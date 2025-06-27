;; Message Coordination Contract
;; Coordinates crisis messages

;; Constants
(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_NOT_FOUND (err u301))
(define-constant ERR_INVALID_INPUT (err u302))
(define-constant ERR_MESSAGE_SENT (err u303))

;; Data Variables
(define-data-var next-message-id uint u1)

;; Data Maps
(define-map crisis-messages
  { message-id: uint }
  {
    sender: principal,
    title: (string-ascii 100),
    content: (string-ascii 1000),
    priority: uint,
    status: (string-ascii 20),
    created-at: uint,
    sent-at: (optional uint)
  }
)

(define-map message-recipients
  { message-id: uint, recipient-index: uint }
  {
    recipient-type: (string-ascii 30),
    recipient-info: (string-ascii 100),
    delivered: bool,
    delivered-at: (optional uint)
  }
)

(define-map message-recipient-count
  { message-id: uint }
  { count: uint }
)

;; Public Functions

;; Create a new crisis message
(define-public (create-message (title (string-ascii 100)) (content (string-ascii 1000)) (priority uint))
  (let
    (
      (message-id (var-get next-message-id))
      (caller tx-sender)
    )
    (asserts! (> (len title) u0) ERR_INVALID_INPUT)
    (asserts! (> (len content) u0) ERR_INVALID_INPUT)
    (asserts! (<= priority u5) ERR_INVALID_INPUT)

    (map-set crisis-messages
      { message-id: message-id }
      {
        sender: caller,
        title: title,
        content: content,
        priority: priority,
        status: "draft",
        created-at: block-height,
        sent-at: none
      }
    )

    (map-set message-recipient-count
      { message-id: message-id }
      { count: u0 }
    )

    (var-set next-message-id (+ message-id u1))
    (ok message-id)
  )
)

;; Add recipient to message
(define-public (add-recipient (message-id uint) (recipient-type (string-ascii 30)) (recipient-info (string-ascii 100)))
  (let
    (
      (message-data (unwrap! (map-get? crisis-messages { message-id: message-id }) ERR_NOT_FOUND))
      (recipient-count-data (unwrap! (map-get? message-recipient-count { message-id: message-id }) ERR_NOT_FOUND))
      (current-count (get count recipient-count-data))
    )
    (asserts! (is-eq tx-sender (get sender message-data)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status message-data) "draft") ERR_MESSAGE_SENT)
    (asserts! (> (len recipient-type) u0) ERR_INVALID_INPUT)
    (asserts! (> (len recipient-info) u0) ERR_INVALID_INPUT)

    (map-set message-recipients
      { message-id: message-id, recipient-index: current-count }
      {
        recipient-type: recipient-type,
        recipient-info: recipient-info,
        delivered: false,
        delivered-at: none
      }
    )

    (map-set message-recipient-count
      { message-id: message-id }
      { count: (+ current-count u1) }
    )

    (ok current-count)
  )
)

;; Send message
(define-public (send-message (message-id uint))
  (match (map-get? crisis-messages { message-id: message-id })
    message-data
    (begin
      (asserts! (is-eq tx-sender (get sender message-data)) ERR_UNAUTHORIZED)
      (asserts! (is-eq (get status message-data) "draft") ERR_MESSAGE_SENT)
      (map-set crisis-messages
        { message-id: message-id }
        (merge message-data { status: "sent", sent-at: (some block-height) })
      )
      (ok true)
    )
    ERR_NOT_FOUND
  )
)

;; Mark recipient as delivered
(define-public (mark-delivered (message-id uint) (recipient-index uint))
  (let
    (
      (message-data (unwrap! (map-get? crisis-messages { message-id: message-id }) ERR_NOT_FOUND))
      (recipient-data (unwrap! (map-get? message-recipients { message-id: message-id, recipient-index: recipient-index }) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get sender message-data)) ERR_UNAUTHORIZED)
    (map-set message-recipients
      { message-id: message-id, recipient-index: recipient-index }
      (merge recipient-data { delivered: true, delivered-at: (some block-height) })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get message
(define-read-only (get-message (message-id uint))
  (map-get? crisis-messages { message-id: message-id })
)

;; Get message recipient
(define-read-only (get-message-recipient (message-id uint) (recipient-index uint))
  (map-get? message-recipients { message-id: message-id, recipient-index: recipient-index })
)

;; Get message recipient count
(define-read-only (get-message-recipient-count (message-id uint))
  (map-get? message-recipient-count { message-id: message-id })
)

;; Check if message is sent
(define-read-only (is-message-sent (message-id uint))
  (match (map-get? crisis-messages { message-id: message-id })
    message-data
    (is-eq (get status message-data) "sent")
    false
  )
)
