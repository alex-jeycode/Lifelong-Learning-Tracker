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