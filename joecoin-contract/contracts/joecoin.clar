;; title: joecoin
;; version: 1.0.0
;; summary: A simple fungible token for the Joecoin project
;; description: 
;;   Joecoin is a basic fungible token implemented in Clarity. It follows
;;   the function conventions of the SIP-010 fungible token standard but
;;   is self-contained in a single contract with no external trait
;;   dependency.

;; ------------------------------------------------------------
;; constants
;; ------------------------------------------------------------

(define-constant token-name "Joecoin")
(define-constant token-symbol "JOE")
(define-constant token-decimals u6)

;; common error codes
(define-constant err-insufficient-balance (err u100))
(define-constant err-amount-zero (err u101))
(define-constant err-already-initialized (err u102))
(define-constant err-not-initialized (err u103))
(define-constant err-unauthorized (err u104))

;; ------------------------------------------------------------
;; data vars
;; ------------------------------------------------------------

;; total number of tokens that have been minted
(define-data-var total-supply uint u0)

;; whether the token has been initialized
(define-data-var initialized bool false)

;; the account that is allowed to mint after initialization
;; this is set when `init` is called for the first time
(define-data-var token-owner principal 'SP000000000000000000002Q6VF78)

;; ------------------------------------------------------------
;; data maps
;; ------------------------------------------------------------

;; track balances for each principal
(define-map balances
  { owner: principal }
  { balance: uint })

;; ------------------------------------------------------------
;; private helpers
;; ------------------------------------------------------------

(define-read-only (get-balance-internal (who principal))
  (match (map-get? balances { owner: who })
    balance-data (get balance balance-data)
    u0))

(define-private (set-balance (who principal) (amount uint))
  (if (is-eq amount u0)
      (begin
        ;; storing zero is equivalent to removing the entry
        (map-delete balances { owner: who })
        true)
      (begin
        (map-set balances { owner: who } { balance: amount })
        true)))

(define-private (only-owner (sender principal))
  (if (is-eq sender (var-get token-owner))
      (ok true)
      err-unauthorized))

(define-private (ensure-initialized)
  (if (var-get initialized)
      (ok true)
      err-not-initialized))

;; ------------------------------------------------------------
;; public functions
;; ------------------------------------------------------------

;; Initialize the token once. The caller becomes the token owner and
;; receives the entire initial supply.
(define-public (init (initial-supply uint))
  (begin
    (if (var-get initialized)
        err-already-initialized
        (let ((sender tx-sender))
          (begin
            (var-set token-owner sender)
            (var-set total-supply initial-supply)
            (map-set balances { owner: sender } { balance: initial-supply })
            (var-set initialized true)
            (ok true))))))

;; Mint new tokens to a recipient. Only the token owner may mint.
(define-public (mint (amount uint) (recipient principal))
  (begin
    (try! (ensure-initialized))
    (if (is-eq amount u0)
        err-amount-zero
        (begin
          (try! (only-owner tx-sender))
          (let ((current-balance (get-balance-internal recipient))
                (new-total (+ (var-get total-supply) amount)))
            (var-set total-supply new-total)
            (set-balance recipient (+ current-balance amount))
            (ok true))))))

;; Transfer tokens from `sender` to `recipient`.
;; The tx-sender must be the same as `sender`.
(define-public (transfer (amount uint)
                         (sender principal)
                         (recipient principal))
  (begin
    (try! (ensure-initialized))
    (if (is-eq amount u0)
        err-amount-zero
        (if (not (is-eq sender tx-sender))
            err-unauthorized
            (let (
                  (sender-balance (get-balance-internal sender))
                 )
              (if (< sender-balance amount)
                  err-insufficient-balance
                  (let (
                        (new-sender-balance (- sender-balance amount))
                        (recipient-balance (get-balance-internal recipient))
                       )
                    (begin
                      (set-balance sender new-sender-balance)
                      (set-balance recipient (+ recipient-balance amount))
                      (ok true)))))))))

;; ------------------------------------------------------------
;; read-only functions
;; ------------------------------------------------------------

(define-read-only (get-name)
  (ok token-name))

(define-read-only (get-symbol)
  (ok token-symbol))

(define-read-only (get-decimals)
  (ok token-decimals))

(define-read-only (get-total-supply)
  (ok (var-get total-supply)))

(define-read-only (get-balance-of (who principal))
  (ok (get-balance-internal who)))
