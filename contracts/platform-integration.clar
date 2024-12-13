;; Platform Integration Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))

(define-map integrated-platforms
  { platform-id: (string-ascii 64) }
  {
    name: (string-ascii 64),
    api-key: (string-ascii 64),
    webhook-url: (string-ascii 256)
  }
)

(define-public (integrate-platform (platform-id (string-ascii 64)) (name (string-ascii 64)) (api-key (string-ascii 64)) (webhook-url (string-ascii 256)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set integrated-platforms
      { platform-id: platform-id }
      {
        name: name,
        api-key: api-key,
        webhook-url: webhook-url
      }
    ))
  )
)

(define-public (update-platform (platform-id (string-ascii 64)) (api-key (string-ascii 64)) (webhook-url (string-ascii 256)))
  (let
    (
      (platform (unwrap! (map-get? integrated-platforms { platform-id: platform-id }) err-not-found))
    )
    (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
      (ok (map-set integrated-platforms
        { platform-id: platform-id }
        (merge platform {
          api-key: api-key,
          webhook-url: webhook-url
        })
      ))
    )
  )
)

(define-read-only (get-platform-info (platform-id (string-ascii 64)))
  (ok (unwrap! (map-get? integrated-platforms { platform-id: platform-id }) err-not-found))
)

;; This function would be called to notify external platforms of events
(define-public (notify-platform (platform-id (string-ascii 64)) (event-type (string-ascii 64)) (event-data (string-ascii 256)))
  (let
    (
      (platform (unwrap! (map-get? integrated-platforms { platform-id: platform-id }) err-not-found))
    )
    ;; In a real-world scenario, this would trigger an API call to the platform's webhook
    ;; For this example, we'll just return success
    (ok true)
  )
)

