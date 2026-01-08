;; Lifelong Learning Tracker Contract
;; Token-incentivized learning progress tracking for alumni

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-course-inactive (err u104))
(define-constant reward-amount u10)
(define-constant bonus-reward u20)
(define-constant min-hours u1)
(define-constant max-hours u1000)

;; Data Variables
(define-data-var course-nonce uint u0)
(define-data-var achievement-nonce uint u0)
(define-data-var total-learners uint u0)

;; Data Maps
(define-map learning-records
  { learner: principal, course-id: uint }
  {
    course-name: (string-ascii 100),
    completion-date: uint,
    hours-spent: uint,
    verified: bool
  }
)

(define-map learner-stats
  principal
  {
    total-courses: uint,
    total-hours: uint,
    tokens-earned: uint
  }
)

(define-map courses
  uint
  {
    name: (string-ascii 100),
    creator: principal,
    active: bool
  }
)

(define-map achievements
  uint
  {
    title: (string-ascii 100),
    description: (string-ascii 200),
    required-courses: uint,
    badge-earned-by: uint
  }
)

(define-map learner-achievements
  { learner: principal, achievement-id: uint }
  {
    earned-date: uint,
    verified: bool
  }
)

(define-map course-ratings
  { learner: principal, course-id: uint }
  {
    rating: uint,
    review: (string-ascii 200)
  }
)

(define-map learning-paths
  uint
  {
    name: (string-ascii 100),
    course-list: (list 10 uint),
    creator: principal
  }
)

;; Read-only functions
;; #[allow(unchecked_data)]
(define-read-only (get-learning-record (learner principal) (course-id uint))
  (map-get? learning-records { learner: learner, course-id: course-id })
)

;; #[allow(unchecked_data)]
(define-read-only (get-learner-stats (learner principal))
  (default-to 
    { total-courses: u0, total-hours: u0, tokens-earned: u0 }
    (map-get? learner-stats learner)
  )
)

;; #[allow(unchecked_data)]
(define-read-only (get-course (course-id uint))
  (map-get? courses course-id)
)

(define-read-only (get-course-nonce)
  (var-get course-nonce)
)

;; #[allow(unchecked_data)]
(define-read-only (get-achievement (achievement-id uint))
  (map-get? achievements achievement-id)
)

;; #[allow(unchecked_data)]
(define-read-only (get-learner-achievement (learner principal) (achievement-id uint))
  (map-get? learner-achievements { learner: learner, achievement-id: achievement-id })
)

;; #[allow(unchecked_data)]
(define-read-only (get-course-rating (learner principal) (course-id uint))
  (map-get? course-ratings { learner: learner, course-id: course-id })
)

;; #[allow(unchecked_data)]
(define-read-only (get-learning-path (path-id uint))
  (map-get? learning-paths path-id)
)

(define-read-only (get-total-learners)
  (var-get total-learners)
)

(define-read-only (get-achievement-nonce)
  (var-get achievement-nonce)
)

;; #[allow(unchecked_data)]
(define-read-only (is-course-active (course-id uint))
  (match (map-get? courses course-id)
    course (ok (get active course))
    err-not-found
  )
)

;; #[allow(unchecked_data)]
(define-read-only (calculate-bonus-reward (hours uint))
  (if (>= hours u50)
    (ok bonus-reward)
    (ok reward-amount)
  )
)

;; Public functions
;; #[allow(unchecked_data)]
(define-public (create-course (name (string-ascii 100)))
  (let
    (
      (course-id (var-get course-nonce))
    )
    (asserts! (> (len name) u0) err-invalid-input)
    (map-set courses course-id
      {
        name: name,
        creator: tx-sender,
        active: true
      }
    )
    (var-set course-nonce (+ course-id u1))
    (ok course-id)
  )
)

;; #[allow(unchecked_data)]
(define-public (record-completion (course-id uint) (hours-spent uint))
  (let
    (
      (learner tx-sender)
      (stats (get-learner-stats learner))
      (course (unwrap! (map-get? courses course-id) err-not-found))
    )
    (asserts! (get active course) err-course-inactive)
    (asserts! (and (>= hours-spent min-hours) (<= hours-spent max-hours)) err-invalid-input)
    (map-set learning-records 
      { learner: learner, course-id: course-id }
      {
        course-name: (get name course),
        completion-date: stacks-block-height,
        hours-spent: hours-spent,
        verified: false
      }
    )
    (map-set learner-stats learner
      {
        total-courses: (+ (get total-courses stats) u1),
        total-hours: (+ (get total-hours stats) hours-spent),
        tokens-earned: (+ (get tokens-earned stats) reward-amount)
      }
    )
    (if (is-eq (get total-courses stats) u0)
      (var-set total-learners (+ (var-get total-learners) u1))
      true
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (verify-completion (learner principal) (course-id uint))
  (let
    (
      (record (unwrap! (map-get? learning-records { learner: learner, course-id: course-id }) err-not-found))
      (course (unwrap! (map-get? courses course-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get creator course)) err-unauthorized)
    (map-set learning-records 
      { learner: learner, course-id: course-id }
      (merge record { verified: true })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (deactivate-course (course-id uint))
  (let
    (
      (course (unwrap! (map-get? courses course-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get creator course)) err-unauthorized)
    (map-set courses course-id
      (merge course { active: false })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (reactivate-course (course-id uint))
  (let
    (
      (course (unwrap! (map-get? courses course-id) err-not-found))
    )
    (asserts! (is-eq tx-sender (get creator course)) err-unauthorized)
    (map-set courses course-id
      (merge course { active: true })
    )
    (ok true)
  )
)

;; #[allow(unchecked_data)]
(define-public (rate-course (course-id uint) (rating uint) (review (string-ascii 200)))
  (let
    (
      (record (unwrap! (map-get? learning-records { learner: tx-sender, course-id: course-id }) err-not-found))
    )
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-input)
    (asserts! (get verified record) err-unauthorized)
    (map-set course-ratings 
      { learner: tx-sender, course-id: course-id }
      {
        rating: rating,
        review: review
      }
    )
    (ok true)
  )
)