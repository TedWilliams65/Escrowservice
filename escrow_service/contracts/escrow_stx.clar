
;; title: escrow_stx
;; Create new escrow
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