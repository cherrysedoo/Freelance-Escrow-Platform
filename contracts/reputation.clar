;; Reputation System Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

(define-map user-reputation
  { user: principal }
  {
    total-score: int,
    review-count: uint
  }
)

(define-map project-reviews
  { project-id: uint }
  {
    client-review: (optional {
      reviewer: principal,
      reviewee: principal,
      score: int,
      comment: (string-utf8 256)
    }),
    freelancer-review: (optional {
      reviewer: principal,
      reviewee: principal,
      score: int,
      comment: (string-utf8 256)
    })
  }
)

(define-public (submit-review (project-id uint) (reviewee principal) (score int) (comment (string-utf8 256)))
  (let
    (
      (project-review (default-to { client-review: none, freelancer-review: none } (map-get? project-reviews { project-id: project-id })))
      (user-rep (default-to { total-score: 0, review-count: u0 } (map-get? user-reputation { user: reviewee })))
    )
    (asserts! (and (>= score -5) (<= score 5)) err-unauthorized)
    (if (is-none (get client-review project-review))
      (map-set project-reviews { project-id: project-id }
        (merge project-review {
          client-review: (some {
            reviewer: tx-sender,
            reviewee: reviewee,
            score: score,
            comment: comment
          })
        })
      )
      (map-set project-reviews { project-id: project-id }
        (merge project-review {
          freelancer-review: (some {
            reviewer: tx-sender,
            reviewee: reviewee,
            score: score,
            comment: comment
          })
        })
      )
    )
    (ok (map-set user-reputation
      { user: reviewee }
      {
        total-score: (+ (get total-score user-rep) score),
        review-count: (+ (get review-count user-rep) u1)
      }
    ))
  )
)

(define-read-only (get-user-reputation (user principal))
  (ok (unwrap! (map-get? user-reputation { user: user }) err-not-found))
)

(define-read-only (get-project-reviews (project-id uint))
  (ok (unwrap! (map-get? project-reviews { project-id: project-id }) err-not-found))
)

