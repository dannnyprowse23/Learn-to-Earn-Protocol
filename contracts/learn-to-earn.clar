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
(define-constant ERR_PATH_NOT_FOUND (err u110))
(define-constant ERR_ALREADY_ENROLLED (err u111))
(define-constant ERR_PREREQUISITE_NOT_MET (err u112))
(define-constant ERR_PATH_NOT_COMPLETED (err u113))
(define-constant ERR_BONUS_ALREADY_CLAIMED (err u114))
(define-constant ERR_MENTOR_NOT_FOUND (err u115))
(define-constant ERR_MENTORSHIP_NOT_FOUND (err u116))
(define-constant ERR_SESSION_NOT_FOUND (err u117))
(define-constant ERR_ALREADY_MENTOR (err u118))
(define-constant ERR_CANNOT_MENTOR_SELF (err u119))
(define-constant ERR_SESSION_ALREADY_COMPLETED (err u120))
(define-constant ERR_INSUFFICIENT_LEVEL (err u121))
(define-constant ERR_MENTOR_UNAVAILABLE (err u122))
(define-constant ERR_BADGE_NOT_FOUND (err u123))
(define-constant ERR_BADGE_ALREADY_EARNED (err u124))
(define-constant ERR_BADGE_REQUIREMENTS_NOT_MET (err u125))

(define-constant BADGE_FIRST_MODULE u1)
(define-constant BADGE_PATH_COMPLETION u2)
(define-constant BADGE_MENTOR_STATUS u3)
(define-constant BADGE_FIVE_MODULES u4)
(define-constant BADGE_PERFECT_SCORE u5)
(define-constant BADGE_FAST_LEARNER u6)

(define-data-var next-module-id uint u1)
(define-data-var next-quiz-id uint u1)
(define-data-var next-path-id uint u1)
(define-data-var next-session-id uint u1)
(define-data-var contract-balance uint u0)
(define-data-var total-rewards-distributed uint u0)
(define-data-var platform-fee-percentage uint u5)
(define-data-var mentor-reward-per-session uint u1000)
(define-data-var min-mentor-level uint u3)

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

(define-map learning-paths
  uint
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    module-sequence: (list 10 uint),
    bonus-reward: uint,
    creator: principal,
    is-active: bool,
    enrollments: uint,
    created-at: uint
  }
)

(define-map user-path-progress
  {user: principal, path-id: uint}
  {
    enrolled: bool,
    current-module-index: uint,
    completed: bool,
    bonus-claimed: bool,
    enrolled-at: uint,
    completed-at: uint
  }
)

(define-map mentors
  principal
  {
    is-active: bool,
    specialties: (list 5 uint),
    total-sessions: uint,
    successful-sessions: uint,
    rating: uint,
    total-earned: uint,
    joined-at: uint
  }
)

(define-map mentorship-sessions
  uint
  {
    mentor: principal,
    mentee: principal,
    module-id: uint,
    status: uint,
    created-at: uint,
    completed-at: uint,
    mentor-rating: uint,
    mentee-rating: uint,
    reward-claimed: bool
  }
)

(define-map mentorship-requests
  {mentee: principal, module-id: uint}
  {
    created-at: uint,
    matched: bool,
    session-id: (optional uint)
  }
)

(define-map achievement-badges
  uint
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    badge-type: uint,
    requirement-value: uint,
    is-active: bool,
    total-earned: uint
  }
)

(define-map user-badges
  {user: principal, badge-id: uint}
  {
    earned: bool,
    earned-at: uint,
    metadata: (string-ascii 100)
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

(define-public (create-learning-path (title (string-ascii 100)) (description (string-ascii 500)) (module-sequence (list 10 uint)) (bonus-reward uint))
  (let ((path-id (var-get next-path-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> (len module-sequence) u0) ERR_INVALID_MODULE)
    (asserts! (>= bonus-reward u0) ERR_INSUFFICIENT_FUNDS)
    (try! (validate-module-sequence module-sequence))
    (map-set learning-paths path-id {
      title: title,
      description: description,
      module-sequence: module-sequence,
      bonus-reward: bonus-reward,
      creator: tx-sender,
      is-active: true,
      enrollments: u0,
      created-at: stacks-block-height
    })
    (var-set next-path-id (+ path-id u1))
    (ok path-id)
  )
)

(define-public (enroll-in-path (path-id uint))
  (let (
    (path-data (unwrap! (map-get? learning-paths path-id) ERR_PATH_NOT_FOUND))
    (existing-progress (map-get? user-path-progress {user: tx-sender, path-id: path-id}))
  )
    (asserts! (get is-active path-data) ERR_PATH_NOT_FOUND)
    (asserts! (is-none existing-progress) ERR_ALREADY_ENROLLED)
    (map-set user-path-progress {user: tx-sender, path-id: path-id} {
      enrolled: true,
      current-module-index: u0,
      completed: false,
      bonus-claimed: false,
      enrolled-at: stacks-block-height,
      completed-at: u0
    })
    (map-set learning-paths path-id (merge path-data {enrollments: (+ (get enrollments path-data) u1)}))
    (ok true)
  )
)

(define-public (advance-in-path (path-id uint))
  (let (
    (path-data (unwrap! (map-get? learning-paths path-id) ERR_PATH_NOT_FOUND))
    (user-progress (unwrap! (map-get? user-path-progress {user: tx-sender, path-id: path-id}) ERR_PATH_NOT_FOUND))
    (current-index (get current-module-index user-progress))
    (module-sequence (get module-sequence path-data))
    (current-module-id (unwrap! (element-at module-sequence current-index) ERR_INVALID_MODULE))
    (module-progress (unwrap! (map-get? user-module-progress {user: tx-sender, module-id: current-module-id}) ERR_INVALID_MODULE))
  )
    (asserts! (get enrolled user-progress) ERR_PATH_NOT_FOUND)
    (asserts! (not (get completed user-progress)) ERR_ALREADY_COMPLETED)
    (asserts! (get completed module-progress) ERR_PREREQUISITE_NOT_MET)
    (let ((next-index (+ current-index u1)))
      (if (>= next-index (len module-sequence))
        (begin
          (map-set user-path-progress {user: tx-sender, path-id: path-id} (merge user-progress {
            completed: true,
            completed-at: stacks-block-height
          }))
          (ok {completed: true, next-module: none})
        )
        (begin
          (map-set user-path-progress {user: tx-sender, path-id: path-id} (merge user-progress {
            current-module-index: next-index
          }))
          (ok {completed: false, next-module: (element-at module-sequence next-index)})
        )
      )
    )
  )
)

(define-public (claim-path-bonus (path-id uint))
  (let (
    (path-data (unwrap! (map-get? learning-paths path-id) ERR_PATH_NOT_FOUND))
    (user-progress (unwrap! (map-get? user-path-progress {user: tx-sender, path-id: path-id}) ERR_PATH_NOT_FOUND))
    (user-profile (default-to {total-modules-completed: u0, total-rewards-earned: u0, streak: u0, last-activity: u0, level: u1, experience-points: u0} (map-get? user-profiles tx-sender)))
    (bonus-amount (get bonus-reward path-data))
  )
    (asserts! (get completed user-progress) ERR_PATH_NOT_COMPLETED)
    (asserts! (not (get bonus-claimed user-progress)) ERR_BONUS_ALREADY_CLAIMED)
    (asserts! (>= (var-get contract-balance) bonus-amount) ERR_INSUFFICIENT_FUNDS)
    (if (> bonus-amount u0)
      (try! (stx-transfer? bonus-amount (as-contract tx-sender) tx-sender))
      true
    )
    (map-set user-path-progress {user: tx-sender, path-id: path-id} (merge user-progress {bonus-claimed: true}))
    (map-set user-profiles tx-sender (merge user-profile {total-rewards-earned: (+ (get total-rewards-earned user-profile) bonus-amount)}))
    (var-set contract-balance (- (var-get contract-balance) bonus-amount))
    (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) bonus-amount))
    (ok bonus-amount)
  )
)

(define-public (become-mentor (specialties (list 5 uint)))
  (let (
    (user-profile (default-to {total-modules-completed: u0, total-rewards-earned: u0, streak: u0, last-activity: u0, level: u1, experience-points: u0} (map-get? user-profiles tx-sender)))
    (existing-mentor (map-get? mentors tx-sender))
  )
    (asserts! (>= (get level user-profile) (var-get min-mentor-level)) ERR_INSUFFICIENT_LEVEL)
    (asserts! (is-none existing-mentor) ERR_ALREADY_MENTOR)
    (asserts! (> (len specialties) u0) ERR_INVALID_MODULE)
    (try! (validate-specialty-modules specialties))
    (map-set mentors tx-sender {
      is-active: true,
      specialties: specialties,
      total-sessions: u0,
      successful-sessions: u0,
      rating: u50,
      total-earned: u0,
      joined-at: stacks-block-height
    })
    (ok true)
  )
)

(define-public (update-mentor-status (active bool))
  (let ((mentor-data (unwrap! (map-get? mentors tx-sender) ERR_MENTOR_NOT_FOUND)))
    (map-set mentors tx-sender (merge mentor-data {is-active: active}))
    (ok active)
  )
)

(define-public (request-mentor (module-id uint))
  (let (
    (module-data (unwrap! (map-get? learning-modules module-id) ERR_INVALID_MODULE))
    (existing-request (map-get? mentorship-requests {mentee: tx-sender, module-id: module-id}))
  )
    (asserts! (get is-active module-data) ERR_MODULE_NOT_ACTIVE)
    (asserts! (is-none existing-request) ERR_ALREADY_ENROLLED)
    (map-set mentorship-requests {mentee: tx-sender, module-id: module-id} {
      created-at: stacks-block-height,
      matched: false,
      session-id: none
    })
    (ok true)
  )
)

(define-public (accept-mentorship (mentee principal) (module-id uint))
  (let (
    (mentor-data (unwrap! (map-get? mentors tx-sender) ERR_MENTOR_NOT_FOUND))
    (request-data (unwrap! (map-get? mentorship-requests {mentee: mentee, module-id: module-id}) ERR_MENTORSHIP_NOT_FOUND))
    (session-id (var-get next-session-id))
  )
    (asserts! (get is-active mentor-data) ERR_MENTOR_UNAVAILABLE)
    (asserts! (not (get matched request-data)) ERR_ALREADY_ENROLLED)
    (asserts! (not (is-eq tx-sender mentee)) ERR_CANNOT_MENTOR_SELF)
    (asserts! (is-mentor-qualified tx-sender module-id) ERR_INSUFFICIENT_LEVEL)
    (map-set mentorship-sessions session-id {
      mentor: tx-sender,
      mentee: mentee,
      module-id: module-id,
      status: u1,
      created-at: stacks-block-height,
      completed-at: u0,
      mentor-rating: u0,
      mentee-rating: u0,
      reward-claimed: false
    })
    (map-set mentorship-requests {mentee: mentee, module-id: module-id} (merge request-data {
      matched: true,
      session-id: (some session-id)
    }))
    (var-set next-session-id (+ session-id u1))
    (ok session-id)
  )
)

(define-public (complete-mentorship-session (session-id uint))
  (let (
    (session-data (unwrap! (map-get? mentorship-sessions session-id) ERR_SESSION_NOT_FOUND))
  )
    (asserts! (or (is-eq tx-sender (get mentor session-data)) (is-eq tx-sender (get mentee session-data))) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status session-data) u1) ERR_SESSION_ALREADY_COMPLETED)
    (map-set mentorship-sessions session-id (merge session-data {
      status: u2,
      completed-at: stacks-block-height
    }))
    (ok true)
  )
)

(define-public (rate-mentorship (session-id uint) (rating uint))
  (let (
    (session-data (unwrap! (map-get? mentorship-sessions session-id) ERR_SESSION_NOT_FOUND))
    (is-mentor (is-eq tx-sender (get mentor session-data)))
    (is-mentee (is-eq tx-sender (get mentee session-data)))
  )
    (asserts! (or is-mentor is-mentee) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status session-data) u2) ERR_SESSION_NOT_FOUND)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR_INVALID_SCORE)
    (map-set mentorship-sessions session-id
      (if is-mentor
        (merge session-data {mentor-rating: rating})
        (merge session-data {mentee-rating: rating})
      )
    )
    (ok true)
  )
)

(define-public (claim-mentorship-reward (session-id uint))
  (let (
    (session-data (unwrap! (map-get? mentorship-sessions session-id) ERR_SESSION_NOT_FOUND))
    (mentor-data (unwrap! (map-get? mentors (get mentor session-data)) ERR_MENTOR_NOT_FOUND))
    (reward-amount (var-get mentor-reward-per-session))
  )
    (asserts! (is-eq tx-sender (get mentor session-data)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status session-data) u2) ERR_SESSION_NOT_FOUND)
    (asserts! (not (get reward-claimed session-data)) ERR_REWARD_ALREADY_CLAIMED)
    (asserts! (> (get mentee-rating session-data) u0) ERR_INVALID_SCORE)
    (asserts! (>= (var-get contract-balance) reward-amount) ERR_INSUFFICIENT_FUNDS)
    (let (
        (is-successful (>= (get mentee-rating session-data) u3))
        (final-reward (if is-successful reward-amount (/ reward-amount u2)))
      )
      (try! (stx-transfer? final-reward (as-contract tx-sender) tx-sender))
      (map-set mentorship-sessions session-id (merge session-data {reward-claimed: true}))
      (map-set mentors (get mentor session-data) (merge mentor-data {
        total-sessions: (+ (get total-sessions mentor-data) u1),
        successful-sessions: (if is-successful
          (+ (get successful-sessions mentor-data) u1)
          (get successful-sessions mentor-data)
        ),
        rating: (calculate-mentor-rating (get mentor session-data) (get mentee-rating session-data)),
        total-earned: (+ (get total-earned mentor-data) final-reward)
      }))
      (var-set contract-balance (- (var-get contract-balance) final-reward))
      (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) final-reward))
      (ok final-reward)
    )
  )
)

(define-public (update-mentor-rewards (new-reward uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> new-reward u0) ERR_INVALID_SCORE)
    (var-set mentor-reward-per-session new-reward)
    (ok new-reward)
  )
)

(define-public (create-badge (name (string-ascii 50)) (description (string-ascii 200)) (badge-type uint) (requirement-value uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (and (>= badge-type u1) (<= badge-type u6)) ERR_INVALID_MODULE)
    (map-set achievement-badges badge-type {
      name: name,
      description: description,
      badge-type: badge-type,
      requirement-value: requirement-value,
      is-active: true,
      total-earned: u0
    })
    (ok badge-type)
  )
)

(define-public (claim-badge (badge-id uint))
  (let (
    (badge-data (unwrap! (map-get? achievement-badges badge-id) ERR_BADGE_NOT_FOUND))
    (user-profile (default-to {total-modules-completed: u0, total-rewards-earned: u0, streak: u0, last-activity: u0, level: u1, experience-points: u0} (map-get? user-profiles tx-sender)))
    (existing-badge (map-get? user-badges {user: tx-sender, badge-id: badge-id}))
  )
    (asserts! (get is-active badge-data) ERR_BADGE_NOT_FOUND)
    (asserts! (is-none existing-badge) ERR_BADGE_ALREADY_EARNED)
    (asserts! (check-badge-requirements badge-id (get badge-type badge-data) (get requirement-value badge-data) user-profile) ERR_BADGE_REQUIREMENTS_NOT_MET)
    (map-set user-badges {user: tx-sender, badge-id: badge-id} {
      earned: true,
      earned-at: stacks-block-height,
      metadata: ""
    })
    (map-set achievement-badges badge-id (merge badge-data {total-earned: (+ (get total-earned badge-data) u1)}))
    (ok true)
  )
)

(define-public (auto-award-badge (user principal) (badge-id uint))
  (let (
    (badge-data (unwrap! (map-get? achievement-badges badge-id) ERR_BADGE_NOT_FOUND))
    (existing-badge (map-get? user-badges {user: user, badge-id: badge-id}))
  )
    (asserts! (get is-active badge-data) ERR_BADGE_NOT_FOUND)
    (asserts! (is-none existing-badge) ERR_BADGE_ALREADY_EARNED)
    (map-set user-badges {user: user, badge-id: badge-id} {
      earned: true,
      earned-at: stacks-block-height,
      metadata: "auto-awarded"
    })
    (map-set achievement-badges badge-id (merge badge-data {total-earned: (+ (get total-earned badge-data) u1)}))
    (ok true)
  )
)

(define-public (toggle-badge-status (badge-id uint))
  (let ((badge-data (unwrap! (map-get? achievement-badges badge-id) ERR_BADGE_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set achievement-badges badge-id (merge badge-data {is-active: (not (get is-active badge-data))}))
    (ok (not (get is-active badge-data)))
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
    total-paths: (- (var-get next-path-id) u1),
    contract-balance: (var-get contract-balance),
    total-rewards-distributed: (var-get total-rewards-distributed),
    platform-fee: (var-get platform-fee-percentage)
  }
)

(define-read-only (get-learning-path (path-id uint))
  (map-get? learning-paths path-id)
)

(define-read-only (get-user-path-progress (user principal) (path-id uint))
  (map-get? user-path-progress {user: user, path-id: path-id})
)

(define-read-only (get-current-module-in-path (user principal) (path-id uint))
  (let (
    (path-data (unwrap! (map-get? learning-paths path-id) (err none)))
    (user-progress (unwrap! (map-get? user-path-progress {user: user, path-id: path-id}) (err none)))
    (current-index (get current-module-index user-progress))
    (module-sequence (get module-sequence path-data))
  )
    (ok (element-at module-sequence current-index))
  )
)

(define-read-only (get-module-review (module-id uint) (user principal))
  (map-get? module-reviews {module-id: module-id, user: user})
)

(define-read-only (get-mentor-profile (mentor principal))
  (map-get? mentors mentor)
)

(define-read-only (get-mentorship-session (session-id uint))
  (map-get? mentorship-sessions session-id)
)

(define-read-only (get-mentorship-request (mentee principal) (module-id uint))
  (map-get? mentorship-requests {mentee: mentee, module-id: module-id})
)

(define-read-only (get-mentorship-stats)
  {
    total-mentors: (var-get next-session-id),
    mentor-reward-per-session: (var-get mentor-reward-per-session),
    min-mentor-level: (var-get min-mentor-level)
  }
)

(define-read-only (get-badge (badge-id uint))
  (map-get? achievement-badges badge-id)
)

(define-read-only (get-user-badge (user principal) (badge-id uint))
  (map-get? user-badges {user: user, badge-id: badge-id})
)

(define-read-only (has-badge (user principal) (badge-id uint))
  (match (map-get? user-badges {user: user, badge-id: badge-id})
    badge-data (get earned badge-data)
    false
  )
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

(define-private (validate-module-sequence (sequence (list 10 uint)))
  (if (is-eq (len sequence) u0)
    ERR_INVALID_MODULE
    (fold validate-module-exists sequence (ok true))
  )
)

(define-private (validate-module-exists (module-id uint) (prev-result (response bool uint)))
  (match prev-result
    success (if (is-some (map-get? learning-modules module-id))
              (ok true)
              ERR_INVALID_MODULE)
    error (err error)
  )
)

(define-private (validate-specialty-modules (specialties (list 5 uint)))
  (if (is-eq (len specialties) u0)
    ERR_INVALID_MODULE
    (fold validate-module-exists specialties (ok true))
  )
)

(define-private (is-mentor-qualified (mentor principal) (module-id uint))
  (match (map-get? mentors mentor)
    mentor-data (is-some (index-of? (get specialties mentor-data) module-id))
    false
  )
)

(define-private (calculate-mentor-rating (mentor principal) (new-rating uint))
  (match (map-get? mentors mentor)
    mentor-data (let (
        (current-rating (get rating mentor-data))
        (total-sessions (get total-sessions mentor-data))
      )
      (if (is-eq total-sessions u0)
        new-rating
        (/ (+ (* current-rating total-sessions) new-rating) (+ total-sessions u1))
      )
    )
    u0
  )
)

(define-private (check-badge-requirements (badge-id uint) (badge-type uint) (requirement-value uint) (user-profile {total-modules-completed: uint, total-rewards-earned: uint, streak: uint, last-activity: uint, level: uint, experience-points: uint}))
  (if (is-eq badge-type BADGE_FIRST_MODULE)
    (>= (get total-modules-completed user-profile) u1)
    (if (is-eq badge-type BADGE_PATH_COMPLETION)
      (check-path-completion tx-sender)
      (if (is-eq badge-type BADGE_MENTOR_STATUS)
        (is-some (map-get? mentors tx-sender))
        (if (is-eq badge-type BADGE_FIVE_MODULES)
          (>= (get total-modules-completed user-profile) u5)
          (if (is-eq badge-type BADGE_PERFECT_SCORE)
            (check-perfect-score tx-sender)
            (if (is-eq badge-type BADGE_FAST_LEARNER)
              (>= (get streak user-profile) requirement-value)
              false
            )
          )
        )
      )
    )
  )
)

(define-private (check-path-completion (user principal))
  (match (map-get? user-path-progress {user: user, path-id: u1})
    progress (get completed progress)
    false
  )
)

(define-private (check-perfect-score (user principal))
  (match (map-get? user-module-progress {user: user, module-id: u1})
    progress (is-eq (get score progress) u100)
    false
  )
)
