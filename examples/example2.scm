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


; Creation of the knowledge base. Note that this function also adds some 
; records in various data tables by default.
(kb-create dbms kb1)


; Insertion of fact records. Notice that all values v for facts contained in
; sde_facts are set initially to zero, while in some cases, values for facts 
; in sde_mem_facts have different values. This is done in order to initialize 
; the "thoughts" of the expert system, while keeping some default values for 
; that will be loaded before the cycle of rule application begins.


;Insert fact.
(set! it "counter2")
(kb-insert-facts dbms kb1 tb1 co st it v p)
(kb-insert-facts dbms kb1 tb2 co st it v p)


;Insert fact.
(set! it "item-a")
(kb-insert-facts dbms kb1 tb1 co st it v p)
(kb-insert-facts dbms kb1 tb2 co st it v p)


;Insert fact.
(set! it "item-b")
(kb-insert-facts dbms kb1 tb1 co st it v p)
(kb-insert-facts dbms kb1 tb2 co st it v p)


;Insert fact.
(set! it "item-c")
(kb-insert-facts dbms kb1 tb1 co st it v p)
(kb-insert-facts dbms kb1 tb2 co st it v p)


; Insertion of rules.
(define tb1 "sde_rules")
; (define tb2 "sde_mem_rules") ; We would need this only if rules are stored as programs.
(define co "prg0_0") ; Standard context value to indicate that a rule always resides on sde_rules and not sde_meme_rules.


; Insert rule.
(define c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value = 0")
(define a "UPDATE sde_facts SET Value = 2 WHERE Status = `applykbrules` AND Item = `max-iter`")
(define d "On initial iteration, set max-iter to a specified value.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value = 0")
(define a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `counter2` ) + 1 ) WHERE Status = `applykbrules` AND Item = `counter2`")
(define d "If item-a = zero, then increment counter2.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value = 0")
(define a "UPDATE sde_facts SET Value = 1 WHERE Item = `item-a` AND Status = `applykbrules`")
(define d "If item-a = zero, then set its value to 1.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value = 1")
(define a "UPDATE sde_facts SET Value = 1 WHERE Item = `item-b` AND Status = `applykbrules`")
(define d "If item-a = 1, then set item-b value to 1.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value >= 1")
(define a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `item-c` ) * (-2) ) WHERE Item = `item-c` AND Status = `applykbrules`")
(define d "If item-a >= 1, then set item-c value to item-c * (-2).")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule.
(define c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value >= ( SELECT Value FROM sde_facts WHERE Item = `max-iter` )")
(define a "UPDATE sde_facts SET Value = 0 WHERE Item = `mode-run` AND Status = `applykbrules`")
(define d "If count1 reached the values specified for max-iter, then mode-run is set to zero in order to stop the cycle.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)




;/////////////////////
; This function will increase by ten the values of item-* items. Its goal is to 
; show how you can provide a helper function to update table sde_facts with 
; sensorial data. Of course, real functions might be far more complex than this one.
; For each step of the full reasining cycle you can create one such function to 
; deal with specific issues related to the step in question. The only condition is 
; that each such function must return the value one.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (item10 p_dbms p_kb1)
  (let ((ret 1))
    (let ((sql-sen "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts  WHERE Item LIKE 'item-%' ) + 10 ) WHERE Item LIKE 'item-%'"))
      (newline)
      (let ((db-obj (dbi-open "sqlite3" p_kb1)))
	(display sql-sen)
	(newline)
	(kb-query p_dbms p_kb1 sql-sen)
        (dbi-close db-obj)
      )
    )
    ; Return the value one.
    (* ret 1)  
  )
)    


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
(define mode-run 1)


(ptit "=" 60 2 "Example2 - A loop that repeats a full reasoning process")
(kb-setup-session dbms kb1)   
(while (= mode-run 1)
       (ptit " " 1 1 "Working... mode-run still equals one.")

       ; First get thata from any sensors you might have (i.e. peripherals)
       (kb-read-sen dbms kb1 1)

       ; Now exchange data with any modules, users, etc.
       (kb-read-mod dbms kb1 1)

       ; Now the system reads each rule contained in sde_rules and if the
       ; SQL code foun in the Condition field delivers a valid result, then  
       ; the SQL code of the Action field will be applied as is.
       (kb-think dbms kb1 1)

       ; Now data from sde_facts should be passed back to any actuators you 
       ; might have
       (kb-write-act dbms kb1 1)

       ; And finally we get the value of item mode-run and pass it to a 
       ; of the same name.
       (set! mode-run (kb-get-value-from-item dbms kb1 "sde_facts" "mode-run"))
)


; And then show all the facts and their values at the end of the loop.
(kb-display-table dbms kb1 "SELECT Item, Value FROM sde_facts" "Results of reasoning process: ")





