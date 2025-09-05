(define-constant ERR_BOUNTY_NOT_FOUND (err u300))
(define-constant ERR_ALREADY_CLAIMED (err u301))
(define-constant ERR_NOT_BOUNTY_CREATOR (err u302))
(define-constant ERR_BOUNTY_EXPIRED (err u303))
(define-constant ERR_INVALID_BOUNTY (err u304))
(define-constant ERR_INSUFFICIENT_FUNDS (err u305))

(define-data-var next-bounty-id uint u1)
(define-data-var platform-fee-percentage uint u5)

(define-map research-bounties
    { bounty-id: uint }
    {
        title: (string-ascii 200),
        description: (string-ascii 500),
        category: (string-ascii 50),
        bounty-amount: uint,
        creator: principal,
        deadline: uint,
        claimed-by: (optional principal),
        completed-research-id: (optional uint),
        is-active: bool,
        created-at: uint
    }
)

(define-map bounty-claims
    { bounty-id: uint, claimant: principal }
    { claimed-at: uint, is-submitted: bool }
)

(define-map user-bounty-stats
    { user: principal }
    { bounties-created: uint, bounties-completed: uint, total-earned: uint }
)

(define-read-only (get-bounty-info (bounty-id uint))
    (map-get? research-bounties { bounty-id: bounty-id })
)

(define-read-only (get-user-stats (user principal))
    (default-to { bounties-created: u0, bounties-completed: u0, total-earned: u0 }
        (map-get? user-bounty-stats { user: user }))
)

(define-read-only (is-bounty-claimed (bounty-id uint) (claimant principal))
    (is-some (map-get? bounty-claims { bounty-id: bounty-id, claimant: claimant }))
)

(define-public (create-bounty 
    (title (string-ascii 200))
    (description (string-ascii 500))
    (category (string-ascii 50))
    (bounty-amount uint)
    (deadline uint))
    (let (
        (bounty-id (var-get next-bounty-id))
        (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
        (user-stats (get-user-stats tx-sender))
    )
        (asserts! (> (len title) u0) ERR_INVALID_BOUNTY)
        (asserts! (> bounty-amount u0) ERR_INVALID_BOUNTY)
        (asserts! (> deadline current-time) ERR_INVALID_BOUNTY)
        
        (try! (stx-transfer? bounty-amount tx-sender (as-contract tx-sender)))
        
        (map-set research-bounties
            { bounty-id: bounty-id }
            {
                title: title,
                description: description,
                category: category,
                bounty-amount: bounty-amount,
                creator: tx-sender,
                deadline: deadline,
                claimed-by: none,
                completed-research-id: none,
                is-active: true,
                created-at: current-time
            }
        )
        
        (map-set user-bounty-stats
            { user: tx-sender }
            (merge user-stats { bounties-created: (+ (get bounties-created user-stats) u1) })
        )
        
        (var-set next-bounty-id (+ bounty-id u1))
        (ok bounty-id)
    )
)

(define-public (claim-bounty (bounty-id uint))
    (let (
        (bounty-data (unwrap! (map-get? research-bounties { bounty-id: bounty-id }) ERR_BOUNTY_NOT_FOUND))
        (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
        (asserts! (get is-active bounty-data) ERR_BOUNTY_NOT_FOUND)
        (asserts! (< current-time (get deadline bounty-data)) ERR_BOUNTY_EXPIRED)
        (asserts! (not (is-bounty-claimed bounty-id tx-sender)) ERR_ALREADY_CLAIMED)
        (asserts! (not (is-eq tx-sender (get creator bounty-data))) ERR_INVALID_BOUNTY)
        
        (map-set bounty-claims
            { bounty-id: bounty-id, claimant: tx-sender }
            { claimed-at: current-time, is-submitted: false }
        )
        
        (ok true)
    )
)

(define-public (complete-bounty (bounty-id uint) (research-id uint))
    (let (
        (bounty-data (unwrap! (map-get? research-bounties { bounty-id: bounty-id }) ERR_BOUNTY_NOT_FOUND))
        (claim-data (unwrap! (map-get? bounty-claims { bounty-id: bounty-id, claimant: tx-sender }) ERR_ALREADY_CLAIMED))
        (research-data (unwrap! (contract-call? .Open-Research-Archive get-research-paper research-id) ERR_INVALID_BOUNTY))
        (platform-fee (/ (* (get bounty-amount bounty-data) (var-get platform-fee-percentage)) u100))
        (payout (- (get bounty-amount bounty-data) platform-fee))
        (user-stats (get-user-stats tx-sender))
        (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
        (asserts! (get is-active bounty-data) ERR_BOUNTY_NOT_FOUND)
        (asserts! (< current-time (get deadline bounty-data)) ERR_BOUNTY_EXPIRED)
        (asserts! (is-eq tx-sender (get author research-data)) ERR_INVALID_BOUNTY)
        
        (try! (as-contract (stx-transfer? payout tx-sender tx-sender)))
        
        (map-set research-bounties
            { bounty-id: bounty-id }
            (merge bounty-data { 
                claimed-by: (some tx-sender),
                completed-research-id: (some research-id),
                is-active: false 
            })
        )
        
        (map-set user-bounty-stats
            { user: tx-sender }
            (merge user-stats { 
                bounties-completed: (+ (get bounties-completed user-stats) u1),
                total-earned: (+ (get total-earned user-stats) payout)
            })
        )
        
        (ok payout)
    )
)
