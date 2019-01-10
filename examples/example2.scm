#! /usr/local/bin/guile -s
!#


; ==============================================================================
;
; example2.scm
;
; This program shows the use of a continuous-loop expert system.
;
; Compilation:
;
; - cd to your /examples folder.
;
; - At the terminal, enter the following:
;
;   guile example2.scm 
;
; ==============================================================================
;
; Copyright (C) 2018  Pablo Edronkin (pablo.edronkin at yahoo.com)
;
;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU Lesser General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;   This program is distributed in the hope that it will be useful,
;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;   GNU Lesser General Public License for more details.
;
;   You should have received a copy of the GNU Lesser General Public License
;   along with this program.  If not, see <https://www.gnu.org/licenses/>.
;
; ==============================================================================


(use-modules (dbi dbi))
(use-modules (grsp grsp0))
(use-modules (gexsys gexsys0))


; Welcome.
(ptit "=" 60 2 "Example2 - A loop that repeats a full reasoning process")


; Vars and initial stuff.
(define dbms "sqlite3")
(define kb1 "example2.db")
(define co "prg0_0")
(define st "enabled")
(define v 0.0)
(define p 1.0)
(define tb1 "sde_facts")
(define tb2 "sde_mem_facts")
(define it " ")
(define f3 2)
(define i 0)

; Creation of the knowledge base. Note that this function also adds some 
; records in various data tables by default.
(kb-create dbms kb1 f3)


; Insertion of fact records. Notice that all values v for facts contained in
; sde_facts are set initially to zero, while in some cases, values for facts 
; in sde_mem_facts have different values. This is done in order to initialize 
; the "thoughts" of the expert system, while keeping some default values for 
; that will be loaded before the cycle of rule application begins.


;Insert fact.
(set! it "counter2")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it v p f3)


;Insert fact.
(set! it "item-a")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it v p f3)


;Insert fact.
(set! it "item-b")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it v p f3)


;Insert fact.
(set! it "item-c")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it v p f3)


; Insertion of rules.
(define tb3 "sde_rules")
; (define tb2 "sde_mem_rules") ; We would need this only if rules are stored as programs.
(define co "prg0_0") ; Standard context value to indicate that a rule always resides on sde_rules and not sde_meme_rules.


; Insert rule.
(define c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value = 0")
(define a "UPDATE sde_facts SET Value = 1 WHERE Status = `applykbrules` AND Item = `max-iter`")
(define d "1- On a certain value for counter1, set max-iter to a specified value.")
(kb-insert-rules dbms kb1 tb3 co st c a d p f3)


; Insert rule.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value = 0")
(define a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `counter2` ) + 1 ) WHERE Status = `applykbrules` AND Item = `counter2`")
(define d "2- If item-a = zero, then increment counter2.")
(kb-insert-rules dbms kb1 tb3 co st c a d p f3)


; Insert rule.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value = 1")
(define a "UPDATE sde_facts SET Value = 1 WHERE Item = `item-b` AND Status = `applykbrules`")
(define d "3- If item-a = 1, then set item-b value to 1.")
(kb-insert-rules dbms kb1 tb3 co st c a d p f3)


; Insert rule.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value >= 1")
(define a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `item-c` ) * (-2) ) WHERE Item = `item-c` AND Status = `applykbrules`")
(define d "4- If item-a >= 1, then set item-c value to item-c * (-2).")
(kb-insert-rules dbms kb1 tb3 co st c a d p f3)


; Insert rule.
(define c "SELECT Value FROM sde_facts WHERE Item = `counter2` AND Value > 2")
(define a "UPDATE sde_facts SET Value = 0 WHERE Item = `mode-run` AND Status = `applykbrules`")
(define d "5- Set mode-run = 0 if counter2 reaches a certain value.")
(kb-insert-rules dbms kb1 tb3 co st c a d p f3)


; MAIN PROGRAM ----------------------------------------------------------------


; Here we will run a loop with the same functions used on example1.scm, but
; with slightly different runes letting full control to the kb. The system
; assigns value 1 to fact mode-run, then that fact value passed from the kb 
; to a variable named mode-run on the program, and that finally stops
; the loop and finishes the program. Consider that a change in mode-run depends 
; entirely on a decision made by the system
;
; Please see the notes for example1.scm for additional information on the 
; rationale for each step and function in a complete reasoning cycle.
;
; Notce that in this example we can work with two nested loops: one defined
; by item max-iter, like in example1.scm, and another one that depends on the 
; value of certain items - counter2 in this case.
;
; If you take a look at the rules for this example program you will see that 
; like in the case of example1.scm, there is one that sets a value for max-iter 
; but there is also a rule that establishes that the "outer" loop that defines 
; the full reasoning cycle depends on the value of variable mode-run 
; as extracted from item mode-run (see below).
;
; You can define rules that modify the value of item mode-run and consequently, 
; variable mode-run, as you desire. For example, the system may continue its 
; reasoning cycles until a sensor detects something, passes a value to the kb 
; and then the rules determine that mode-run now equals zero. You can of course 
; extract any number of values coming from any number of item records at any 
; time, like it is done here with mode-run.
;
; This is of course, a fairly trivial example that only shows how things may 
; interact, but fairly complex reasoning systems can be built in this way. We 
; will leave that for other example programs.
;
; I have named Scheme variables that extract values from the kb using function 
; kb-get-value-from-item exaclty the same as the items from sde_facts from which
; they extract the value - i.e. a Scheme variable mode-run for example would 
; extract the value of item mode-run contained in sde_facts, or a scheme 
; variable counter1 would extract the value from item counter1. You can of 
; of course use different names but in my opinion it is better to use the same
; names because once you star extracting lots of values from items, it might 
; get confusing if the Scheme variables are named otherwise.
;
(define mode-run 1)


(kb-setup-session dbms kb1 f3)
(while (= mode-run 1)

       ; This informs you about the iteration number. Can be useful.
       (set! i (+ i 1))
       (pline "+" 60)
       (pres "Iteration" (number->string i))
       
       ; First get data from any sensors you might have (i.e. peripherals)
       (kb-read-sen dbms kb1 1 f3)

       ; Now exchange data with any modules, users, etc.
       (kb-read-mod dbms kb1 1 f3)

       ; Now the system reads each rule contained in sde_rules and if the
       ; SQL code foun in the Condition field delivers a valid result, then  
       ; the SQL code of the Action field will be applied as is.
       (kb-think dbms kb1 1 f3)

       ; Now data from sde_facts should be passed back to any actuators you 
       ; might have
       (kb-write-act dbms kb1 1 f3)

       ; And finally we get the value of item mode-run and pass it to a 
       ; of the same name.
       (set! mode-run (kb-get-value-from-item dbms kb1 "sde_facts" "mode-run"))
)


; And then show all the facts and their values at the end of the loop.
(kb-display-table dbms kb1 "SELECT Item, Value FROM sde_facts" "Results of reasoning process: ")
(newlines 3)






