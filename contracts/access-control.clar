;; Access Control Contract
;; Manages permissions for sharing knowledge assets

(define-data-var admin principal tx-sender)

;; Map to store access permissions
(define-map access-permissions
  {asset-id: uint, accessor: principal}
  {
    granted-by: principal,
    granted-at: uint,
    expires-at: uint,
    access-level: uint  ;; 1: read, 2: read+download, 3: read+download+modify
  }
)

;; Check if a principal has access to an asset
(define-read-only (has-access (asset-id uint) (accessor principal))
  (let ((permission (map-get? access-permissions {asset-id: asset-id, accessor: accessor})))
    (if (is-some permission)
      (let ((perm (unwrap-panic permission)))
        (< block-height (get expires-at perm))
      )
      false
    )
  )
)

;; Get access details
(define-read-only (get-access-details (asset-id uint) (accessor principal))
  (map-get? access-permissions {asset-id: asset-id, accessor: accessor})
)

;; Grant access to an asset
(define-public (grant-access
                (asset-id uint)
                (accessor principal)
                (duration uint)
                (access-level uint))
  (begin
    ;; Verify access level is valid (1-3)
    (asserts! (and (>= access-level u1) (<= access-level u3)) (err u301))

    ;; Set the permission
    (map-set access-permissions
      {asset-id: asset-id, accessor: accessor}
      {
        granted-by: tx-sender,
        granted-at: block-height,
        expires-at: (+ block-height duration),
        access-level: access-level
      }
    )

    (ok true)
  )
)

;; Revoke access to an asset
(define-public (revoke-access (asset-id uint) (accessor principal))
  (begin
    (asserts! (is-some (map-get? access-permissions {asset-id: asset-id, accessor: accessor})) (err u302))
    (map-delete access-permissions {asset-id: asset-id, accessor: accessor})
    (ok true)
  )
)

;; Extend access duration
(define-public (extend-access (asset-id uint) (accessor principal) (additional-duration uint))
  (let ((current-permission (unwrap! (map-get? access-permissions {asset-id: asset-id, accessor: accessor}) (err u302))))
    (map-set access-permissions
      {asset-id: asset-id, accessor: accessor}
      (merge current-permission {expires-at: (+ (get expires-at current-permission) additional-duration)})
    )
    (ok true)
  )
)
