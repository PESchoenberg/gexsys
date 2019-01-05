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
(use-modules (grsp grsp0))
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
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value = 0;")
(define a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `counter2` ) + 1 ) WHERE Status = `applykbrules` AND Item = `counter2`;")
(define d "2- If item-a = zero, then increment counter2.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule #3.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value = 0;")
(define a "UPDATE sde_facts SET Value = 1 WHERE Item = `item-a` AND Status = `applykbrules`;")
(define d "3- If item-a = zero, then set its value to 1.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule #4.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value = 1;")
(define a "UPDATE sde_facts SET Value = 1 WHERE Item = `item-b` AND Status = `applykbrules`;")
(define d "4- If item-a = 1, then set item-b value to 1.")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule #5.
(define c "SELECT Value FROM sde_facts WHERE Item = `item-a` AND Value >= 1;")
(define a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `item-c` ) * (-2) ) WHERE Item = `item-c` AND Status = `applykbrules`;")
(define d "5- If item-a >= 1, then set item-c value to item-c * (-2).")
(kb-insert-rules dbms kb1 tb1 co st c a d p)


; Insert rule #6.
(define c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value >= ( SELECT Value FROM sde_facts WHERE Item = `max-iter` );")
(define a "UPDATE sde_facts SET Value = 0 WHERE Item = `mode-run` AND Status = `applykbrules`;")
(define d "6- If count1 reached the values specified for max-iter, then mode-run is set to zero in order to stop the cycle.")
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
    (let ((sql-sen "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts  WHERE Item LIKE 'item-%' ) + 10 ) WHERE Item LIKE 'item-%';"))
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


; These steps constitute a full reasoning iteration. If you loop them, you
; can obtain several different variants of reasoning processes. You may need
; to create functions to replace the last parameter p_f1 by function calls
; like in the case of kb-read-sen in order to get meaningful results on
; each step.
;
; Gexsys is essentially the Scheme version of an expert system designed for  
; a semi - autonomous spacecraft. That system - called exsys - runs on an 
; unique thread, separated from other processes In this thread, exsys works 
; on a continupus loop in which several things take place:
;
; 1 - Data is gathered from the onboard sensors and stored into sde_facts; this  
; is what function kb-read-sen does. i.e. current speed, current altitude 					;
; as measured from a reference celestial body.

; 2 - Then, data coming from modules related to the user interface - human or 
; machine are gathered and stored in sde_facts, on specific fact records, such as 
; target or desired speed, target altitude, etc. with respect to a reference 
; body that is usually the same as in paraghraph 1. This is achieved via 
; external modules and then, kb-read-mode finishes the process by changing the
; Status flag on the recently-added item values.
;
; 3 - Then, rules are checked and executed if applicable. for example, once the 
; kb has received a different value for target speed with respect to the current 
; speed, rules concerning reference celestial bodies and thrust maneuvering 
; might come into action in order to achieve the desired goals. This is the job 
; of function kb-think, which reads the Condition field of each rule, sees if 
; its conditions are applicable, and if so, then reads the Action field and 
; executes it. This meas that values of items that correspond to actuators 
; will be updated so that in the next step, data will be send to them and
; processes such as maneuvers will be performed. kb-think does not actually 
; actuate the decisions taken, it just passes the relevant parameters to the 
; data items that will be passed to the actuators.

; 4 - Finally. kb-write-act passes the data to the actuators. In the case of
; Gexsys, little is done at this stage, but nevertheless, the function updates				      
; the status of the kb.
;
; You may not need to perform all those steps, depending on the architecture of
; your particular system, or you may have to add additional ones, but now you
; know where does this particular architecture comes from.
;
; Also, notice that Gexsys uses SQL statement both as data stored in the kb and
; as program instructions. That is, data and and program statements are 
; essentially the same thing, and as data can be modified on the fly, this 
; means that you can add, delete or even modify the rules of your system while 
; it is running, or the system can modify them by itself.
;
(ptit "=" 60 2 "Example1 - One single iteration of a full reasoning process.")
(kb-setup-session dbms kb1)
(kb-read-sen dbms kb1 (item10 dbms kb1))
(kb-read-mod dbms kb1 1)
(kb-think dbms kb1 1)
(kb-write-act dbms kb1 1)


; And then show all the columns or fields of sde_facts.
(kb-display-table dbms kb1 "SELECT * FROM sde_facts" "q")


; Or we can see only some selected data.
(kb-display-table dbms kb1 "SELECT Item, Value FROM sde_facts" "q")


