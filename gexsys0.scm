; ==============================================================================
;
; gexsys0.scm
;
; Guile Expert System.
;
; Sources: 
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


; Required modules.
(use-modules (dbi dbi))


(define-module (gexsys gexsys0)
  #:export (;apply-rule
	    ;apply-rules
	    ;create
	    ;create-edges
	    ;create-facts
	    ;create-mem-facts
	    ;create-prg-rules
	    create-rules
	    ;df2dt
	    ;get-query
	    ;list-tables
	    ;send-query
	    ;trans-table))


; create - creates a knowledge base.

; This function creates table sde_rules within knowledge base p_kb. Its is to
; store the working if-then rules or productions that will be used by the
; inference engine. A working rule is one that is being currently used during
; a deductive process. Rules that are not currently  in use should be stored
; in table sde_prg_rules and only be loaded unto sde_rules on demand in order
; to free resources and lessen the workload of the system. Having too many
; rules on sde_rules might slow down the inference engine. Nested JOIN
; operations are among the kind of rules that can consume considerable
; resources during execution. This function will overwrite any prior instance
; of the table it creates in p_kb if the knowledge base is located in the same
; working directory where you intend to use the function.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (create-rules p_dbms p_kb1)
  (let ((db-obj (dbi-open p_dbms p_kb1)))
    (dbi-query db-obj "DROP TABLE IF EXISTS sde_rules;")
    (dbi-query db-obj "CREATE TABLE sde_rules (
              Id          INTEGER PRIMARY KEY ASC ON CONFLICT ROLLBACK AUTOINCREMENT UNIQUE ON CONFLICT ROLLBACK,
              Context     TEXT    DEFAULT main,
              Status      TEXT    DEFAULT enabled,
              Condition   TEXT    DEFAULT na,
              [Action]    TEXT    DEFAULT na,
              Description TEXT    DEFAULT na,
              Prob        REAL    CONSTRAINT prob_def_val DEFAULT (1) CONSTRAINT prob_bet_0_1 CHECK (Prob >= 0 AND Prob <= 1) );
              ")
    (dbi-close db-obj)))
    


