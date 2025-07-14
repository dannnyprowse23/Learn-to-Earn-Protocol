;; title: learn-to-earn

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_MODULE (err u101))
(define-constant ERR_ALREADY_COMPLETED (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_INVALID_QUIZ (err u104))
(define-constant ERR_QUIZ_NOT_PASSED (err u105))
(define-constant ERR_REWARD_ALREADY_CLAIMED (err u106))
(define-constant ERR_MODULE_NOT_ACTIVE (err u107))
(define-constant ERR_INVALID_SCORE (err u108))
(define-constant ERR_COOLDOWN_ACTIVE (err u109))

(define-data-var next-module-id uint u1)
(define-data-var next-quiz-id uint u1)
(define-data-var contract-balance uint u0)
(define-data-var total-rewards-distributed uint u0)
(define-data-var platform-fee-percentage uint u5)

(define-map learning-modules 
  uint 
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    reward-amount: uint,
    creator: principal,
    is-active: bool,
    completion-count: uint,
    created-at: uint,
    difficulty-level: uint
  }
)

(define-map user-module-progress
  {user: principal, module-id: uint}
  {
    completed: bool,
    completion-time: uint,
    score: uint,
    attempts: uint,
    reward-claimed: bool
  }
)

(define-map quizzes
  uint
  {
    module-id: uint,
    question: (string-ascii 500),
    options: (list 4 (string-ascii 200)),
    correct-answer: uint,
    passing-score: uint,
    max-attempts: uint,
    is-active: bool
  }
)

(define-map quiz-attempts
  {user: principal, quiz-id: uint}
  {
    attempts: uint,
    best-score: uint,
    passed: bool,
    last-attempt: uint
  }
)

(define-map user-profiles
  principal
  {
    total-modules-completed: uint,
    total-rewards-earned: uint,
    streak: uint,
    last-activity: uint,
    level: uint,
    experience-points: uint
  }
)

(define-map module-reviews
  {module-id: uint, user: principal}
  {
    rating: uint,
    review: (string-ascii 500),
    created-at: uint
  }
)

(define-public (create-module (title (string-ascii 100)) (description (string-ascii 500)) (reward-amount uint) (difficulty-level uint))
  (let ((module-id (var-get next-module-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> reward-amount u0) ERR_INSUFFICIENT_FUNDS)
    (asserts! (<= difficulty-level u5) ERR_INVALID_MODULE)
    (map-set learning-modules module-id {
      title: title,
      description: description,
      reward-amount: reward-amount,
      creator: tx-sender,
      is-active: true,
      completion-count: u0,
      created-at: stacks-block-height,
      difficulty-level: difficulty-level
    })
    (var-set next-module-id (+ module-id u1))
    (ok module-id)
  )
)

(define-public (create-quiz (module-id uint) (question (string-ascii 500)) (options (list 4 (string-ascii 200))) (correct-answer uint) (passing-score uint) (max-attempts uint))
  (let ((quiz-id (var-get next-quiz-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? learning-modules module-id)) ERR_INVALID_MODULE)
    (asserts! (and (>= correct-answer u1) (<= correct-answer u4)) ERR_INVALID_QUIZ)
    (asserts! (and (> passing-score u0) (<= passing-score u100)) ERR_INVALID_SCORE)
    (map-set quizzes quiz-id {
      module-id: module-id,
      question: question,
      options: options,
      correct-answer: correct-answer,
      passing-score: passing-score,
      max-attempts: max-attempts,
      is-active: true
    })
    (var-set next-quiz-id (+ quiz-id u1))
    (ok quiz-id)
  )
)

(define-public (complete-module (module-id uint) (score uint))
  (let (
    (module-data (unwrap! (map-get? learning-modules module-id) ERR_INVALID_MODULE))
    (user-progress (default-to {completed: false, completion-time: u0, score: u0, attempts: u0, reward-claimed: false} (map-get? user-module-progress {user: tx-sender, module-id: module-id})))
    (user-profile (default-to {total-modules-completed: u0, total-rewards-earned: u0, streak: u0, last-activity: u0, level: u1, experience-points: u0} (map-get? user-profiles tx-sender)))
  )
    (asserts! (get is-active module-data) ERR_MODULE_NOT_ACTIVE)
    (asserts! (not (get completed user-progress)) ERR_ALREADY_COMPLETED)
    (asserts! (and (>= score u0) (<= score u100)) ERR_INVALID_SCORE)
    (map-set user-module-progress {user: tx-sender, module-id: module-id} {
      completed: true,
      completion-time: stacks-block-height,
      score: score,
      attempts: (+ (get attempts user-progress) u1),
      reward-claimed: false
    })
    (map-set learning-modules module-id (merge module-data {completion-count: (+ (get completion-count module-data) u1)}))
    (map-set user-profiles tx-sender {
      total-modules-completed: (+ (get total-modules-completed user-profile) u1),
      total-rewards-earned: (get total-rewards-earned user-profile),
      streak: (calculate-streak tx-sender),
      last-activity: stacks-block-height,
      level: (calculate-level (+ (get experience-points user-profile) (get difficulty-level module-data))),
      experience-points: (+ (get experience-points user-profile) (get difficulty-level module-data))
    })
    (ok true)
  )
)

(define-public (take-quiz (quiz-id uint) (answer uint))
  (let (
    (quiz-data (unwrap! (map-get? quizzes quiz-id) ERR_INVALID_QUIZ))
    (attempt-data (default-to {attempts: u0, best-score: u0, passed: false, last-attempt: u0} (map-get? quiz-attempts {user: tx-sender, quiz-id: quiz-id})))
    (is-correct (is-eq answer (get correct-answer quiz-data)))
    (current-score (if is-correct u100 u0))
    (cooldown-period u10)
  )
    (asserts! (get is-active quiz-data) ERR_INVALID_QUIZ)
    (asserts! (< (get attempts attempt-data) (get max-attempts quiz-data)) ERR_QUIZ_NOT_PASSED)
    (asserts! (> (+ (get last-attempt attempt-data) cooldown-period) stacks-block-height) ERR_COOLDOWN_ACTIVE)
    (map-set quiz-attempts {user: tx-sender, quiz-id: quiz-id} {
      attempts: (+ (get attempts attempt-data) u1),
      best-score: (if (> current-score (get best-score attempt-data)) current-score (get best-score attempt-data)),
      passed: (or (get passed attempt-data) (>= current-score (get passing-score quiz-data))),
      last-attempt: stacks-block-height
    })
    (ok {score: current-score, passed: (>= current-score (get passing-score quiz-data))})
  )
)

(define-public (claim-reward (module-id uint))
  (let (
    (module-data (unwrap! (map-get? learning-modules module-id) ERR_INVALID_MODULE))
    (user-progress (unwrap! (map-get? user-module-progress {user: tx-sender, module-id: module-id}) ERR_INVALID_MODULE))
    (user-profile (default-to {total-modules-completed: u0, total-rewards-earned: u0, streak: u0, last-activity: u0, level: u1, experience-points: u0} (map-get? user-profiles tx-sender)))
    (reward-amount (get reward-amount module-data))
    (platform-fee (/ (* reward-amount (var-get platform-fee-percentage)) u100))
    (user-reward (- reward-amount platform-fee))
  )
    (asserts! (get completed user-progress) ERR_INVALID_MODULE)
    (asserts! (not (get reward-claimed user-progress)) ERR_REWARD_ALREADY_CLAIMED)
    (asserts! (>= (var-get contract-balance) reward-amount) ERR_INSUFFICIENT_FUNDS)
    (try! (stx-transfer? user-reward (as-contract tx-sender) tx-sender))
    (map-set user-module-progress {user: tx-sender, module-id: module-id} (merge user-progress {reward-claimed: true}))
    (map-set user-profiles tx-sender (merge user-profile {total-rewards-earned: (+ (get total-rewards-earned user-profile) user-reward)}))
    (var-set contract-balance (- (var-get contract-balance) reward-amount))
    (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) user-reward))
    (ok user-reward)
  )
)

(define-public (submit-review (module-id uint) (rating uint) (review (string-ascii 500)))
  (let ((user-progress (unwrap! (map-get? user-module-progress {user: tx-sender, module-id: module-id}) ERR_INVALID_MODULE)))
    (asserts! (get completed user-progress) ERR_INVALID_MODULE)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_SCORE)
    (map-set module-reviews {module-id: module-id, user: tx-sender} {
      rating: rating,
      review: review,
      created-at: stacks-block-height
    })
    (ok true)
  )
)

(define-public (fund-contract (amount uint))
  (begin
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set contract-balance (+ (var-get contract-balance) amount))
    (ok true)
  )
)

(define-public (toggle-module-status (module-id uint))
  (let ((module-data (unwrap! (map-get? learning-modules module-id) ERR_INVALID_MODULE)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set learning-modules module-id (merge module-data {is-active: (not (get is-active module-data))}))
    (ok (not (get is-active module-data)))
  )
)

(define-public (update-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-fee u20) ERR_INVALID_SCORE)
    (var-set platform-fee-percentage new-fee)
    (ok new-fee)
  )
)

(define-read-only (get-module (module-id uint))
  (map-get? learning-modules module-id)
)

(define-read-only (get-user-progress (user principal) (module-id uint))
  (map-get? user-module-progress {user: user, module-id: module-id})
)

(define-read-only (get-quiz (quiz-id uint))
  (map-get? quizzes quiz-id)
)

(define-read-only (get-quiz-attempts (user principal) (quiz-id uint))
  (map-get? quiz-attempts {user: user, quiz-id: quiz-id})
)

(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles user)
)

(define-read-only (get-contract-stats)
  {
    total-modules: (- (var-get next-module-id) u1),
    total-quizzes: (- (var-get next-quiz-id) u1),
    contract-balance: (var-get contract-balance),
    total-rewards-distributed: (var-get total-rewards-distributed),
    platform-fee: (var-get platform-fee-percentage)
  }
)

(define-read-only (get-module-review (module-id uint) (user principal))
  (map-get? module-reviews {module-id: module-id, user: user})
)

(define-private (calculate-streak (user principal))
  (let ((profile (default-to {total-modules-completed: u0, total-rewards-earned: u0, streak: u0, last-activity: u0, level: u1, experience-points: u0} (map-get? user-profiles user))))
    (if (< (- stacks-block-height (get last-activity profile)) u1440)
      (+ (get streak profile) u1)
      u1
    )
  )
)

(define-private (calculate-level (experience uint))
  (if (< experience u10) u1
    (if (< experience u25) u2
      (if (< experience u50) u3
        (if (< experience u100) u4
          u5
        )
      )
    )
  )
)
