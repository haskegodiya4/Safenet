;; Title: Occupational Safety Violation Tracker
;; Description: Anonymous safety violation reporting system with comprehensive tracking
;; Version: 1.0.0

;; Constants for error codes
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_PARAMETERS (err u103))
(define-constant ERR_INVALID_SEVERITY (err u104))
(define-constant ERR_INVALID_STATUS (err u105))
(define-constant ERR_COMPANY_NOT_REGISTERED (err u106))
(define-constant ERR_VIOLATION_ALREADY_RESOLVED (err u107))
(define-constant ERR_INSUFFICIENT_PRIVILEGES (err u108))

;; System administrator (contract deployer)
(define-constant CONTRACT_ADMIN tx-sender)

;; Valid severity levels
(define-constant SEVERITY_CRITICAL "critical")
(define-constant SEVERITY_HIGH "high")
(define-constant SEVERITY_MEDIUM "medium")
(define-constant SEVERITY_LOW "low")

;; Valid violation statuses
(define-constant STATUS_REPORTED "reported")
(define-constant STATUS_INVESTIGATING "investigating")
(define-constant STATUS_RESOLVED "resolved")
(define-constant STATUS_DISMISSED "dismissed")

;; Data variables
(define-data-var next-company-id uint u1)
(define-data-var next-violation-id uint u1)
(define-data-var total-companies uint u0)
(define-data-var total-violations uint u0)
(define-data-var total-resolved-violations uint u0)

;; Company registration data
(define-map companies uint {
    company-id: uint,
    company-name: (string-ascii 100),
    industry: (string-ascii 50),
    registration-date: uint,
    admin: principal,
    total-violations: uint,
    resolved-violations: uint,
    compliance-score: uint,
    status: (string-ascii 20)
})

;; Safety violation records
(define-map violations uint {
    violation-id: uint,
    company-id: uint,
    department: (string-ascii 50),
    violation-type: (string-ascii 100),
    severity: (string-ascii 20),
    description: (string-ascii 500),
    evidence-hash: (string-ascii 64),
    reporter-hash: (buff 32),
    status: (string-ascii 20),
    reported-date: uint,
    resolution-date: (optional uint),
    resolution-notes: (optional (string-ascii 300)),
    reward-claimed: bool
})

;; Company name mapping for uniqueness
(define-map company-names (string-ascii 100) uint)

;; Reporter tracking (anonymous)
(define-map reporter-stats (buff 32) {
    total-reports: uint,
    verified-reports: uint,
    last-report-date: uint
})

;; Public functions

;; Register a new company in the system
(define-public (register-company (company-name (string-ascii 100)) (industry (string-ascii 50)))
    (let ((company-id (var-get next-company-id))
          (admin tx-sender))
        
        ;; Validate input parameters
        (asserts! (> (len company-name) u0) ERR_INVALID_PARAMETERS)
        (asserts! (> (len industry) u0) ERR_INVALID_PARAMETERS)
        
        ;; Check if company name already exists
        (asserts! (is-none (map-get? company-names company-name)) ERR_ALREADY_EXISTS)
        
        ;; Register company
        (map-set companies company-id {
            company-id: company-id,
            company-name: company-name,
            industry: industry,
            registration-date: stacks-block-height,
            admin: admin,
            total-violations: u0,
            resolved-violations: u0,
            compliance-score: u100,
            status: "active"
        })
        
        ;; Map company name to ID
        (map-set company-names company-name company-id)
        
        ;; Update counters
        (var-set next-company-id (+ company-id u1))
        (var-set total-companies (+ (var-get total-companies) u1))
        
        (ok company-id)))

;; Report a safety violation anonymously
(define-public (report-violation 
                (company-id uint)
                (department (string-ascii 50))
                (violation-type (string-ascii 100))
                (severity (string-ascii 20))
                (description (string-ascii 500))
                (evidence-hash (string-ascii 64)))
    (let ((violation-id (var-get next-violation-id))
          (reporter-hash (generate-reporter-hash tx-sender stacks-block-height))
          (company-data (unwrap! (map-get? companies company-id) ERR_COMPANY_NOT_REGISTERED)))
        
        ;; Validate input parameters
        (asserts! (> (len department) u0) ERR_INVALID_PARAMETERS)
        (asserts! (> (len violation-type) u0) ERR_INVALID_PARAMETERS)
        (asserts! (> (len description) u0) ERR_INVALID_PARAMETERS)
        (asserts! (> (len evidence-hash) u0) ERR_INVALID_PARAMETERS)
        
        ;; Validate severity level
        (asserts! (is-valid-severity severity) ERR_INVALID_SEVERITY)
        
        ;; Check if company is active
        (asserts! (is-eq (get status company-data) "active") ERR_COMPANY_NOT_REGISTERED)
        
        ;; Record violation
        (map-set violations violation-id {
            violation-id: violation-id,
            company-id: company-id,
            department: department,
            violation-type: violation-type,
            severity: severity,
            description: description,
            evidence-hash: evidence-hash,
            reporter-hash: reporter-hash,
            status: STATUS_REPORTED,
            reported-date: stacks-block-height,
            resolution-date: none,
            resolution-notes: none,
            reward-claimed: false
        })
        
        ;; Update company violation count
        (map-set companies company-id 
            (merge company-data {
                total-violations: (+ (get total-violations company-data) u1),
                compliance-score: (calculate-compliance-score 
                    (+ (get total-violations company-data) u1)
                    (get resolved-violations company-data))
            }))
        
        ;; Update reporter statistics
        (update-reporter-stats reporter-hash)
        
        ;; Update global counters
        (var-set next-violation-id (+ violation-id u1))
        (var-set total-violations (+ (var-get total-violations) u1))
        
        (ok violation-id)))

;; Update violation status (company admin or system admin only)
(define-public (update-violation-status 
                (violation-id uint)
                (new-status (string-ascii 20))
                (resolution-notes (string-ascii 300)))
    (let ((violation-data (unwrap! (map-get? violations violation-id) ERR_NOT_FOUND))
          (company-data (unwrap! (map-get? companies (get company-id violation-data)) ERR_NOT_FOUND)))
        
        ;; Check authorization (company admin or system admin)
        (asserts! (or (is-eq tx-sender (get admin company-data))
                     (is-eq tx-sender CONTRACT_ADMIN)) ERR_UNAUTHORIZED)
        
        ;; Validate status
        (asserts! (is-valid-status new-status) ERR_INVALID_STATUS)
        
        ;; Check if violation is already resolved
        (asserts! (not (is-eq (get status violation-data) STATUS_RESOLVED)) ERR_VIOLATION_ALREADY_RESOLVED)
        
        ;; Update violation status
        (map-set violations violation-id 
            (merge violation-data {
                status: new-status,
                resolution-date: (if (is-eq new-status STATUS_RESOLVED)
                                   (some stacks-block-height)
                                   none),
                resolution-notes: (some resolution-notes)
            }))
        
        ;; If resolved, update company resolved count
        (if (is-eq new-status STATUS_RESOLVED)
            (begin
                (map-set companies (get company-id violation-data)
                    (merge company-data {
                        resolved-violations: (+ (get resolved-violations company-data) u1),
                        compliance-score: (calculate-compliance-score
                            (get total-violations company-data)
                            (+ (get resolved-violations company-data) u1))
                    }))
                (var-set total-resolved-violations (+ (var-get total-resolved-violations) u1))
                true)
            true)
        
        (ok true)))

;; Update company information (admin only)
(define-public (update-company-info 
                (company-id uint)
                (new-company-name (string-ascii 100))
                (new-industry (string-ascii 50)))
    (let ((company-data (unwrap! (map-get? companies company-id) ERR_NOT_FOUND)))
        
        ;; Check authorization
        (asserts! (is-eq tx-sender (get admin company-data)) ERR_UNAUTHORIZED)
        
        ;; Validate parameters
        (asserts! (> (len new-company-name) u0) ERR_INVALID_PARAMETERS)
        (asserts! (> (len new-industry) u0) ERR_INVALID_PARAMETERS)
        
        ;; Check if new name conflicts (if different from current)
        (if (not (is-eq new-company-name (get company-name company-data)))
            (asserts! (is-none (map-get? company-names new-company-name)) ERR_ALREADY_EXISTS)
            true)
        
        ;; Update company information
        (map-set companies company-id 
            (merge company-data {
                company-name: new-company-name,
                industry: new-industry
            }))
        
        ;; Update name mapping if changed
        (if (not (is-eq new-company-name (get company-name company-data)))
            (begin
                (map-delete company-names (get company-name company-data))
                (map-set company-names new-company-name company-id)
                true)
            true)
        
        (ok true)))

;; Private functions

;; Generate anonymous reporter hash
(define-private (generate-reporter-hash (reporter principal) (timestamp uint))
    ;; Simple hash generation for anonymity (in production, use more sophisticated hashing)
    (sha256 (concat (unwrap-panic (to-consensus-buff? reporter))
                   (unwrap-panic (to-consensus-buff? timestamp)))))

;; Validate severity level
(define-private (is-valid-severity (severity (string-ascii 20)))
    (or (is-eq severity SEVERITY_CRITICAL)
        (is-eq severity SEVERITY_HIGH)
        (is-eq severity SEVERITY_MEDIUM)
        (is-eq severity SEVERITY_LOW)))

;; Validate status
(define-private (is-valid-status (status (string-ascii 20)))
    (or (is-eq status STATUS_REPORTED)
        (is-eq status STATUS_INVESTIGATING)
        (is-eq status STATUS_RESOLVED)
        (is-eq status STATUS_DISMISSED)))

;; Calculate compliance score (0-100)
(define-private (calculate-compliance-score (total uint) (resolved uint))
    (if (is-eq total u0)
        u100
        (let ((unresolved (- total resolved))
              (penalty (* unresolved u5)))
            (if (is-eq unresolved u0)
                u100
                (if (> penalty u100)
                    u0
                    (- u100 penalty))))))

;; Update reporter statistics
(define-private (update-reporter-stats (reporter-hash (buff 32)))
    (let ((current-stats (default-to 
                            { total-reports: u0, verified-reports: u0, last-report-date: u0 }
                            (map-get? reporter-stats reporter-hash))))
        (map-set reporter-stats reporter-hash 
            (merge current-stats {
                total-reports: (+ (get total-reports current-stats) u1),
                last-report-date: stacks-block-height
            }))
        true))

;; Read-only functions

;; Get company information
(define-read-only (get-company (company-id uint))
    (map-get? companies company-id))

;; Get violation information
(define-read-only (get-violation (violation-id uint))
    (map-get? violations violation-id))

;; Get company by name
(define-read-only (get-company-by-name (company-name (string-ascii 100)))
    (match (map-get? company-names company-name)
        company-id (map-get? companies company-id)
        none))

;; Get reporter statistics
(define-read-only (get-reporter-stats (reporter-hash (buff 32)))
    (map-get? reporter-stats reporter-hash))

;; Get system statistics
(define-read-only (get-system-stats)
    {
        total-companies: (var-get total-companies),
        total-violations: (var-get total-violations),
        resolved-violations: (var-get total-resolved-violations),
        next-company-id: (var-get next-company-id),
        next-violation-id: (var-get next-violation-id)
    })

;; Check if company exists
(define-read-only (company-exists (company-id uint))
    (is-some (map-get? companies company-id)))

;; Get violations by company
(define-read-only (get-company-violations (company-id uint))
    (match (map-get? companies company-id)
        company-data (some {
            company-id: company-id,
            total-violations: (get total-violations company-data),
            resolved-violations: (get resolved-violations company-data),
            compliance-score: (get compliance-score company-data)
        })
        none))

;; Get violation severity reward amount
(define-read-only (get-severity-reward (severity (string-ascii 20)))
    (if (is-eq severity SEVERITY_CRITICAL)
        u50
        (if (is-eq severity SEVERITY_HIGH)
            u30
            (if (is-eq severity SEVERITY_MEDIUM)
                u15
                u5))))
