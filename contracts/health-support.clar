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