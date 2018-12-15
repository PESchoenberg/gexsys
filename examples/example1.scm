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
(define it "counter1")

; Creation of the knowledge base.
(kb-create dbms kb1)


; Insertion of fact records. Notice that all values v for facts contained in
; sde_facts are set initially to zero, while in some cases, values for facts 
; in sde_mem_facts have different values. This is done in order to initialize 
; the "thoughts" of the expert system, while keeping some default values for 
; that will be loaded before the cycle of rule application begins.


; Insert fact #1.
(kb-insert-facts dbms kb1 tb1 co st it v p)
(kb-insert-facts dbms kb1 tb2 co st it v p)


;Insert fact #2.
(set! it "counter2")
(kb-insert-facts dbms kb1 tb1 co st it v p)
(kb-insert-facts dbms kb1 tb2 co st it v p)


;Insert fact #3.
(set! it "mode-run")
(kb-insert-facts dbms kb1 tb1 co st it v p)
(kb-insert-facts dbms kb1 tb2 co st it 1 p) ; v = 1 to start the cycle.


;Insert fact #3.
(set! it "max-iter")
(kb-insert-facts dbms kb1 tb1 co st it v p)
(kb-insert-facts dbms kb1 tb2 co st it 5 p) ; v = 4, to set max iterations. 


;Insert fact #4.
(set! it "item-a")
(kb-insert-facts dbms kb1 tb1 co st it v p)
(kb-insert-facts dbms kb1 tb2 co st it v p)


;Insert fact #5.
(set! it "item-b")
(kb-insert-facts dbms kb1 tb1 co st it v p)
(kb-insert-facts dbms kb1 tb2 co st it v p)


;Insert fact #6.
(set! it "item-c")
(kb-insert-facts dbms kb1 tb1 co st it v p)
(kb-insert-facts dbms kb1 tb2 co st it v p)


; Insertion of rules.
(define tb1 "sde_rules")
; (define tb2 "sde_mem_rules") ; We would need this only if rules are stored as programs.
(define co "prg0_0") ; Standard context value to indicate that a rule always resides on sde_rules and not sde_meme_rules.

; Insert rule #1.
(define c "SELECT Value FROM sde_facts WHERE Item = `counter1`")
(define a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `counter1` ) + 1 ) WHERE Status = `applykbrules` AND Item = `counter1`")
(define d "Increase counter in one unit on each iteration.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


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


; Run a full cycle four times.
(kb-cycle-lim dbms kb1 4)

(newline)
(display "Okay then...")
(newline)



