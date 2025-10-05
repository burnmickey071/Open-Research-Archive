(define-constant ERR_BOUNTY_NOT_FOUND (err u400))
(define-constant ERR_NOT_CREATOR (err u401))
(define-constant ERR_BOUNTY_INACTIVE (err u402))
(define-constant ERR_INVALID_EXTENSION (err u403))
(define-constant ERR_ALREADY_CLAIMED (err u404))
(define-constant ERR_EXPIRED_BOUNTY (err u405))
(define-constant ERR_INSUFFICIENT_AMOUNT (err u406))

(define-data-var next-modification-id uint u1)

(define-map bounty-modifications
    { bounty-id: uint, modification-id: uint }
    {
        modification-type: (string-ascii 20),
        old-value: uint,
        new-value: uint,
        additional-funds: uint,
        modified-at: uint,
        modifier: principal
    }
)

(define-map bounty-modification-count
    { bounty-id: uint }
    { count: uint, total-added-funds: uint, total-extensions: uint }
)

(define-read-only (get-modification-history (bounty-id uint) (modification-id uint))
    (map-get? bounty-modifications { bounty-id: bounty-id, modification-id: modification-id })
)

(define-read-only (get-bounty-modification-stats (bounty-id uint))
    (default-to { count: u0, total-added-funds: u0, total-extensions: u0 }
        (map-get? bounty-modification-count { bounty-id: bounty-id }))
)

(define-public (extend-bounty-deadline (bounty-id uint) (new-deadline uint))
    (let (
        (bounty-data (unwrap! (contract-call? .Research-Bounty get-bounty-info bounty-id) ERR_BOUNTY_NOT_FOUND))
        (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
        (mod-stats (get-bounty-modification-stats bounty-id))
        (mod-id (var-get next-modification-id))
    )
        (asserts! (is-eq tx-sender (get creator bounty-data)) ERR_NOT_CREATOR)
        (asserts! (get is-active bounty-data) ERR_BOUNTY_INACTIVE)
        (asserts! (is-none (get claimed-by bounty-data)) ERR_ALREADY_CLAIMED)
        (asserts! (> (get deadline bounty-data) current-time) ERR_EXPIRED_BOUNTY)
        (asserts! (> new-deadline (get deadline bounty-data)) ERR_INVALID_EXTENSION)
        
        (map-set bounty-modifications
            { bounty-id: bounty-id, modification-id: mod-id }
            {
                modification-type: "deadline-extension",
                old-value: (get deadline bounty-data),
                new-value: new-deadline,
                additional-funds: u0,
                modified-at: current-time,
                modifier: tx-sender
            }
        )
        
        (map-set bounty-modification-count
            { bounty-id: bounty-id }
            {
                count: (+ (get count mod-stats) u1),
                total-added-funds: (get total-added-funds mod-stats),
                total-extensions: (+ (get total-extensions mod-stats) u1)
            }
        )
        
        (var-set next-modification-id (+ mod-id u1))
        (ok { new-deadline: new-deadline, modification-id: mod-id })
    )
)

(define-public (top-up-bounty (bounty-id uint) (additional-amount uint))
    (let (
        (bounty-data (unwrap! (contract-call? .Research-Bounty get-bounty-info bounty-id) ERR_BOUNTY_NOT_FOUND))
        (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
        (mod-stats (get-bounty-modification-stats bounty-id))
        (mod-id (var-get next-modification-id))
        (new-total (+ (get bounty-amount bounty-data) additional-amount))
    )
        (asserts! (is-eq tx-sender (get creator bounty-data)) ERR_NOT_CREATOR)
        (asserts! (get is-active bounty-data) ERR_BOUNTY_INACTIVE)
        (asserts! (is-none (get claimed-by bounty-data)) ERR_ALREADY_CLAIMED)
        (asserts! (> additional-amount u0) ERR_INSUFFICIENT_AMOUNT)
        
        (try! (stx-transfer? additional-amount tx-sender (as-contract tx-sender)))
        
        (map-set bounty-modifications
            { bounty-id: bounty-id, modification-id: mod-id }
            {
                modification-type: "amount-increase",
                old-value: (get bounty-amount bounty-data),
                new-value: new-total,
                additional-funds: additional-amount,
                modified-at: current-time,
                modifier: tx-sender
            }
        )
        
        (map-set bounty-modification-count
            { bounty-id: bounty-id }
            {
                count: (+ (get count mod-stats) u1),
                total-added-funds: (+ (get total-added-funds mod-stats) additional-amount),
                total-extensions: (get total-extensions mod-stats)
            }
        )
        
        (var-set next-modification-id (+ mod-id u1))
        (ok { new-total: new-total, modification-id: mod-id })
    )
)
