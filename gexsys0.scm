; ==============================================================================
;
; gexsys0.scm
;
; A simple expert system based on GNU Guile and relational databases.
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


(define-module (gexsys gexsys0)
  #:use-module (dbi dbi)
  #:export (kb-create
	    kb-create-sde-edges
	    kb-create-sde-facts
	    kb-create-sde-mem-facts
	    kb-create-sde-prg-rules
	    kb-create-sde-rules
	    kb-query
	    kb-insert-facts
	    kb-insert-rules
	    kb-setup-session
	    kb-read-sen
	    kb-read-mod
	    kb-think
	    kb-write-act
	    kb-cycle-lim
	    kb-reas-iter
	    kb-setup-session-wr
	    kb-comp-iter p_dbms))


; kb-create  - creates knowledge base.
;
; This function creates knowledge base p_kb. While SQLite allows the
; creation of empty databases Rkb1 defines upon creation of a knowledge base
; some tables required for the AI engine so you will see that some tables
; will be created as part of p_kb by using this function. While you may have
; to add data to these tables - facts, rules, etc - do not edit their
; structure (i.e change the names of columns or delete some of them, for
; example). You may also need to create additional tables by:
;
; - Importing one or more datasets in data frame format using function
; kb-df2db.
; - Creating tables using "CREATE TABLE..." SQL statements and later import
; your data.
; - In some cases in which you will buld a system that does not use data sets
; to be processed in batch, you may use just the provided data tables.
;
; or both after using rkbCreate(...). The knowledge base will be created on
; your current work directory or folder. This function will overwrite any prior
; instance of p_kb1 and its tables located in the same working directory where
; you intend to use the function again. If you intend to use kb-create on an
; existing knowledge base, back it up first.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-create p_dbms p_kb1)
  (kb-create-sde-edges p_dbms p_kb1)
  (kb-create-sde-facts p_dbms p_kb1)
  (kb-create-sde-mem-facts p_dbms p_kb1)
  (kb-create-sde-prg-rules p_dbms p_kb1)
  (kb-create-sde-rules p_dbms p_kb1)
)


; kb-create-sde-edges - creates table sde_edges.
;
; This function creates table sde_edges within knowledge base p_kb1; sde_edges
; is might be useful for defining network relationships if you want to use an
; approximation to a graph paradigm on top of the relational model used by
; SQLite. While not covering all aspects of network databases, this function
; serves its purpose as proof of concept to build one on top of a relational
; system. In theory almost any database model could be build on top of a
; relational one, albeit it would not necessarily in the most efficient
; fashion. This function will overwrite any prior instance of the table it
; creates in p_kb1 if the knowledge base is located in the same working
; directory where you intend to use the function.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-create-sde-edges p_dbms p_kb1)
  (let ((db-obj (dbi-open p_dbms p_kb1)))
    (dbi-query db-obj "DROP TABLE IF EXISTS sde_edges;")
    (dbi-query db-obj "CREATE TABLE sde_edges (
                         Id       INTEGER PRIMARY KEY ASC ON CONFLICT ROLLBACK AUTOINCREMENT UNIQUE ON CONFLICT ROLLBACK,
                         Context  TEXT    DEFAULT na,
                         Status   TEXT    DEFAULT na,
                         Item     TEXT    DEFAULT na UNIQUE ON CONFLICT ROLLBACK,
                         Value    REAL    DEFAULT (0),
                         Prob     REAL    DEFAULT (1) CONSTRAINT prob_bet_0_1 CHECK (Prob >= 0 AND Prob <= 1),
                         Fkbnode  TEXT    DEFAULT na,
                         Ftbnode  TEXT    DEFAULT na,
                         Frcnode  TEXT    DEFAULT na,
                         Tkbnode  TEXT    DEFAULT na,
                         Ttbnode  TEXT    DEFAULT na,
                         Trcnode  TEXT    DEFAULT na,
                         Property TEXT    DEFAULT na);
                         ")
    (dbi-close db-obj)
  )
)


; kb-create-sde-facts - creates table sde_facts.
;
; This function creates table sde_facts within knowledge base p_kb. A facts
; table holds session data about your rule based system such as counters,
; parameters and variables used by the inference engine with any desired
; degree of detail. Facts contained within sde_facts table are represented by
; key - value tuples represented by field or columnar names 'Item' and
; 'Value', being the first a string and the second a number that represent
; each fact. There are other fields per record, containing additional process
; data. Default and start up values should be stored in table sde_mem_facts.
; This function will overwrite any prior instance of the table it creates in
; p_kb1 if the knowledge base is located in the same working directory where
; you intend to use the function.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-create-sde-facts p_dbms p_kb1)
  (let ((db-obj (dbi-open p_dbms p_kb1)))
    (dbi-query db-obj "DROP TABLE IF EXISTS sde_facts;")
    (dbi-query db-obj "CREATE TABLE sde_facts (
              Id      INTEGER PRIMARY KEY ASC ON CONFLICT ROLLBACK AUTOINCREMENT UNIQUE ON CONFLICT ROLLBACK,
              Context TEXT    DEFAULT main,
              Status  TEXT    DEFAULT dbtoact,
              Item    TEXT    DEFAULT na CONSTRAINT item_unique UNIQUE ON CONFLICT ROLLBACK,
              Value   REAL    DEFAULT (0),
              Prob    REAL    DEFAULT (1) CONSTRAINT prob_bet_0_1 CHECK (Prob >= 0 AND Prob <= 1) );
              ")
    (dbi-close db-obj)
  )
)


; kb-create-sde-mem-facts - creates table sde_mem_facts.
;
; This function creates table sde_mem_facts within knowledge base p_kb1. Such
; a table could be used to hold factual data (from sde_facts) that you might
; use as default for future sessions or whenever you need to reset your
; system. This function will overwrite any prior instance of the table it
; creates in p_kb1 if the knowledge base is located in the same working
; directory where you intend to use the function.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-create-sde-mem-facts p_dbms p_kb1)
  (let ((db-obj (dbi-open p_dbms p_kb1)))
    (dbi-query db-obj "DROP TABLE IF EXISTS sde_mem_facts;")
    (dbi-query db-obj "CREATE TABLE sde_mem_facts (
              Id      INTEGER PRIMARY KEY ASC ON CONFLICT ROLLBACK AUTOINCREMENT UNIQUE ON CONFLICT ROLLBACK,
              Context TEXT    DEFAULT main,
              Status  TEXT    DEFAULT dbtoact,
              Item    TEXT    DEFAULT na CONSTRAINT item_unique UNIQUE ON CONFLICT ROLLBACK,
              Value   REAL    DEFAULT (0),
              Prob    REAL    DEFAULT (1) CONSTRAINT prob_bet_0_1 CHECK (Prob >= 0 AND Prob <= 1) );
              ")
    (dbi-close db-obj)
  )
)


; kb-create-sde-prg-rules - creates table sde_prg_rules.
;
; This function creates table sde_prg_rules within p_kb. This table is similar
; to sde_rules but its purpose is to store rules that might not be used by the
; inference engine at a specific time, thus freeing as much resources as
; possible. Rules can be grouped together by assigning them a similar Context
; value. These sets of rules can be stored as 'programs' in sde_prg_rules and
; can be called into sde_rules whenever they are needed. Generally speaking,
; it is better to keep on sde_rules as few as possible rules as possible
; during execution. Every rule should be called from sde_mem_rules into
; sde_rules only when needed. This function will overwrite any prior instance
; of the table it creates in p_kb1 if the knowledge base is located in the
; same working directory where you intend to use the function.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-create-sde-prg-rules p_dbms p_kb1)
  (let ((db-obj (dbi-open p_dbms p_kb1)))
    (dbi-query db-obj "DROP TABLE IF EXISTS sde_prg_rules;")
    (dbi-query db-obj "CREATE TABLE sde_prg_rules (
              Id          INTEGER PRIMARY KEY ASC ON CONFLICT ROLLBACK AUTOINCREMENT UNIQUE ON CONFLICT ROLLBACK,
              Context     TEXT    DEFAULT main,
              Status      TEXT    DEFAULT enabled,
              Condition   TEXT    DEFAULT na,
              Action      TEXT    DEFAULT na,
              Description TEXT    DEFAULT na,
              Prob        REAL    CONSTRAINT prob_def_val DEFAULT (1) CONSTRAINT prob_bet_0_1 CHECK (Prob >= 0 AND Prob <= 1) );
              ")
    (dbi-close db-obj)
  )
)


; kb-create-sde-rules - creates table sde_rules.
;
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
(define (kb-create-sde-rules p_dbms p_kb1)
  (let ((db-obj (dbi-open p_dbms p_kb1)))
    (dbi-query db-obj "DROP TABLE IF EXISTS sde_rules;")
    (dbi-query db-obj "CREATE TABLE sde_rules (
              Id          INTEGER PRIMARY KEY ASC ON CONFLICT ROLLBACK AUTOINCREMENT UNIQUE ON CONFLICT ROLLBACK,
              Context     TEXT    DEFAULT main,
              Status      TEXT    DEFAULT enabled,
              Condition   TEXT    DEFAULT na,
              Action      TEXT    DEFAULT na,
              Description TEXT    DEFAULT na,
              Prob        REAL    CONSTRAINT prob_def_val DEFAULT (1) CONSTRAINT prob_bet_0_1 CHECK (Prob >= 0 AND Prob <= 1) );
              ")
    (dbi-close db-obj)
  )
)
    

;kb-query - Performs a single SQL query on closed knowledge base. Use dbi-query 
; directly if the database has been opened.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_sql: SQL query.
;
(define (kb-query p_dbms p_kb1 p_sql)
  (let ((db-obj (dbi-open p_dbms p_kb1)))
    (dbi-query db-obj p_sql)
    (display p_sql)
    (newline)
    (dbi-close db-obj)
  )
)  


; kb-insert-facts - inserts a record on a sde*facts table.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_tb1: the name of an sde*facts table (sde_facts, sde_mem_facts).
; - p_co: context.
; - p_st: status.
; - p_it: item.
; - p_v: value.
; - p_p: probability.
;
(define (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st p_it p_v p_p)
  (let ((a1 "INSERT INTO "))
    (let ((a2 " (Context, Status, Item, Value, Prob) VALUES ('"))
      (let ((a3 "','"))
	(let ((a4 "')"))
	  (let ((b2 (string-append (number->string p_p) a4)))
	    (let ((b3 (string-append a3 b2)))
	      (let ((b4 (string-append (number->string p_v) b3)))
		(let ((b5 (string-append a3 b4)))
		  (let ((b6 (string-append p_it b5)))
		    (let ((b7 (string-append a3 b6)))
		      (let ((b8 (string-append p_st b7)))
			(let ((b9 (string-append a3 b8)))
			  (let ((b10 (string-append p_co b9)))
			    (let ((b11 (string-append a2 b10)))
			      (let ((b12 (string-append p_tb1 b11)))
				(let ((sql (string-append a1 b12)))
				  (newline)
				  (display sql)
				  (kb-query p_dbms p_kb1 sql)
				)
			      )
			    )
			  )
			)
		      )
		    )
		  )
		)
	      )
	    )
	  )
	)
      )
    )
  )
)


; kb-insert-rules - inserts a record on a sde*rules table.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_tb1: the name of an sde*rules table (sde_rules, sde_prg_rules).
; - p_co: context.
; - p_st: status.
; - p_c: condition.
; - p_a: action.
; - p_d: description.
; - p_p: probability.
;
(define (kb-insert-rules p_dbms p_kb1 p_tb1 p_co p_st p_c p_a p_d p_p)
  (let ((a1 "INSERT INTO "))
    (let ((a2 " (Context, Status, Condition, Action, Description, Prob) VALUES ('"))
      (let ((a3 "','"))
	(let ((a4 "')"))
	  (let ((b1 (string-append (number->string p_p) a4)))
	    (let ((b2 (string-append a3 b1)))
	      (let ((b3 (string-append p_d b2)))
		(let ((b4 (string-append a3 b3)))		    
		  (let ((b5 (string-append p_a b4)))
		    (let ((b6 (string-append a3 b5)))
		      (let ((b7 (string-append p_c b6)))
			(let ((b8 (string-append a3 b7)))
			  (let ((b9 (string-append p_st b8)))
			    (let ((b10 (string-append a3 b9)))
			      (let ((b11 (string-append p_co b10)))
				(let ((b12 (string-append a2 b11)))
				  (let ((b13 (string-append p_tb1 b12)))
				    (let ((sql (string-append a1 b13)))
				      (newline)
				      (display sql)
				      (kb-query p_dbms p_kb1 sql)
				    )
				  )
				)
			      )
			    )
			  )
			)
		      )
		    )
		  )
		)
	      )
	    )
	  )
	)
      )
    )
  )
)


; kb-setup-session - loads the default values contained in sde_mem_facts 
; into sde_facts.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-setup-session p_dbms p_kb1)

  ; Clean up things a bit.
  (kb-query p_dbms p_kb1 "VACUUM;")

  ; Delete left-overs from past sessions i.e. rules loaded from sde_prg_rules.
  (kb-query p_dbms p_kb1 "DELETE FROM sde_rules WHERE Context NOT LIKE 'prg0_0';")

  ; Set the Value field of sde_facts to the default values contained in sde_mem_facts.
  (kb-query p_dbms p_kb1"UPDATE sde_facts SET Value = COALESCE( ( SELECT sde_mem_facts.Value FROM sde_mem_facts WHERE ( sde_facts.Item = sde_mem_facts.Item AND sde_mem_facts.Status = 'enabled' AND sde_mem_facts.Context = 'prg0_0' ) ), 0);")

  ; Set the Prob field of sde_facts to the default values contained in sde_mem_facts.
  (kb-query p_dbms p_kb1"UPDATE sde_facts SET Prob = COALESCE( ( SELECT sde_mem_facts.Prob FROM sde_mem_facts WHERE ( sde_facts.Item = sde_mem_facts.Item AND sde_mem_facts.Status = 'enabled' AND sde_mem_facts.Context = 'prg0_0' ) ), 0);")

  ; Initialize status for first cycle.
  (kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'sentodb' WHERE Status != 'disabled';")
  
)
 

; kb-read-sen - read information from non-human sensors or sources.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-read-sen p_dbms p_kb1)

  ; Update status.
  (kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'getfromnetwork' WHERE Status = 'sentodb' OR Status = 'enabled';")  
  (newline)
)

  
; kb-read-mod - read information from external modules. If you want to have user 
; interaction with the system, you should do it within the context of this
; function.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-read-mod p_dbms p_kb1)

  ; Your code here... (TODO this requires a first order function call)
  
  ; Update status.
  (kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'applykbrules' WHERE Status = 'getfromnetwork';")  
  (newline)
)

  
; kb-think - apply rules from sde_rules
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-think p_dbms p_kb1)

  ; Update status.
  (kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'sentodb' WHERE Status = 'applykbrules';")  
  (newline)
)

  
; kb-write-act - write to actuators.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-write-act p_dbms p_kb1)

  ; Update status.
  (kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'sentodb' WHERE Status = 'applykbrules';")  
  (newline)
)


; kb-cycle-lim - perform a limited number of reasoning cycles.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_n1: number of iterations to run.
;
(define (kb-cycle-lim p_dbms p_kb1 p_n1)
  (let loop ((i p_n1))
    (if (= i 0)
	(display "End of cycle...")
	(begin (kb-comp-iter p_dbms p_kb1 i p_n1)
                (loop (- i 1))))))


; kb-reas-iter - perform one reasoning iteration.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-reas-iter p_dbms p_kb1)
  ; Call these functions on every iteration of the cycle.    
  (begin (display "p1 -------------------------------")(newline))
  (newline)
  (kb-read-sen p_dbms p_kb1)
  (kb-read-mod p_dbms p_kb1)
  (kb-think p_dbms p_kb1)
  (kb-write-act p_dbms p_kb1))


; kb-setup-session-wr - setup session wrapper. call kb_setup_session 
; once, when p_i is at its maximum value within a recursively decrementing
; loop.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_i1: i value.
; - p_n1: n value.
;
(define (kb-setup-session-wr p_dbms p_kb1 p_i1 p_n1)
  (if (equal? p_i1 p_n1)(kb-setup-session p_dbms p_kb1)))


; Complete iteration module.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_i1: i value.
; - p_n1: n value.
;
(define (kb-comp-iter p_dbms p_kb1 p_i1 p_n1)
  (kb-setup-session-wr p_dbms p_kb1 p_i1 p_n1)
  (kb-reas-iter p_dbms p_kb1))







