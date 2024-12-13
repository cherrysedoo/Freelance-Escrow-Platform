;; Escrow Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

(define-map projects
  { project-id: uint }
  {
    client: principal,
    freelancer: principal,
    total-amount: uint,
    milestones: (list 10 {
      amount: uint,
      status: (string-ascii 20)
    }),
    current-milestone: uint
  }
)

(define-public (create-project (project-id uint) (freelancer principal) (total-amount uint) (milestones (list 10 uint)))
  (let
    (
      (milestone-data (map milestone-to-map milestones))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? projects { project-id: project-id })) err-already-exists)
    (ok (map-set projects
      { project-id: project-id }
      {
        client: tx-sender,
        freelancer: freelancer,
        total-amount: total-amount,
        milestones: milestone-data,
        current-milestone: u0
      }
    ))
  )
)

(define-private (milestone-to-map (amount uint))
  {
    amount: amount,
    status: "pending"
  }
)

(define-public (fund-project (project-id uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get client project)) err-unauthorized)
    (try! (stx-transfer? (get total-amount project) tx-sender (as-contract tx-sender)))
    (ok true)
  )
)

(define-public (complete-milestone (project-id uint))
  (let
    (
      (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
      (current-milestone (get current-milestone project))
      (milestone (unwrap! (element-at (get milestones project) current-milestone) err-not-found))
      (updated-milestone (merge milestone { status: "completed" }))
      (milestones-before (slice (get milestones project) u0 current-milestone))
      (milestones-after (slice (get milestones project) (+ current-milestone u1) (len (get milestones project))))
    )
    (asserts! (is-eq tx-sender (get freelancer project)) err-unauthorized)
    (asserts! (< current-milestone (len (get milestones project))) err-not-found)
    (try! (as-contract (stx-transfer? (get amount milestone) tx-sender (get freelancer project))))
    (map-set projects
      { project-id: project-id }
      (merge project {
        current-milestone: (+ current-milestone u1),
        milestones: (concat (concat milestones-before (list updated-milestone)) milestones-after)
      })
    )
    (ok true)
  )
)

(define-read-only (get-project (project-id uint))
  (ok (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
)

