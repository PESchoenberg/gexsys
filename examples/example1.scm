#! /usr/local/bin/guile -s
!#


; ==============================================================================
;
; example1.scm
;
; This program does nothing particular except showing different functions of
; gexsys.
;
; Compilation:
;
; - cd to your /examples folder.
;
; - At the terminal, enter the following:
;
;   guile example1.scm 
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
(use-modules (gexsys gexsys0))


; Vars and initial stuff.
(define dbms "sqlite3")
(define kb1 "example1.db")
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


; Insert rule #2.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value = 0")
(define a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `counter2` ) + 1 ) WHERE Status = `applykbrules` AND Item = `counter2`")
(define d "If item-a = zero, then increment counter2.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule #3.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value = 0")
(define a "UPDATE sde_facts SET Value = 1 WHERE Item = `item-a` AND Status = `applykbrules`")
(define d "If item-a = zero, then set its value to 1.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule #4.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value = 1")
(define a "UPDATE sde_facts SET Value = 1 WHERE Item = `item-b` AND Status = `applykbrules`")
(define d "If item-a = 1, then set item-b value to 1.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule #5.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value >= 1")
(define a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `item-c` ) * (-2) ) WHERE Item = `item-c` AND Status = `applykbrules`")
(define d "If item-a >= 1, then set item-c value to item-c * (-2).")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule #6.
(define c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value >= ( SELECT Value FROM sde_facts WHERE Item = `max-iter` )")
(define a "UPDATE sde_facts SET Value = 0 WHERE Item = `mode-run` AND Status = `applykbrules`")
(define d "If count1 reached the values specified for max-iter, then mode-run is set to zero in order to stop the cycle.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


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


; Start with a heading.
(newline)
(display "------------------------------------------------------------")
(newline)
(display "Example of a full reasoning iteration.")
(newline)


; These steps constitute a full reasoning iteration. If you loop them, you
; can obtain several different variants of reasoning processes. 
(kb-read-sen dbms kb1 (item10 dbms kb1))
(kb-read-mod dbms kb1 1)
(kb-think dbms kb1 1)
(kb-write-act dbms kb1 1)


; And then finish with a message.
(newline)
(display "Okay then...")
(newline)




