;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-USER-NOT-FOUND (err u101))
(define-constant ERR-PROVIDER-NOT-FOUND (err u102))
(define-constant ERR-SESSION-NOT-FOUND (err u103))

;; Data Variables
(define-data-var platform-admin principal tx-sender)
(define-data-var session-fee uint u100) ;; Fixed session fee
(define-data-var session-counter uint u0) ;; Counter for session IDs

;; Data Maps
(define-map Users
    { user-id: (buff 32) } ;; Anonymous hash of user's identity
    { sessions-attended: uint }
)

(define-map Providers
    { provider-id: principal }
    { specialization: (string-ascii 64), sessions-conducted: uint }
)

(define-map Sessions
    { session-id: uint }
    { provider: principal, user-hash: (buff 32), status: (string-ascii 20) }
)

;; Administrative Functions

(define-public (set-platform-admin (new-admin principal))
    (begin
        (asserts! (is-eq tx-sender (var-get platform-admin)) ERR-NOT-AUTHORIZED)
        (var-set platform-admin new-admin)
        (ok true)
    )
)

(define-public (set-session-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender (var-get platform-admin)) ERR-NOT-AUTHORIZED)
        (var-set session-fee new-fee)
        (ok true)
    )
)

;; User Management

(define-public (register-user (user-hash (buff 32)))
    (begin
        (map-set Users
            { user-id: user-hash }
            { sessions-attended: u0 }
        )
        (ok true)
    )
)

(define-public (register-provider (specialization (string-ascii 64)))
    (begin
        (map-set Providers
            { provider-id: tx-sender }
            { specialization: specialization, sessions-conducted: u0 }
        )
        (ok true)
    )
)

;; Session Management

(define-public (create-session (user-hash (buff 32)) (provider principal))
    (let
        (
            (new-session-id (+ (var-get session-counter) u1))
        )
        (asserts! (is-some (map-get? Users { user-id: user-hash })) ERR-USER-NOT-FOUND)
        (asserts! (is-some (map-get? Providers { provider-id: provider })) ERR-PROVIDER-NOT-FOUND)

        (map-set Sessions
            { session-id: new-session-id }
            { provider: provider, user-hash: user-hash, status: "scheduled" }
        )
        (var-set session-counter new-session-id)
        (ok new-session-id)
    )
)

(define-public (complete-session (session-id uint))
    (let
        (
            (session (unwrap! (map-get? Sessions { session-id: session-id }) ERR-SESSION-NOT-FOUND))
            (provider (get provider session))
        )
        ;; Update session status
        (map-set Sessions
            { session-id: session-id }
            (merge session { status: "completed" })
        )

        ;; Update provider's conducted sessions count
        (let ((provider-data (unwrap! (map-get? Providers { provider-id: provider }) ERR-PROVIDER-NOT-FOUND)))
            (map-set Providers
                { provider-id: provider }
                (merge provider-data { sessions-conducted: (+ (get sessions-conducted provider-data) u1) })
            )
        )
        (ok true)
    )
)

;; Utility Functions

(define-read-only (get-provider-details (provider-id principal))
    (map-get? Providers { provider-id: provider-id })
)

(define-read-only (get-session-details (session-id uint))
    (map-get? Sessions { session-id: session-id })
)

(define-read-only (get-user-details (user-hash (buff 32)))
    (map-get? Users { user-id: user-hash })
)
