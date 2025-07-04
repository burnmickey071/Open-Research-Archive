(define-constant ERR_ALREADY_ENDORSED (err u105))
(define-constant ERR_SELF_ENDORSEMENT (err u106))
(define-constant ERR_UNQUALIFIED_ENDORSER (err u107))
(define-constant ERR_PAPER_NOT_FOUND (err u108))

(define-data-var min-papers-to-endorse uint u3)
(define-data-var endorsement-reward uint u100000)

(define-map paper-endorsements
    { paper-id: uint }
    { endorsement-count: uint, endorser-principals: (list 50 principal) }
)

(define-map user-endorsements
    { endorser: principal, paper-id: uint }
    { endorsed: bool, timestamp: uint }
)

(define-map endorser-reputation
    { endorser: principal }
    { endorsements-given: uint, endorsements-received: uint }
)

(define-read-only (get-paper-endorsements (paper-id uint))
    (default-to { endorsement-count: u0, endorser-principals: (list) } 
        (map-get? paper-endorsements { paper-id: paper-id }))
)

(define-read-only (get-endorser-reputation (endorser principal))
    (default-to { endorsements-given: u0, endorsements-received: u0 }
        (map-get? endorser-reputation { endorser: endorser }))
)

(define-read-only (has-endorsed (endorser principal) (paper-id uint))
    (default-to { endorsed: false, timestamp: u0 }
        (map-get? user-endorsements { endorser: endorser, paper-id: paper-id }))
)

(define-read-only (can-endorse (endorser principal))
    (let ((author-data (contract-call? .Open-Research-Archive get-author-papers endorser)))
        (match author-data
            data (>= (get paper-count data) (var-get min-papers-to-endorse))
            false
        )
    )
)

(define-public (endorse-paper (paper-id uint))
    (let (
        (paper-data (contract-call? .Open-Research-Archive get-research-paper paper-id))
        (current-endorsements (get-paper-endorsements paper-id))
        (current-reputation (get-endorser-reputation tx-sender))
        (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
        (existing-endorsement (has-endorsed tx-sender paper-id))
    )
        (asserts! (is-some paper-data) ERR_PAPER_NOT_FOUND)
        (asserts! (can-endorse tx-sender) ERR_UNQUALIFIED_ENDORSER)
        (asserts! (not (get endorsed existing-endorsement)) ERR_ALREADY_ENDORSED)
        
        (let ((paper-author (get author (unwrap-panic paper-data))))
            (asserts! (not (is-eq tx-sender paper-author)) ERR_SELF_ENDORSEMENT)
            
            (map-set user-endorsements
                { endorser: tx-sender, paper-id: paper-id }
                { endorsed: true, timestamp: current-time }
            )
            
            (map-set paper-endorsements
                { paper-id: paper-id }
                {
                    endorsement-count: (+ (get endorsement-count current-endorsements) u1),
                    endorser-principals: (unwrap-panic (as-max-len? 
                        (append (get endorser-principals current-endorsements) tx-sender) u50))
                }
            )
            
            (map-set endorser-reputation
                { endorser: tx-sender }
                { 
                    endorsements-given: (+ (get endorsements-given current-reputation) u1),
                    endorsements-received: (get endorsements-received current-reputation)
                }
            )
            
            (let ((author-reputation (get-endorser-reputation paper-author)))
                (map-set endorser-reputation
                    { endorser: paper-author }
                    {
                        endorsements-given: (get endorsements-given author-reputation),
                        endorsements-received: (+ (get endorsements-received author-reputation) u1)
                    }
                )
            )
            
            (and (> (var-get endorsement-reward) u0)
                 (is-ok (stx-transfer? (var-get endorsement-reward) 
                                     (as-contract tx-sender) paper-author)))
            
            (ok true)
        )
    )
)
