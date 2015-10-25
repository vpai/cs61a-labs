;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                 ;
; Cucumber Card Game - Scheme Implementation      ;
; Rules: http://www.pagat.com/last/cucumber.html  ;
; Author: Varun Pai                               ;
; Date: 10/25/2015                                ;
;                                                 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Constants. ;;;

; Card values.
(define J 11)
(define Q 12)
(define K 13)
(define A 14)
(define ALL_VALUES (list 2 3 4 5 6 7 8 9 10 J Q K A))

; Game mechanics.
(define PLAYER_YOU 1)
(define PLAYER_OPPONENT 2)
(define LOSING_SCORE 21)

; Strategies.
(define STRATEGY_LOW `low)
(define STRATEGY_HIGH `high)
(define STRATEGY_NEXT_HIGHEST `next-highest)

; End states.
(define STATE_WIN 'win)
(define STATE_LOSS 'loss)

;;; Deck/hand functions. ;;;

; Generate a randomly ordered list of 52 cards.
(define (build-deck)
  (shuffle (reduce append (map (lambda (x) (list x x x x)) ALL_VALUES))))

; Shuffle the elements in a hand (list).
(define (shuffle deck)
  (if (< (length deck) 2)
    deck
    (let ((item (list-ref deck (random (length deck)))))
         (cons item (shuffle (remove-first item deck))))))

; Given a shuffled deck, return a pair representing 2 hands containing 7 random cards each.
(define (deal-hands deck)
  (cons
    (list
      (list-ref deck 0)
      (list-ref deck 1)
      (list-ref deck 2)
      (list-ref deck 3)
      (list-ref deck 4)
      (list-ref deck 5)
      (list-ref deck 6)
    )

    (list
      (list-ref deck 7)
      (list-ref deck 8)
      (list-ref deck 9)
      (list-ref deck 10)
      (list-ref deck 11)
      (list-ref deck 12)
      (list-ref deck 13)
    )
  )
)

;;; Game functions. ;;;

; Choose a card to play from the hand given the current max and your strategy.
(define (choose-card hand current_max strategy)
  (cond ((equal? strategy STRATEGY_LOW) (pick-lowest hand))
        ((equal? strategy STRATEGY_HIGH) (pick-highest hand current_max))
        ((equal? strategy STRATEGY_NEXT_HIGHEST) (pick-next-highest hand current_max))))

; Play one hand of cucumber. Return a pair of penalties for this hand,
; where one element of the pair is always 0.
(define (play-round your_strategy opponent_strategy player_to_start)
  (let ((hands (deal-hands (build-deck))))
    (let ((your_hand (car hands)) (opponent_hand (cdr hands)))
         (play-round-helper your_hand opponent_hand your_strategy opponent_strategy 0 nil player_to_start))))

; Helper function to store state as a hand is being played.
(define (play-round-helper your_hand opponent_hand your_strategy opponent_strategy current_max current_loser current_player)
  (cond
        ; Hand over if both you and your opponent have only 1 card left.
        ((and (= (length your_hand) 1) (= (length opponent_hand) 1))
          (if (= current_loser PLAYER_YOU)
              (cons current_max 0)
              (cons 0 current_max)))

        ; Play a card if it's your turn.
        ((= current_player PLAYER_YOU)
          (let ((card_played (choose-card your_hand current_max your_strategy)))
               (play-round-helper (remove-first card_played your_hand) ; Remove card played from your hand.
                                  opponent_hand
                                  your_strategy
                                  opponent_strategy
                                  (if (>= card_played current_max) card_played current_max)
                                  (if (>= card_played current_max) PLAYER_YOU PLAYER_OPPONENT)
                                  PLAYER_OPPONENT)))

        ; Let you opponent play a card on their turn.
        ((= current_player PLAYER_OPPONENT)
          (let ((card_played (choose-card opponent_hand current_max opponent_strategy)))
               (play-round-helper your_hand
                                  (remove-first card_played opponent_hand) ; Remove card played from opponent's hand.
                                  your_strategy
                                  opponent_strategy
                                  (if (>= card_played current_max) card_played current_max)
                                  (if (>= card_played current_max) PLAYER_OPPONENT PLAYER_YOU)
                                  PLAYER_YOU))))
)

; Play one full round of cucumber. Randomly choose the starting player
; and halt play once one player reaches the losing score. Return a symbol
; indicating whether you (player 1) won or lost the game.
(define (cucumber your_strategy opponent_strategy)
  (begin
    (define (cucumber-helper your_score opponent_score player_to_start)
      (cond ((>= your_score LOSING_SCORE) STATE_LOSS)
            ((>= opponent_score LOSING_SCORE) STATE_WIN)
            (else (let ((scores_this_round (play-round your_strategy opponent_strategy player_to_start)))
                       (let ((your_points_this_round (car scores_this_round)) (opponent_points_this_round (cdr scores_this_round)))
                            (cucumber-helper (+ your_score your_points_this_round)
                                             (+ opponent_score opponent_points_this_round)
                                             (if (> your_points_this_round opponent_points_this_round) PLAYER_YOU PLAYER_OPPONENT)))))))
    (cucumber-helper 0 0 (if (= (random 2) 0) PLAYER_YOU PLAYER_OPPONENT))
  )
)

;;; Testing functions. ;;;

(define (play-cucumber-n-times n strategy1 strategy2 wins losses)
  (if (= n 0)
      (cons wins losses)
      (let
        ((result (cucumber strategy1 strategy2)))
        (if (equal? result STATE_WIN)
          (play-cucumber-n-times (- n 1) strategy1 strategy2 (+ 1 wins) losses)
          (play-cucumber-n-times (- n 1) strategy1 strategy2 wins (+ 1 losses))))))

(define (play-cucumber)
  (begin
    (display (play-cucumber-n-times 1000 STRATEGY_HIGH STRATEGY_LOW 0 0))
    (display (play-cucumber-n-times 1000 STRATEGY_HIGH STRATEGY_HIGH 0 0))
    (display (play-cucumber-n-times 1000 STRATEGY_HIGH STRATEGY_NEXT_HIGHEST 0 0))
    (display (play-cucumber-n-times 1000 STRATEGY_LOW STRATEGY_LOW 0 0))
    (display (play-cucumber-n-times 1000 STRATEGY_LOW STRATEGY_HIGH 0 0))
    (display (play-cucumber-n-times 1000 STRATEGY_LOW STRATEGY_NEXT_HIGHEST 0 0))
    (display (play-cucumber-n-times 1000 STRATEGY_NEXT_HIGHEST STRATEGY_LOW 0 0))
    (display (play-cucumber-n-times 1000 STRATEGY_NEXT_HIGHEST STRATEGY_HIGH 0 0))
    (display (play-cucumber-n-times 1000 STRATEGY_NEXT_HIGHEST STRATEGY_NEXT_HIGHEST 0 0))))

;;; Helper functions. ;;;

; Remove the first instance of the item from the list.
(define (remove-first item lst)
  (cond ((null? lst) '())
        ((equal? item (car lst)) (cdr lst))
        (else (cons (car lst) (remove-first item (cdr lst))))))

;;; Strategies. ;;;

; Play your lowest card.
(define (pick-lowest hand)
  (apply min hand)
)

; Play the highest card you are able to.
;  1) If the highest card you have is >= the current maximum, play it.
;  2) Otherwise, play your lowest card.
(define (pick-highest hand current_max)
  (let ((max_in_hand (apply max hand)))
    (if (>= max_in_hand current_max)
        max_in_hand
        (pick-lowest hand))))

; Play the lowest card you are able to that is >= to the current max.
(define (pick-next-highest hand current_max)
  (define (pick-next-helper value_to_check)
    (cond ((> value_to_check A) (pick-lowest hand))
          ((not (eq? (member value_to_check hand) #f)) value_to_check)
          (else (helper (+ value_to_check 1))))
  )
  (pick-next-helper current_max)
)
