;; Dispute Resolution Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

(define-map disputes
  { dispute-id: uint }
  {
    project-id: uint,
    client: principal,
    freelancer: principal,
    arbitrator: (optional principal),
    status: (string-ascii 20),
    resolution: (optional (string-ascii 256))
  }
)

(define-data-var dispute-nonce uint u0)

(define-public (create-dispute (project-id uint) (client principal) (freelancer principal))
  (let
    (
      (dispute-id (var-get dispute-nonce))
    )
    (asserts! (or (is-eq tx-sender client) (is-eq tx-sender freelancer)) err-unauthorized)
    (var-set dispute-nonce (+ dispute-id u1))
    (ok (map-set disputes
      { dispute-id: dispute-id }
      {
        project-id: project-id,
        client: client,
        freelancer: freelancer,
        arbitrator: none,
        status: "open",
        resolution: none
      }
    ))
  )
)

(define-public (assign-arbitrator (dispute-id uint) (arbitrator principal))
  (let
    (
      (dispute (unwrap! (map-get? disputes { dispute-id: dispute-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status dispute) "open") err-unauthorized)
    (ok (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        arbitrator: (some arbitrator),
        status: "arbitration"
      })
    ))
  )
)

(define-public (resolve-dispute (dispute-id uint) (resolution (string-ascii 256)))
  (let
    (
      (dispute (unwrap! (map-get? disputes { dispute-id: dispute-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (unwrap! (get arbitrator dispute) err-unauthorized)) err-unauthorized)
    (asserts! (is-eq (get status dispute) "arbitration") err-unauthorized)
    (ok (map-set disputes
      { dispute-id: dispute-id }
      (merge dispute {
        status: "resolved",
        resolution: (some resolution)
      })
    ))
  )
)

(define-read-only (get-dispute (dispute-id uint))
  (ok (unwrap! (map-get? disputes { dispute-id: dispute-id }) err-not-found))
)

