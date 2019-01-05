; ==============================================================================
;
; gexsys0.scm
;
; Gexsys is a simple expert system framework based on GNU Guile and relational 
; databases.
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
  #:use-module (grsp grsp0)
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
	    kb-setup-session-wr
	    kb-get-value-from-item
	    kb-display-table
	    ;kb-setup-session
	    ))


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
; Some default records for sde_facts, sde_mem_facts and sde_rules will be 
; added. In principle, the facts, values and rules created by this function 
; should not be altered by the user.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-create p_dbms p_kb1)
  (let ((co "prg0_0"))
    (let ((st "enabled"))
      (let ((tb1 "sde_facts"))      
	(let ((tb2 "sde_mem_facts"))
	  (let ((tb3 "sde_rules"))
	    (let ((a " "))
	      (let ((c " "))
		(let ((d " "))

		  ; Create tables.
		  (kb-create-sde-edges p_dbms p_kb1)
		  (kb-create-sde-facts p_dbms p_kb1)
		  (kb-create-sde-mem-facts p_dbms p_kb1)
		  (kb-create-sde-prg-rules p_dbms p_kb1)
		  (kb-create-sde-rules p_dbms p_kb1)

		  ; Default records for sde-facts and sde_mem_facts.
		  (kb-insert-facts p_dbms p_kb1 tb1 co st "counter1" 0.0 1.0)
		  (kb-insert-facts p_dbms p_kb1 tb2 co st "counter1" 0.0 1.0)
		  (kb-insert-facts p_dbms p_kb1 tb1 co st "mode-run" 0.0 1.0)
		  (kb-insert-facts p_dbms p_kb1 tb2 co st "mode-run" 1.0 1.0)  
		  (kb-insert-facts p_dbms p_kb1 tb1 co st "max-iter" 0.0 1.0)
		  (kb-insert-facts p_dbms p_kb1 tb2 co st "max-iter" 1.0 1.0) 

                  ; Default records for sde_rules.
		  (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1`;")
		  (set! a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `counter1` ) + 1 ) WHERE Status = `applykbrules` AND Item = `counter1`;")
		  (set! d "Increase counter in one unit on each iteration.")
		  (kb-insert-rules p_dbms p_kb1 tb3 co st c a d 1.0)
		)
	      )
	    )
	  )
	)
      )	    
    )
  )
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

  ; These two updates are requred to replace some characters that are used
  ; to input SQL as data itself into an SQLite table, since both Scheme and 
  ; SQLIte do a bit of a mess with special characters such as " ' and `. Thus 
  ; after geetting SQL queries as data into the database using ` in some cases 
  ; because " and ' cause conflicts, those ` characters must be replaced by
  ; ' characters, and that is what this section achieves. Remember that data
  ; introduced in fields Condition and Action in sde*rules tables using SQL 
  ; statements are SQL statements themselves.
  ;
  (kb-query p_dbms p_kb1 "UPDATE sde_rules SET Condition = REPLACE ( Condition, \"`\", \"'\");")
  (kb-query p_dbms p_kb1 "UPDATE sde_rules SET Action = REPLACE ( Action, \"`\", \"'\");")
  (kb-query p_dbms p_kb1 "UPDATE sde_prg_rules SET Condition = REPLACE ( Condition, \"`\", \"'\");")
  (kb-query p_dbms p_kb1 "UPDATE sde_prg_rules SET Action = REPLACE ( Action, \"`\", \"'\");")
  
  ; Set the Value field of sde_facts to the default values contained in sde_mem_facts.
  (kb-query p_dbms p_kb1 "UPDATE sde_facts SET Value = COALESCE( ( SELECT sde_mem_facts.Value FROM sde_mem_facts WHERE ( sde_facts.Item = sde_mem_facts.Item AND sde_mem_facts.Status = 'enabled' AND sde_mem_facts.Context = 'prg0_0' ) ), 0);")

  ; Set the Prob field of sde_facts to the default values contained in sde_mem_facts.
  (kb-query p_dbms p_kb1 "UPDATE sde_facts SET Prob = COALESCE( ( SELECT sde_mem_facts.Prob FROM sde_mem_facts WHERE ( sde_facts.Item = sde_mem_facts.Item AND sde_mem_facts.Status = 'enabled' AND sde_mem_facts.Context = 'prg0_0' ) ), 0);")

  ; Initialize status for first cycle.
  (kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'sentodb' WHERE Status != 'disabled';")
  
)
 

; kb-read-sen - read information from non-human sensors or sources.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_f1: control value for sensor data function.
;
(define (kb-read-sen p_dbms p_kb1 p_f1)
  (if (= p_f1 1)(kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'getfromnetwork' WHERE Status = 'sentodb' OR Status = 'enabled';"))
)

  
; kb-read-mod - read information from external modules. If you want to have user 
; interaction with the system, you should do it within the context of this
; function, and modules should exchange data with the kb using status
; 'getfromnetwork'. Interaction with the database should be direct from the 
; external module to the kb setting status to 'getfromnetwork'. On each 
; iteration, data passed to the kb using this status will be 'aligned' with the 
; rest of the data by applying stauts 'applykbrules' to it.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_f2: control value for module data function.
;
(define (kb-read-mod p_dbms p_kb1 p_f2)
  (if (= p_f2 1)(kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'applykbrules' WHERE Status = 'getfromnetwork';"))
)

  
; kb-think - apply rules from sde_rules to all items sporting status 'applykbrules'.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_f3: control value for reasoning data function.
;
(define (kb-think p_dbms p_kb1 p_f3)
  (let (( db-obj (dbi-open "sqlite3" p_kb1)))
    (let ((sql-res1 #t))
      (let ((sql-res2 #f))
	(let ((condition "c"))
	  (let ((action "a"))
	    (let ((con "c"))
	      (let ((act "a"))
		(let ((i 0))
                  (dbi-query db-obj "SELECT Condition, Action from sde_rules WHERE Status = 'enabled'")
		  (set! sql-res1 (dbi-get_row db-obj))
                  (while (not (equal? sql-res1 #f))
                         ; Get Condition and action into different string variables.
		         (set! con (list-ref sql-res1 0))
		         (set! act (list-ref sql-res1 1))		       
		         (set! condition (cdr con))
		         (set! action (cdr act))
		         (set! i (+ i 1))
		       
		         ; Test if condition applies. If it does, apply action.
		         (newline)
		         (display "Step 1.4......................")
		         (newline)
		         (dbi-query db-obj condition)
		         (set! sql-res2 (dbi-get_row db-obj))

		         ; Equiv to if.
		         (while (not (equal? sql-res2 #f))
			        (display "Step 1.4.1....................")
			        (newline)
			        (display condition)
			        (newline)
			        (write sql-res2)
			        (newline)
			        (display action)
			        (dbi-query db-obj action)
			        (newline)
			        (set! sql-res2 #f)
		         )
		         (newline)
		         (display "Step 1.5......................")
		         (set! sql-res2 #f)
		         (dbi-query db-obj "SELECT Condition, Action from sde_rules WHERE Status = 'enabled'")
		         (let ((j 0))
			   (while (not (equal? i j))
				        (set! sql-res1 (dbi-get_row db-obj))
				        (set! j (+ j 1))
			   )	
		         )
		         (newlines 3)
		  )
		)
	      )  
	    )
 	  )		   
        )
      )
    )
    (dbi-close db-obj)
  )	

  ;
  (display "Step 2.......................")
  (newline)
  
  ; Once all rules in sde_rules have been reviewed, change status.
  (if (= p_f3 1)(kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'sentodb' WHERE Status = 'applykbrules';"))
)

  
; kb-write-act - write to actuators.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_f4: control value for actuator data function.
;
(define (kb-write-act p_dbms p_kb1 p_f4)
  (if (= p_f4 1)(kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'sentodb' WHERE Status = 'applykbrules';"))
)


; kb-setup-session-wr - setup session wrapper. call kb_setup_session 
; once, when p_i is at its maximum value within a recursively decrementing
; loop.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_i1: i value (see kb-cycle-lim).
; - p_n1: n value (see kb-cycle-lim).
;
(define (kb-setup-session-wr p_dbms p_kb1 p_i1 p_n1)
  (if (equal? p_i1 p_n1)(kb-setup-session p_dbms p_kb1))
)


; kb-get-value-from-item - returns the value of an item as a numeric variable.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_tb1: sde*facts table.
; - p_it1: item.
;
(define (kb-get-value-from-item p_dbms p_kb1 p_tb1 p_it1)
  (let ((ret 0))
    (let ((sql-res #f))
      (let ((db-obj (dbi-open "sqlite3" p_kb1)))  
        (let ((a "';"))
  	  (let ((b "SELECT Value FROM "))
	    (let ((c " WHERE Item = '"))
	      (let ((sql-sen (string-append b (string-append p_tb1 (string-append c (string-append p_it1 a))))))
	        (dbi-query db-obj sql-sen)
	        (set! sql-res (dbi-get_row db-obj))
		(newline)
	      )
	    )
	  )
        )
        (dbi-close db-obj)    
      )   
      ; If sql-res false (no record found) set ret to zero. Otherwise, set it
      ; to to adequate value obtained by cdr.
      (if (equal? sql-res #f)
	  (set! ret 0)
	  (begin (set! ret (cdr (list-ref sql-res 0))))
      )
    )
    (* ret 1)
  )
)


; kb-display-table - Displays the content of a table as defined by p_sql.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_sql: SQL query.
; - p_tit: title or header for listing.
;   - "q": to use p_sql as value for p_tit.
;
(define (kb-display-table p_dbms p_kb1 p_sql p_tit)
  (let ((sql-res #f))
    (if (equal? p_tit "q")(set! p_tit p_sql))
    (pline "-" 60)
    (display p_tit)
    (newline)
    (newline)
    (let ((db-obj (dbi-open "sqlite3" p_kb1)))   
      (dbi-query db-obj p_sql)
      (display db-obj)
      (newline)
      (write (dbi-get_row db-obj))
      (newline)
      (set! sql-res (dbi-get_row db-obj))
      (while (not (equal? sql-res #f))
	     (display sql-res)(newline)
	     (set! sql-res (dbi-get_row db-obj))
      )
      (display sql-res)
      (newline)
      (dbi-close db-obj)
      (write (dbi-get_row db-obj))
      (newline)
    )
  )
)
      





