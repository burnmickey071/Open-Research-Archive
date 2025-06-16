(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_RESEARCH_NOT_FOUND (err u101))
(define-constant ERR_INVALID_INPUT (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_INSUFFICIENT_PAYMENT (err u104))

(define-data-var next-research-id uint u1)
(define-data-var submission-fee uint u1000000)

(define-map research-papers
    { research-id: uint }
    {
        title: (string-ascii 200),
        author: principal,
        content-hash: (buff 32),
        timestamp: uint,
        block-height: uint,
        verified: bool,
        category: (string-ascii 50)
    }
)

(define-map author-papers
    { author: principal }
    { paper-count: uint, paper-ids: (list 100 uint) }
)

(define-map content-hashes
    { content-hash: (buff 32) }
    { research-id: uint, exists: bool }
)

(define-map research-citations
    { citing-paper: uint, cited-paper: uint }
    { citation-context: (string-ascii 500) }
)

(define-map paper-citations-count
    { research-id: uint }
    { citation-count: uint }
)

(define-read-only (get-research-paper (research-id uint))
    (map-get? research-papers { research-id: research-id })
)

(define-read-only (get-author-papers (author principal))
    (map-get? author-papers { author: author })
)

(define-read-only (check-content-exists (content-hash (buff 32)))
    (map-get? content-hashes { content-hash: content-hash })
)

(define-read-only (get-paper-citations (research-id uint))
    (map-get? paper-citations-count { research-id: research-id })
)

(define-read-only (get-submission-fee)
    (var-get submission-fee)
)

(define-read-only (get-next-research-id)
    (var-get next-research-id)
)

(define-read-only (verify-timestamp-claim (content-hash (buff 32)) (claimed-timestamp uint))
    (match (map-get? content-hashes { content-hash: content-hash })
        existing-record
        (let ((research-data (unwrap-panic (map-get? research-papers { research-id: (get research-id existing-record) }))))
            {
                exists: true,
                original-timestamp: (get timestamp research-data),
                original-author: (get author research-data),
                is-prior-claim: (< (get timestamp research-data) claimed-timestamp)
            }
        )
        {
            exists: false,
            original-timestamp: u0,
            original-author: tx-sender,
            is-prior-claim: false
        }
    )
)

(define-public (submit-research 
    (title (string-ascii 200))
    (content-hash (buff 32))
    (category (string-ascii 50)))
    (let (
        (current-id (var-get next-research-id))
        (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
        (fee (var-get submission-fee))
    )
        (asserts! (> (len title) u0) ERR_INVALID_INPUT)
        (asserts! (> (len category) u0) ERR_INVALID_INPUT)
        (asserts! (is-none (map-get? content-hashes { content-hash: content-hash })) ERR_ALREADY_EXISTS)
        
        (try! (stx-transfer? fee tx-sender CONTRACT_OWNER))
        
        (map-set research-papers
            { research-id: current-id }
            {
                title: title,
                author: tx-sender,
                content-hash: content-hash,
                timestamp: current-time,
                block-height: stacks-block-height,
                verified: false,
                category: category
            }
        )
        
        (map-set content-hashes
            { content-hash: content-hash }
            { research-id: current-id, exists: true }
        )
        
        (map-set paper-citations-count
            { research-id: current-id }
            { citation-count: u0 }
        )
        
        (match (map-get? author-papers { author: tx-sender })
            existing-author
            (map-set author-papers
                { author: tx-sender }
                {
                    paper-count: (+ (get paper-count existing-author) u1),
                    paper-ids: (unwrap-panic (as-max-len? (append (get paper-ids existing-author) current-id) u100))
                }
            )
            (map-set author-papers
                { author: tx-sender }
                { paper-count: u1, paper-ids: (list current-id) }
            )
        )
        
        (var-set next-research-id (+ current-id u1))
        (ok current-id)
    )
)

(define-public (verify-research (research-id uint))
    (let ((research-data (unwrap! (map-get? research-papers { research-id: research-id }) ERR_RESEARCH_NOT_FOUND)))
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (map-set research-papers
            { research-id: research-id }
            (merge research-data { verified: true })
        )
        (ok true)
    )
)

(define-public (add-citation 
    (citing-paper-id uint)
    (cited-paper-id uint)
    (citation-context (string-ascii 500)))
    (let (
        (citing-paper (unwrap! (map-get? research-papers { research-id: citing-paper-id }) ERR_RESEARCH_NOT_FOUND))
        (cited-paper (unwrap! (map-get? research-papers { research-id: cited-paper-id }) ERR_RESEARCH_NOT_FOUND))
        (current-citations (default-to { citation-count: u0 } (map-get? paper-citations-count { research-id: cited-paper-id })))
    )
        (asserts! (is-eq tx-sender (get author citing-paper)) ERR_UNAUTHORIZED)
        (asserts! (not (is-eq citing-paper-id cited-paper-id)) ERR_INVALID_INPUT)
        
        (map-set research-citations
            { citing-paper: citing-paper-id, cited-paper: cited-paper-id }
            { citation-context: citation-context }
        )
        
        (map-set paper-citations-count
            { research-id: cited-paper-id }
            { citation-count: (+ (get citation-count current-citations) u1) }
        )
        
        (ok true)
    )
)

(define-public (update-submission-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (var-set submission-fee new-fee)
        (ok true)
    )
)

(define-read-only (get-research-by-category (category (string-ascii 50)))
    (ok category)
)

(define-read-only (get-citation-details (citing-paper uint) (cited-paper uint))
    (map-get? research-citations { citing-paper: citing-paper, cited-paper: cited-paper })
)

(define-public (transfer-ownership (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
        (ok true)
    )
)
