
;; title: escrow_stx
;; Create new escrow

(define-trait sip010-trait
  ((transfer (uint principal principal) (response bool uint))
   (balance-of (principal) (response uint uint))
   (get-owner (uint) (response principal uint))
   (total-supply () (response uint uint))
   (decimals () (response uint uint))))

(define-data-var escrow-counter uint u0)
(define-map escrows ((escrow-id uint))
  {
    buyer: principal,
    seller: principal,
    amount: uint,
    token: optional (trait_reference),
    deadline: uint,
    is-released: bool,
    is-disputed: bool,
    arbiter: optional principal
  })

(define-constant ERR_UNAUTHORIZED u100)
(define-constant ERR_NOT_FOUND u101)
(define-constant ERR_DEADLINE u102)
(define-constant ERR_ALREADY_RELEASED u103)
(define-constant ERR_DISPUTED u104)
(define-public (create-escrow (seller principal) (arbiter (optional principal)) 
                             (amount uint) (deadline uint) (conditions (string-utf8 500)))
  (let ((escrow-id (+ (var-get last-escrow-id) u1))
        (buyer tx-sender))
    ;; Transfer funds from buyer to contract
    (try! (stx-transfer? amount buyer (as-contract tx-sender)))
    
    ;; Store escrow details
    (map-set escrows escrow-id {
      buyer: buyer,
      seller: seller,
      arbiter: arbiter,
      amount: amount,
      status: "pending",
      deadline: deadline,
      conditions: conditions
    })
    
    ;; Update escrow counter
    (var-set last-escrow-id escrow-id)
    (ok escrow-id)
  )
)

;; Release funds to seller
(define-public (release-funds (escrow-id uint))
  (let ((escrow (unwrap! (map-get? escrows escrow-id) (err u404)))
        (caller tx-sender))
    ;; Verify caller is buyer
    (asserts! (is-eq caller (get buyer escrow)) (err u403))
    ;; Verify escrow is pending
    (asserts! (is-eq (get status escrow) "pending") (err u400))
    
    ;; Transfer funds to seller
    (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get seller escrow))))
    
    ;; Update escrow status
    (map-set escrows escrow-id (merge escrow { status: "completed" }))
    (ok true)
  )
)

;; Raise a dispute
(define-public (dispute (escrow-id uint))
  (match (map-get escrows {escrow-id: escrow-id})
    escrow =>
      (if (is-eq tx-sender (get buyer escrow))
        (begin
          (map-set escrows {escrow-id: escrow-id} (merge escrow {is-disputed: true}))
          (ok true)
        )
        (err ERR_UNAUTHORIZED)
      )
    (err ERR_NOT_FOUND)))

    ;; Resolve dispute
(define-public (resolve-dispute (escrow-id uint) (winner principal))
  (match (map-get escrows {escrow-id: escrow-id})
    escrow =>
      (if (is-eq tx-sender (default-to none (get arbiter escrow)))
        (begin
          ;; Distribute funds based on arbiter's decision
          (map-set escrows {escrow-id: escrow-id} (merge escrow {is-released: true is-disputed: false}))
          ;; Add transfer logic
          (ok winner)
        )
        (err ERR_UNAUTHORIZED)
      )
    (err ERR_NOT_FOUND)))

    ;; Refund buyer if deadline passed and no release
(define-public (refund (escrow-id uint))
  (match (map-get escrows {escrow-id: escrow-id})
    escrow =>
      (if (and (is-eq tx-sender (get buyer escrow))
               (> block-height (get deadline escrow))
               (not (get is-released escrow)))
        (begin
          (map-set escrows {escrow-id: escrow-id} (merge escrow {is-released: true}))
          ;; Refund logic here
          (ok true)
        )
        (err ERR_DEADLINE)
      )
    (err ERR_NOT_FOUND)))