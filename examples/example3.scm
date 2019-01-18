#! /usr/local/bin/guile -s
!#


; ==============================================================================
;
; example3.scm
;
; This program creates a knowledge base that will be used by other independent
; programs for AI planning purposes. Its sole goal is to create the KB and fill
; it with the required facts and rules. Then it will present the results of
; the knowledge base creation process.
;
; Compilation:
;
; - cd to your /examples folder.
;
; - At the terminal, enter the following:
;
;   guile example3.scm 
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
(ptit "=" 60 2 "Example3 - Creation of a stand alone knowledge base.")


; Vars and initial stuff.
(define dbms "sqlite3")
(define kb1 "example3.db")
(define co "prg0.1")
(define st "enabled")
(define v 0.0)
(define p 1.0)
(define tb1 "sde_facts")
(define tb2 "sde_mem_facts")
(define it " ")
(define f3 1)


; Creation
(kb-create dbms kb1 f3)


;Insert fact.
(set! it "counter2")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it v p f3)


;Insert fact.
(set! it "leg-cost")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it v p f3)


;Insert fact.
(set! it "total-cost")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it v p f3)


;Insert fact.
(set! it "leg-desc")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it v p f3)


;Insert fact.
(set! it "plan-desc")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it v p f3)





; Now we will inser some facts that will describe the following graph:
;
; a ---- b ---- c
; |      |
; d ---- e
;
; The cost of reaching une pont from another will be:
;
; cost-pa-pb: 10
; cost-pa-pd: 5
; cost-pd-pe: 2
; cost-pe-pb: 2 
; cost-pb-pc: 10
; 
; And will be passed to the kb as:


;Insert fact.
(set! it "cost-pa-pb")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it 10 p f3)


;Insert fact.
(set! it "cost-pa-pd")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it 5 p f3)


;Insert fact.
(set! it "cost-pd-pe")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it 2 p f3)


;Insert fact.
(set! it "cost-pe-pb")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it 2 p f3)


;Insert fact.
(set! it "cost-pb-pc")
(kb-insert-facts dbms kb1 tb1 co st it v p f3)
(kb-insert-facts dbms kb1 tb2 co st it 10 p f3)


; Insertion of rules. Notice on the description of the first rule to be
; inserted that it is identified with a number higher than one. This is
; due to the fact that during the creation of table sde_rules, a number 
; of default rules are included, including those that set fact counter1
; increasing on every cycle.


; Required to pass rules resident on sde_rules.
(define tb3 "sde_rules")


; We would need this only if rules are stored as programs.
(define tb4 "sde_mem_rules")


; Standard context value to indicate that a rule always resides on sde_rules
; and not sde_meme_rules.
(define co "prg0.1") 


; Insert rule.
(define c "SELECT Value FROM sde_facts WHERE Item = `counter2` AND Value > 2")
(define a "UPDATE sde_facts SET Value = 0 WHERE Item = `mode-run` AND Status = `applykbrules`")
(define d "4- Set mode-run = 0 if counter2 reaches a certain value.")
(kb-insert-rules dbms kb1 tb3 co st c a d p f3)


; Display results. while they may not appear in the best format possible
; it is yet a good idea to check the daya that has been inserted.
(kb-display-table dbms kb1 "SELECT * FROM sde_facts" "example3.db - Contents of new sde_facts")
(kb-display-table dbms kb1 "SELECT * FROM sde_mem_facts" "example3.db - Contents of new sde_mem_facts")
(kb-display-table dbms kb1 "SELECT * FROM sde_rules" "example3.db - Contents of new sde_rules")


; In order to use this kb, please see example4.scm.



