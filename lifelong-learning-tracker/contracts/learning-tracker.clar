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