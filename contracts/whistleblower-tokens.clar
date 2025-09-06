;; Title: Whistleblower Token Reward System
;; Description: Token-based incentive system for safety violation reporting with anti-fraud protection
;; Version: 1.0.0

;; Constants for error codes
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_NOT_FOUND (err u201))
(define-constant ERR_ALREADY_CLAIMED (err u202))
(define-constant ERR_INVALID_PARAMETERS (err u203))
(define-constant ERR_INSUFFICIENT_BALANCE (err u204))
(define-constant ERR_VIOLATION_NOT_VERIFIED (err u205))
(define-constant ERR_REWARD_NOT_AVAILABLE (err u206))
(define-constant ERR_INVALID_SEVERITY (err u207))
(define-constant ERR_REPORTER_SUSPENDED (err u208))

;; System administrator (contract deployer)
(define-constant CONTRACT_ADMIN tx-sender)

;; Reward amounts based on severity
(define-constant REWARD_CRITICAL u50)
(define-constant REWARD_HIGH u30)
(define-constant REWARD_MEDIUM u15)
(define-constant REWARD_LOW u5)

;; Reputation multipliers
(define-constant REPUTATION_EXCELLENT_THRESHOLD u10) ;; 10+ verified reports
(define-constant REPUTATION_GOOD_THRESHOLD u5)       ;; 5+ verified reports
(define-constant REPUTATION_BONUS_MULTIPLIER u2)     ;; 2x bonus for excellent reputation
(define-constant REPUTATION_GOOD_MULTIPLIER u1)      ;; 1.5x bonus for good reputation (150%)

;; Token system constants
(define-constant TOKEN_SYMBOL "SAFE")
(define-constant TOKEN_DECIMALS u6)

;; Data variables
(define-data-var next-reward-id uint u1)
(define-data-var total-tokens-distributed uint u0)
(define-data-var total-rewards-claimed uint u0)
(define-data-var token-pool-balance uint u1000000) ;; Initial token pool (1M tokens)

;; Whistleblower token balances (using reporter hash for anonymity)
(define-map token-balances (buff 32) uint)

;; Whistleblower profiles (anonymous)
(define-map whistleblower-profiles (buff 32) {
    total-reports: uint,
    verified-reports: uint,
    reputation-score: uint,
    total-tokens-earned: uint,
    last-activity: uint,
    status: (string-ascii 20),
    suspension-end: (optional uint)
})

;; Token rewards tracking
(define-map token-rewards uint {
    reward-id: uint,
    violation-id: uint,
    reporter-hash: (buff 32),
    base-reward: uint,
    reputation-bonus: uint,
    total-reward: uint,
    claim-date: uint,
    verification-status: (string-ascii 20)
})

;; Violation to reward mapping
(define-map violation-rewards uint uint) ;; violation-id -> reward-id

;; Anti-fraud tracking
(define-map fraud-reports (buff 32) {
    total-fraud-reports: uint,
    last-fraud-date: uint,
    fraud-penalty: uint
})

;; Public functions

;; Claim token reward for a verified violation report
(define-public (claim-reward (violation-id uint))
    (let ((reporter tx-sender)
          (reporter-hash (generate-reporter-hash reporter stacks-block-height)))
        
        ;; Check if violation exists and is eligible for reward
        (let ((existing-reward-id (map-get? violation-rewards violation-id)))
            (asserts! (is-none existing-reward-id) ERR_ALREADY_CLAIMED))
        
        ;; Get violation severity (this would integrate with safety-tracker contract)
        (let ((severity (get-violation-severity violation-id)))
            (asserts! (is-some severity) ERR_NOT_FOUND)
            
            (let ((base-reward (calculate-base-reward (unwrap-panic severity)))
                  (profile (get-or-create-profile reporter-hash))
                  (reputation-bonus (calculate-reputation-bonus base-reward (get verified-reports profile)))
                  (total-reward (+ base-reward reputation-bonus))
                  (reward-id (var-get next-reward-id)))
                
                ;; Check if reporter is suspended
                (asserts! (not (is-reporter-suspended profile)) ERR_REPORTER_SUSPENDED)
                
                ;; Check token pool availability
                (asserts! (>= (var-get token-pool-balance) total-reward) ERR_INSUFFICIENT_BALANCE)
                
                ;; Record the reward
                (map-set token-rewards reward-id {
                    reward-id: reward-id,
                    violation-id: violation-id,
                    reporter-hash: reporter-hash,
                    base-reward: base-reward,
                    reputation-bonus: reputation-bonus,
                    total-reward: total-reward,
                    claim-date: stacks-block-height,
                    verification-status: "verified"
                })
                
                ;; Map violation to reward
                (map-set violation-rewards violation-id reward-id)
                
                ;; Update reporter token balance
                (let ((current-balance (default-to u0 (map-get? token-balances reporter-hash))))
                    (map-set token-balances reporter-hash (+ current-balance total-reward)))
                
                ;; Update whistleblower profile
                (map-set whistleblower-profiles reporter-hash 
                    (merge profile {
                        verified-reports: (+ (get verified-reports profile) u1),
                        total-tokens-earned: (+ (get total-tokens-earned profile) total-reward),
                        last-activity: stacks-block-height,
                        reputation-score: (calculate-reputation-score 
                            (+ (get verified-reports profile) u1)
                            (get total-reports profile))
                    }))
                
                ;; Update system counters
                (var-set next-reward-id (+ reward-id u1))
                (var-set total-tokens-distributed (+ (var-get total-tokens-distributed) total-reward))
                (var-set total-rewards-claimed (+ (var-get total-rewards-claimed) u1))
                (var-set token-pool-balance (- (var-get token-pool-balance) total-reward))
                
                (ok reward-id)))))

;; Transfer tokens between whistleblowers (anonymous)
(define-public (transfer-tokens 
                (recipient-hash (buff 32))
                (amount uint))
    (let ((sender tx-sender)
          (sender-hash (generate-reporter-hash sender stacks-block-height))
          (sender-balance (default-to u0 (map-get? token-balances sender-hash)))
          (recipient-balance (default-to u0 (map-get? token-balances recipient-hash))))
        
        ;; Validate parameters
        (asserts! (> amount u0) ERR_INVALID_PARAMETERS)
        (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
        
        ;; Update balances
        (map-set token-balances sender-hash (- sender-balance amount))
        (map-set token-balances recipient-hash (+ recipient-balance amount))
        
        (ok true)))

;; Report fraudulent violation (admin function)
(define-public (report-fraud (violation-id uint) (reporter-hash (buff 32)))
    (begin
        ;; Only admin can report fraud
        (asserts! (is-eq tx-sender CONTRACT_ADMIN) ERR_UNAUTHORIZED)
        
        ;; Update fraud tracking
        (let ((current-fraud (default-to 
                                { total-fraud-reports: u0, last-fraud-date: u0, fraud-penalty: u0 }
                                (map-get? fraud-reports reporter-hash))))
            (map-set fraud-reports reporter-hash 
                (merge current-fraud {
                    total-fraud-reports: (+ (get total-fraud-reports current-fraud) u1),
                    last-fraud-date: stacks-block-height,
                    fraud-penalty: (+ (get fraud-penalty current-fraud) u10) ;; 10 token penalty
                })))
        
        ;; Suspend reporter if too many fraud reports
        (let ((fraud-data (unwrap-panic (map-get? fraud-reports reporter-hash))))
            (if (>= (get total-fraud-reports fraud-data) u3) ;; 3 strikes rule
                (suspend-reporter reporter-hash u4320) ;; Suspend for ~30 days
                true))
        
        (ok true)))

;; Add tokens to the pool (admin function)
(define-public (add-tokens-to-pool (amount uint))
    (begin
        ;; Only admin can add tokens
        (asserts! (is-eq tx-sender CONTRACT_ADMIN) ERR_UNAUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_PARAMETERS)
        
        ;; Add to pool
        (var-set token-pool-balance (+ (var-get token-pool-balance) amount))
        
        (ok true)))

;; Private functions

;; Generate anonymous reporter hash
(define-private (generate-reporter-hash (reporter principal) (timestamp uint))
    (sha256 (concat (unwrap-panic (to-consensus-buff? reporter))
                   (unwrap-panic (to-consensus-buff? timestamp)))))

;; Get or create whistleblower profile
(define-private (get-or-create-profile (reporter-hash (buff 32)))
    (default-to 
        {
            total-reports: u1,
            verified-reports: u0,
            reputation-score: u0,
            total-tokens-earned: u0,
            last-activity: stacks-block-height,
            status: "active",
            suspension-end: none
        }
        (map-get? whistleblower-profiles reporter-hash)))

;; Calculate base reward based on severity
(define-private (calculate-base-reward (severity (string-ascii 20)))
    (if (is-eq severity "critical")
        REWARD_CRITICAL
        (if (is-eq severity "high")
            REWARD_HIGH
            (if (is-eq severity "medium")
                REWARD_MEDIUM
                REWARD_LOW))))

;; Calculate reputation bonus
(define-private (calculate-reputation-bonus (base-reward uint) (verified-reports uint))
    (if (>= verified-reports REPUTATION_EXCELLENT_THRESHOLD)
        (* base-reward REPUTATION_BONUS_MULTIPLIER)
        (if (>= verified-reports REPUTATION_GOOD_THRESHOLD)
            (/ (* base-reward u3) u2) ;; 1.5x multiplier
            u0)))

;; Calculate reputation score (0-100)
(define-private (calculate-reputation-score (verified uint) (total uint))
    (if (is-eq total u0)
        u0
        (let ((score (* (/ verified total) u100)))
            (if (> score u100)
                u100
                score))))

;; Check if reporter is suspended
(define-private (is-reporter-suspended (profile { total-reports: uint, verified-reports: uint, reputation-score: uint, total-tokens-earned: uint, last-activity: uint, status: (string-ascii 20), suspension-end: (optional uint) }))
    (match (get suspension-end profile)
        end-date (< stacks-block-height end-date)
        false))

;; Suspend reporter
(define-private (suspend-reporter (reporter-hash (buff 32)) (duration uint))
    (let ((profile (get-or-create-profile reporter-hash)))
        (map-set whistleblower-profiles reporter-hash 
            (merge profile {
                status: "suspended",
                suspension-end: (some (+ stacks-block-height duration))
            }))
        true))

;; Get violation severity (simplified - in real implementation, this would call safety-tracker contract)
(define-private (get-violation-severity (violation-id uint))
    ;; This is a simplified implementation
    ;; In production, this would integrate with the safety-tracker contract
    (if (< violation-id u100)
        (some "high")
        (some "medium")))

;; Read-only functions

;; Get token balance for a reporter
(define-read-only (get-token-balance (reporter-hash (buff 32)))
    (default-to u0 (map-get? token-balances reporter-hash)))

;; Get whistleblower profile
(define-read-only (get-whistleblower-profile (reporter-hash (buff 32)))
    (map-get? whistleblower-profiles reporter-hash))

;; Get reward information
(define-read-only (get-reward-info (reward-id uint))
    (map-get? token-rewards reward-id))

;; Get reward by violation ID
(define-read-only (get-reward-by-violation (violation-id uint))
    (match (map-get? violation-rewards violation-id)
        reward-id (map-get? token-rewards reward-id)
        none))

;; Get system token statistics
(define-read-only (get-token-stats)
    {
        total-tokens-distributed: (var-get total-tokens-distributed),
        total-rewards-claimed: (var-get total-rewards-claimed),
        token-pool-balance: (var-get token-pool-balance),
        next-reward-id: (var-get next-reward-id)
    })

;; Get fraud report information
(define-read-only (get-fraud-reports (reporter-hash (buff 32)))
    (map-get? fraud-reports reporter-hash))

;; Calculate potential reward for severity
(define-read-only (calculate-potential-reward 
                  (severity (string-ascii 20))
                  (verified-reports uint))
    (let ((base-reward (calculate-base-reward severity))
          (reputation-bonus (calculate-reputation-bonus base-reward verified-reports)))
        {
            base-reward: base-reward,
            reputation-bonus: reputation-bonus,
            total-reward: (+ base-reward reputation-bonus)
        }))

;; Check if violation has been rewarded
(define-read-only (is-violation-rewarded (violation-id uint))
    (is-some (map-get? violation-rewards violation-id)))

;; Get reporter reputation level
(define-read-only (get-reputation-level (verified-reports uint))
    (if (>= verified-reports REPUTATION_EXCELLENT_THRESHOLD)
        "excellent"
        (if (>= verified-reports REPUTATION_GOOD_THRESHOLD)
            "good"
            "new")))
