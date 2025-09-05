(define-constant ERR_NOT_MEMBER (err u200))
(define-constant ERR_NOT_ADMIN (err u201))
(define-constant ERR_GROUP_NOT_FOUND (err u202))
(define-constant ERR_ALREADY_MEMBER (err u203))
(define-constant ERR_DRAFT_NOT_FOUND (err u204))

(define-data-var next-group-id uint u1)
(define-data-var next-draft-id uint u1)

(define-map collaboration-groups
    { group-id: uint }
    { 
        name: (string-ascii 100),
        admin: principal,
        member-count: uint,
        created-at: uint
    }
)

(define-map group-members
    { group-id: uint, member: principal }
    { joined-at: uint, is-active: bool }
)

(define-map research-drafts
    { draft-id: uint }
    {
        title: (string-ascii 200),
        content-hash: (buff 32),
        group-id: uint,
        author: principal,
        created-at: uint,
        is-finalized: bool
    }
)

(define-map draft-permissions
    { draft-id: uint, viewer: principal }
    { can-view: bool, can-edit: bool }
)

(define-read-only (get-group-info (group-id uint))
    (map-get? collaboration-groups { group-id: group-id })
)

(define-read-only (is-group-member (group-id uint) (member principal))
    (default-to { joined-at: u0, is-active: false }
        (map-get? group-members { group-id: group-id, member: member }))
)

(define-read-only (get-draft-info (draft-id uint))
    (map-get? research-drafts { draft-id: draft-id })
)

(define-read-only (can-access-draft (draft-id uint) (user principal))
    (match (map-get? research-drafts { draft-id: draft-id })
        draft-data 
        (let ((membership (is-group-member (get group-id draft-data) user)))
            (get is-active membership))
        false
    )
)

(define-public (create-collaboration-group (name (string-ascii 100)))
    (let (
        (group-id (var-get next-group-id))
        (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
        (map-set collaboration-groups
            { group-id: group-id }
            {
                name: name,
                admin: tx-sender,
                member-count: u1,
                created-at: current-time
            }
        )
        
        (map-set group-members
            { group-id: group-id, member: tx-sender }
            { joined-at: current-time, is-active: true }
        )
        
        (var-set next-group-id (+ group-id u1))
        (ok group-id)
    )
)

(define-public (join-group (group-id uint))
    (let (
        (group-data (unwrap! (map-get? collaboration-groups { group-id: group-id }) ERR_GROUP_NOT_FOUND))
        (existing-membership (is-group-member group-id tx-sender))
        (current-time (unwrap-panic (get-stacks-block-info? time (- stacks-block-height u1))))
    )
        (asserts! (not (get is-active existing-membership)) ERR_ALREADY_MEMBER)
        
        (map-set group-members
            { group-id: group-id, member: tx-sender }
            { joined-at: current-time, is-active: true }
        )
        
        (map-set collaboration-groups
            { group-id: group-id }
            (merge group-data { member-count: (+ (get member-count group-data) u1) })
        )
        
        (ok true)
    )
)
