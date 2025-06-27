;; Communication Planning Contract
;; Plans crisis communications

;; Constants
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_INVALID_INPUT (err u202))
(define-constant ERR_PLAN_ACTIVE (err u203))

;; Data Variables
(define-data-var next-plan-id uint u1)

;; Data Maps
(define-map communication-plans
  { plan-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    priority-level: uint,
    active: bool,
    created-at: uint,
    updated-at: uint
  }
)

(define-map plan-contacts
  { plan-id: uint, contact-index: uint }
  {
    contact-type: (string-ascii 30),
    contact-info: (string-ascii 100),
    priority: uint
  }
)

(define-map plan-contact-count
  { plan-id: uint }
  { count: uint }
)

;; Public Functions

;; Create a new communication plan
(define-public (create-plan (title (string-ascii 100)) (description (string-ascii 500)) (priority-level uint))
  (let
    (
      (plan-id (var-get next-plan-id))
      (caller tx-sender)
    )
    (asserts! (> (len title) u0) ERR_INVALID_INPUT)
    (asserts! (> (len description) u0) ERR_INVALID_INPUT)
    (asserts! (<= priority-level u5) ERR_INVALID_INPUT)

    (map-set communication-plans
      { plan-id: plan-id }
      {
        creator: caller,
        title: title,
        description: description,
        priority-level: priority-level,
        active: false,
        created-at: block-height,
        updated-at: block-height
      }
    )

    (map-set plan-contact-count
      { plan-id: plan-id }
      { count: u0 }
    )

    (var-set next-plan-id (+ plan-id u1))
    (ok plan-id)
  )
)

;; Add contact to plan
(define-public (add-contact-to-plan (plan-id uint) (contact-type (string-ascii 30)) (contact-info (string-ascii 100)) (priority uint))
  (let
    (
      (plan-data (unwrap! (map-get? communication-plans { plan-id: plan-id }) ERR_NOT_FOUND))
      (contact-count-data (unwrap! (map-get? plan-contact-count { plan-id: plan-id }) ERR_NOT_FOUND))
      (current-count (get count contact-count-data))
    )
    (asserts! (is-eq tx-sender (get creator plan-data)) ERR_UNAUTHORIZED)
    (asserts! (> (len contact-type) u0) ERR_INVALID_INPUT)
    (asserts! (> (len contact-info) u0) ERR_INVALID_INPUT)
    (asserts! (<= priority u5) ERR_INVALID_INPUT)

    (map-set plan-contacts
      { plan-id: plan-id, contact-index: current-count }
      {
        contact-type: contact-type,
        contact-info: contact-info,
        priority: priority
      }
    )

    (map-set plan-contact-count
      { plan-id: plan-id }
      { count: (+ current-count u1) }
    )

    (ok current-count)
  )
)

;; Activate communication plan
(define-public (activate-plan (plan-id uint))
  (match (map-get? communication-plans { plan-id: plan-id })
    plan-data
    (begin
      (asserts! (is-eq tx-sender (get creator plan-data)) ERR_UNAUTHORIZED)
      (map-set communication-plans
        { plan-id: plan-id }
        (merge plan-data { active: true, updated-at: block-height })
      )
      (ok true)
    )
    ERR_NOT_FOUND
  )
)

;; Deactivate communication plan
(define-public (deactivate-plan (plan-id uint))
  (match (map-get? communication-plans { plan-id: plan-id })
    plan-data
    (begin
      (asserts! (is-eq tx-sender (get creator plan-data)) ERR_UNAUTHORIZED)
      (map-set communication-plans
        { plan-id: plan-id }
        (merge plan-data { active: false, updated-at: block-height })
      )
      (ok true)
    )
    ERR_NOT_FOUND
  )
)

;; Read-only Functions

;; Get communication plan
(define-read-only (get-plan (plan-id uint))
  (map-get? communication-plans { plan-id: plan-id })
)

;; Get plan contact
(define-read-only (get-plan-contact (plan-id uint) (contact-index uint))
  (map-get? plan-contacts { plan-id: plan-id, contact-index: contact-index })
)

;; Get plan contact count
(define-read-only (get-plan-contact-count (plan-id uint))
  (map-get? plan-contact-count { plan-id: plan-id })
)

;; Check if plan is active
(define-read-only (is-plan-active (plan-id uint))
  (match (map-get? communication-plans { plan-id: plan-id })
    plan-data
    (get active plan-data)
    false
  )
)
