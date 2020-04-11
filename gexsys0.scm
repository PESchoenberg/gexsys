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
; Copyright (C) 2018 - 2020 Pablo Edronkin (pablo.edronkin at yahoo.com)
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
	    kb-create-sde-facts
	    kb-create-sde-mem-facts
	    kb-create-sde-prg-rules
	    kb-create-sde-rules
	    kb-create-sde-experiments
	    kb-query
	    kb-insert-facts
	    kb-insert-default-facts
	    kb-insert-rules
	    kb-insert-sde-rules
	    kb-insert-sde-prg-rules
	    kb-setup-session
	    kb-read-sen
	    kb-read-mod
	    kb-think
	    kb-write-act
	    kb-get-value-from-item
	    kb-display-table ))


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
; - In some cases in which you will build a system that does not use data sets
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
; - p_f3:
;   - Set to 1 if you want to see the rules being applied.
;   - Set to 0 if you don't want to see the rules bing applied (faster).
;
(define (kb-create p_dbms p_kb1 p_f3)
  (let ((co "prg0.1")
	(st "enabled")
	(tb1 "sde_facts")
	(tb2 "sde_mem_facts")
	(tb3 "sde_rules")
	(tb4 "sde_prg_rules")
	(a " ")
	(c " ")
	(d " "))
    (if (> p_f3 0)(ptit " " 1 1 "Creating tables..."))
    (kb-create-sde-facts p_dbms p_kb1)
    (kb-create-sde-mem-facts p_dbms p_kb1)
    (kb-create-sde-prg-rules p_dbms p_kb1)
    (kb-create-sde-rules p_dbms p_kb1)
    (if (> p_f3 0)(ptit " " 1 1 "Inserting default facts..."))
    (kb-insert-default-facts p_dbms p_kb1 tb1 tb2 co st p_f3)
    (if (> p_f3 0)(ptit " " 1 1 "Inserting primary rules..."))
    (kb-insert-sde-rules p_dbms p_kb1 p_f3)
    (if (> p_f3 0)(ptit " " 1 1 "Inserting secondary rules...")) 
    (kb-insert-sde-prg-rules p_dbms p_kb1 p_f3)))


; kb-insert-sde-rules - Inserts a batch of rules into sde_rules; in order  
; to keep things tidy it is better to insert the rules that go directly into 
; sde_rules from those that are stored into sde_prg_rules during the creation 
; of the knowledge base. The rules that go into sde_rules stay all the time 
; in that table and it is better to keep the number of them as low as 
; possible while the rules that go into sde_prg rules are intended to be
; loaded and unloaded from sde_prg_rules into sde_rules on demand.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_f3:
;   - Set to 1 if you want to see the rules being applied.
;   - Set to 0 if you don't want to see the rules bing applied (faster).
;
(define (kb-insert-sde-rules p_dbms p_kb1 p_f3)
  (let ((co "prg0.1")
	(st "enabled")
	(tb "sde_rules")
	(a " ")
	(c " ")
	(d " "))

    ; These are primary rules that are loaded directly into sde_rules.
    
    ; Main counter increment rule.  
    (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1`;")
    (set! a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `counter1` ) + 1 ) WHERE Status = `applykbrules` AND Item = `counter1`;")
    (set! d "1- Increase counter in one unit on each iteration.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)

    ; Load specified program.
    (set! c "SELECT E FROM ( SELECT COUNT(*) AS E FROM sde_rules WHERE Context = ( SELECT ( `prg` || CAST( ( SELECT Value FROM sde_facts WHERE Item = `mode-prg-load` ) AS TEXT ) ) ) ) WHERE E = 0;")
    (set! a"INSERT INTO sde_rules (Context, Status, Condition, Action, Description, Prob) SELECT Context, Status, Condition, Action, Description, Prob FROM sde_prg_rules WHERE sde_prg_rules.Context = ( SELECT ( `prg` || CAST( ( SELECT Value FROM sde_facts WHERE Item = `mode-prg-load` ) AS TEXT ) ) );")
    (set! d "2- Load into sde_rules from sde_prg_rules the program specified at mode-prg-load.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)

    ; Reset mode prg load fact value.
    (set! c "SELECT E FROM ( SELECT COUNT(*) AS E FROM sde_rules WHERE Context = ( SELECT ( `prg` || CAST( ( SELECT Value FROM sde_facts WHERE Item = `mode-prg-load` ) AS TEXT ) ) ) ) WHERE E > 0;")
    (set! a "UPDATE sde_facts SET Value = 0 WHERE Item = `mode-prg-load`;")
    (set! d "3- Once the required prg has been loaded reset mode-prg-load.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)

    ; Delete specified program.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `mode_prg_end` AND Value != ( SELECT Value FROM sde_facts WHERE Item = `cur-ver-prg0` );")
    (set! a "DELETE FROM sde_rules WHERE Context = ( SELECT ( `prg` || CAST( ( SELECT Value FROM sde_facts WHERE Item = `mode_prg_end` ) AS TEXT ) ) );") 
    (set! d "4- Delete rules with Context matching with mode_prg_end.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)    

    ; Reset mode prg end fact value.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `mode_prg_end` AND Value >= 0;")
    (set! a "UPDATE sde_facts SET Value = 0 WHERE Item = `mode-prg-end`;")	
    (set! d "5- Reset mode-prg-end.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)

    ; Instruction to load prg24.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value = ( SELECT Value FROM sde_facts WHERE Item = `load-order-prg24` );")    
    (set! a "UPDATE sde_facts SET Value = ( SELECT Value FROM sde_facts WHERE Item = `cur-ver-prg24` ) WHERE Item = `mode-prg-load`;")
    (set! d "6- Load the current version of prg24 - batch program loader.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)))


; kb-insert-sde-prg-rules - Inserts secondary rules into sde_prg_rules; in order
; to keep things tidy it is better to insert the rules that go directly into 
; sde_rules from those that are stored into sde_prg_rules during the creation 
; of the knowledge base. The rules that go into sde_rules stay all the time 
; in that table and it is better to keep the number of them as low as 
; possible while the rules that go into sde_prg rules are intended to be
; loaded and unloaded from sde_prg_rules into sde_rules on demand.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_f3:
;   - Set to 1 if you want to see the rules being applied.
;   - Set to 0 if you don't want to see the rules bing applied (faster).
;
(define (kb-insert-sde-prg-rules p_dbms p_kb1 p_f3)
  (let ((co " ")
	(st "enabled")
	(tb "sde_prg_rules")
	(a " ")
	(c " ")
	(d " "))

    ; These are secondary programs that are stored in sde_prg_rules and then 
    ; iserted or deleted into sde_rules on demand.
    
    ; prg24.0 is the batch loader for programs required on init.
    (set! co "prg24.0")
    
    ; Load prg1
    (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value = ( SELECT Value FROM sde_facts WHERE Item = `load-order-prg1` );")
    (set! a "UPDATE sde_facts SET Value = ( SELECT Value FROM sde_facts WHERE Item = `cur-ver-prg1` ) WHERE Item = `mode-prg-load`;")
    (set! d "1- Load prg1.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)

    ; Load prg2
    (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value = ( SELECT Value FROM sde_facts WHERE Item = `load-order-prg2` );")
    (set! a "UPDATE sde_facts SET Value = ( SELECT Value FROM sde_facts WHERE Item = `cur-ver-prg2` ) WHERE Item = `mode-prg-load`;")
    (set! d "2- Load prg2.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)

    ; Program is running on this iter. This will tell when was the last
    ; iteration when the program was running.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value >= 0;")
    (set! a "UPDATE sde_facts SET Value = ( SELECT Value FROM sde_facts WHERE Item = `counter1` ) WHERE Item = `last-exec-prg24`;")
    (set! d "3- Update last-exec value to present interation value.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)
    
    ; Del prg24 fact value.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `init-ok` AND Value >= 2;")
    (set! a "DELETE FROM sde_rules WHERE Context LIKE `prg24.%`;")
    (set! d "4- Delete prg24 once init-ok >= 2.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3) 
   
    ; prg1.0 performs several init chores.
    (set! co "prg1.0")

    ; Clean up things a bit.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value >= 0;")
    (set! a "VACUUM;")
    (set! d "1- Tidy up things with a vacuum command.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)
    
    ; Session id increment.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value >= 0;")
    (set! a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `session-id` ) + 1 ) WHERE Status = `applykbrules` AND Item = `session-id`;")
    (set! d "2- Increase value for session id.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)

    ; Session id mem update.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value >= 0;")
    (set! a "UPDATE sde_mem_facts SET Value = ( SELECT Value FROM sde_facts WHERE Item = `session-id` ) WHERE Item = `session-id`;")		  
    (set! d "3- Store new session id in sde_mem_facts.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)

    ; Increase init-ok value.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `init-ok` AND Value >= 0;")
    (set! a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `init-ok` ) + 1) WHERE Item = `init-ok`;")
    (set! d "4- Increase value of init-ok.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3) 

    ; Program is running on this iter. This will tell when was the last
    ; iteration when the program was running.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value >= 0;")
    (set! a "UPDATE sde_facts SET Value = ( SELECT Value FROM sde_facts WHERE Item = `counter1` ) WHERE Item = `last-exec-prg1`;")
    (set! d "5- Update last-exec value to present interation value.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)
    
    ; Delete left-overs from past sessions i.e. rules loaded from sde_prg_rules.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value >= 0;")
    (set! a "UPDATE sde_facts SET Value = 1 WHERE Item = `mode-prg-purge`;")
    (set! d "5- Delete left-overs from past sessions.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)
    
    ; Delete prg1.%.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value >= 0;")
    (set! a "DELETE FROM sde_rules WHERE Context LIKE `prg1.%`;")
    (set! d "6- Delete prg1.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3) 
    
    ; prg2.0 is the batch purge program. It deletes from sde_rules annything
    ; that doesn't belong to context prg0.% or itself, and after performing
    ; those deletions, it deletes itself. This is required so that the 
    ; after deleting everything else can update the mode-prg-purge item.
    (set! co "prg2.0")    

    ;Delete all programs that are not co if mode purge is on. **
    (set! c "SELECT Value FROM sde_facts WHERE Item = `mode-prg-purge` AND Value = 1;")
    ;(set! a (strings-append (list "DELETE FROM sde_rules WHERE ( Context NOT LIKE `prg0.%` AND Context NOT LIKE `prg3.%` );") 0))
    (set! a "DELETE FROM sde_rules WHERE ( Context NOT LIKE `prg0.%` AND Context NOT LIKE `prg2.%` );")
    (set! d "1- Delete anything on sde_rules that has a context different from prg0 or prg2 if mode-prg-purge = 1.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)

    ; Reset mode prg purge fact value.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `mode-prg-purge` AND Value = 1;")
    (set! a "UPDATE sde_facts SET Value = 0 WHERE Item = `mode-prg-purge`;")
    (set! d "2- Once prgs have been purged reset mode-prg-purge.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)

    ; Increase init-ok value.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `init-ok` AND Value >= 0;")
    (set! a "UPDATE sde_facts SET Value = ( ( SELECT Value FROM sde_facts WHERE Item = `init-ok` ) + 1) WHERE Item = `init-ok`;")
    (set! d "3- Increase value of init-ok.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3) 

    ; Program is running on this iter. This will tell when was the last
    ; iteration when the program was running.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `counter1` AND Value >= 0;")
    (set! a "UPDATE sde_facts SET Value = ( SELECT Value FROM sde_facts WHERE Item = `counter1` ) WHERE Item = `last-exec-prg2`;")
    (set! d "4- Update last-exec value to present interation value.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)
    
    ; Delete prg2.%.
    (set! c "SELECT Value FROM sde_facts WHERE Item = `mode-prg-purge` AND Value >= 0;")
    (set! a "DELETE FROM sde_rules WHERE Context LIKE `prg2.%`;")
    (set! d "5- Delete prg2.")
    (kb-insert-rules p_dbms p_kb1 tb co st c a d 1.0 p_f3)))


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
    (dbi-close db-obj)))


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
    (dbi-close db-obj)))


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
    (dbi-close db-obj)))


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
    (dbi-close db-obj)))


; kb-create-sde-experiments - creates a table to hold experimental data as
; a string that might later be passed to tables of the kb such as sde_facts.
; 
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
;
(define (kb-create-sde-experiments p_dbms p_kb1)
  (let ((db-obj (dbi-open p_dbms p_kb1)))
    (dbi-query db-obj "DROP TABLE IF EXISTS sde_experiments;")
    (dbi-query db-obj "CREATE TABLE sde_experiments (
              Id        INTEGER PRIMARY KEY ASC ON CONFLICT ROLLBACK AUTOINCREMENT UNIQUE ON CONFLICT ROLLBACK,
              Context   TEXT        DEFAULT main,
              Status    TEXT        DEFAULT enabled,
              Results   TEXT (1024) DEFAULT na,
              Comments  TEXT (256)  DEFAULT na,
              Timestamp DATETIME    DEFAULT (CURRENT_TIMESTAMP) );
              ")
    (dbi-close db-obj)))


; kb-query - Performs a single SQL query on closed knowledge base. Use dbi-query 
; directly if the database has been opened.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_sql: SQL query.
; - p_f3:
;   - Set to 1 if you want to see the rules being applied.
;   - Set to 0 if you don't want to see the rules bing applied (faster).
;
(define (kb-query p_dbms p_kb1 p_sql p_f3)
  (if (equal? p_f3 2)(ptit " " 1 1 p_sql))
  (let ((db-obj (dbi-open p_dbms p_kb1)))
    (dbi-query db-obj p_sql)
    (dbi-close db-obj)))


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
; - p_f3:
;   - Set to 1 if you want to see the rules being applied.
;   - Set to 0 if you don't want to see the rules bing applied (faster).
;
(define (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st p_it p_v p_p p_f3)
  (let ((a1 "INSERT INTO ")
	(a2 " (Context, Status, Item, Value, Prob) VALUES ('")
	(a3 "','")
	(a4 "')")
	(sql ""))
    (set! sql (strings-append (list a1 p_tb1 a2 p_co a3 p_st a3 p_it a3 (number->string p_v) a3 (number->string p_p) a4) 0))
    (kb-query p_dbms p_kb1 sql p_f3)))


; kb-insert-default-facts - inserts all default facts into a kb.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_tb1: the name of an sde*facts table (sde_facts, sde_mem_facts).
; - p_tb2: the name of an sde*facts table (sde_facts, sde_mem_facts).
; - p_co: context.
; - p_st: status.
; - p_f3:
;   - Set to 1 if you want to see the rules being applied.
;   - Set to 0 if you don't want to see the rules bing applied (faster).
;
(define (kb-insert-default-facts p_dbms p_kb1 p_tb1 p_tb2 p_co p_st p_f3)
    ; counter1 is the main cycle counter.
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "counter1" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "counter1" 0.0 1.0 p_f3)

    ; mode-run 
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "mode-run" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "mode-run" 1.0 1.0 p_f3)

    ; max-inter indicates the max number of iterations to run during kb-think.
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "max-iter" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "max-iter" 1.0 1.0 p_f3)

    ; session-id creates an unique identification for each session of an
    ; existing knowledge base.
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "session-id" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "session-id" 0.0 1.0 p_f3)

    ; model-prg-load contains the number fo program to be loaded from 
    ; sde-prg-rules to sde_rules.
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "mode-prg-load" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "mode-prg-load" 0.0 1.0 p_f3)

    ; mode-prg-purge if 1 loads prg2, which deletes every rule except those
    ; with context prg0.
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "mode-prg-purge" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "mode-prg-purge" 0.0 1.0 p_f3)

    ; mode-prg-end contains the number of program to be deleted from sde_rules.
    ; program scan be deleted by other means as well but it is better form to
    ; do so using this flag.
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "mode-prg-end" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "mode-prg-end" 0.0 1.0 p_f3)

    ; mode-prg-create indicates the number of a program to be created by 
    ; loading prg2, which contains the code that creates the records required
    ; to register a new program within the kb.
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "mode-prg-create" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "mode-prg-create" 0.0 1.0 p_f3)    

    ; init-ok, when it has a value 0 indicates that the process of loading
    ; initial stuff is still going on. when 1, inidcates that all initila
    ; processes have been finished and so the actual work within the kb can 
    ; be initiated.
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "init-ok" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "init-ok" 0.0 1.0 p_f3) 
    
    ; prg0.1 is a dummy denomination for primary rules.
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "cur-ver-prg0" 0.0 1.0 p_f3) 
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "cur-ver-prg0" 0.1 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "load-order-prg0" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "load-order-prg0" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "last-exec-prg0" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "last-exec-prg0" 0.0 1.0 p_f3)

    ; prg1.0 - session setup.
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "cur-ver-prg1" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "cur-ver-prg1" 1.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "load-order-prg1" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "load-order-prg1" 4.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "last-exec-prg1" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "last-exec-prg1" 0.0 1.0 p_f3)
    
    ; prg2.0 - purge programs.
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "cur-ver-prg2" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "cur-ver-prg2" 2.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "load-order-prg2" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "load-order-prg2" 6.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "last-exec-prg2" 0.0 1.0 p_f3)
    
    ; prg24 - initial program batch loader.
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "cur-ver-prg24" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "cur-ver-prg24" 24.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "load-order-prg24" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "load-order-prg24" 2.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb1 p_co p_st "last-exec-prg24" 0.0 1.0 p_f3)
    (kb-insert-facts p_dbms p_kb1 p_tb2 p_co p_st "last-exec-prg24" 0.0 1.0 p_f3))



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
; - p_f3:
;   - Set to 1 if you want to see the SQL query being applied.
;   - Set to 0 if you don't want to see the SQL query being applied (faster).
;
(define (kb-insert-rules p_dbms p_kb1 p_tb1 p_co p_st p_c p_a p_d p_p p_f3)
  (let ((a1 "INSERT INTO ")
	(a2 " (Context, Status, Condition, Action, Description, Prob) VALUES ('")
	(a3 "','")
	(a4 "')")
	(sql ""))
    (set! sql (strings-append (list a1 p_tb1 a2 p_co a3 p_st a3 p_c a3 p_a a3 p_d a3 (number->string p_p) a4) 0))
    (kb-query p_dbms p_kb1 sql p_f3)))


; kb-setup-session - loads the default values contained in sde_mem_facts 
; into sde_facts.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_f3:
;   - Set to 1 if you want to see the SQL query being applied.
;   - Set to 0 if you don't want to see the SQL query being applied (faster).
;
(define (kb-setup-session p_dbms p_kb1 p_f3)

  (if (> p_f3 0)(ptit " " 1 1 "Setting up session..."))
  
  ; Clean up things a bit.
  ;(kb-query p_dbms p_kb1 "VACUUM;" p_f3)

  ; Delete left-overs from past sessions i.e. rules loaded from sde_prg_rules.
  ;(kb-query p_dbms p_kb1 "DELETE FROM sde_rules WHERE Context NOT LIKE 'prg0.1';" p_f3)

  ; These two updates are requred to replace some characters that are used
  ; to input SQL as data itself into an SQLite table, since both Scheme and 
  ; SQLIte do a bit of a mess with special characters such as " ' and `. Thus 
  ; after geetting SQL queries as data into the database using ` in some cases 
  ; because " and ' cause conflicts, those ` characters must be replaced by
  ; ' characters, and that is what this section achieves. Remember that data
  ; introduced in fields Condition and Action in sde*rules tables using SQL 
  ; statements are SQL statements themselves.
  ;
  (kb-query p_dbms p_kb1 "UPDATE sde_rules SET Condition = REPLACE ( Condition, \"`\", \"'\");" p_f3)
  (kb-query p_dbms p_kb1 "UPDATE sde_rules SET Action = REPLACE ( Action, \"`\", \"'\");" p_f3)
  (kb-query p_dbms p_kb1 "UPDATE sde_prg_rules SET Condition = REPLACE ( Condition, \"`\", \"'\");" p_f3)
  (kb-query p_dbms p_kb1 "UPDATE sde_prg_rules SET Action = REPLACE ( Action, \"`\", \"'\");" p_f3)
  
  ; Set the Value field of sde_facts to the default values contained in sde_mem_facts.
  (kb-query p_dbms p_kb1 "UPDATE sde_facts SET Value = COALESCE( ( SELECT sde_mem_facts.Value FROM sde_mem_facts WHERE ( sde_facts.Item = sde_mem_facts.Item AND sde_mem_facts.Status = 'enabled' AND sde_mem_facts.Context = 'prg0.1' ) ), 0);" p_f3)

  ; Set the Prob field of sde_facts to the default values contained in sde_mem_facts.
  (kb-query p_dbms p_kb1 "UPDATE sde_facts SET Prob = COALESCE( ( SELECT sde_mem_facts.Prob FROM sde_mem_facts WHERE ( sde_facts.Item = sde_mem_facts.Item AND sde_mem_facts.Status = 'enabled' AND sde_mem_facts.Context = 'prg0.1' ) ), 0);" p_f3)

  ; Initialize status for first cycle.
  (kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'sentodb' WHERE Status != 'disabled';" p_f3))
 

; kb-read-sen - read information from non-human sensors or sources.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_f1: control value for sensor data function.
; - p_f3:
;   - Set to 1 if you want to see the SQL query being applied.
;   - Set to 0 if you don't want to see the SQL query being applied (faster).
;
(define (kb-read-sen p_dbms p_kb1 p_f1 p_f3)
  (if (> p_f3 0)(ptit " " 1 1 "Reading sensors..."))
  (if (= p_f1 1)(kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'getfromnetwork' WHERE Status = 'sentodb' OR Status = 'enabled';" p_f3)))

  
; kb-read-mod - read information from external modules. If you want to have user 
; interaction with the system, you should do it within the context of this
; function, and modules should exchange data with the kb using status
; 'getfromnetwork'. Interaction with the database should be direct from the 
; external module to the kb setting status to 'getfromnetwork'. On each 
; iteration, data passed to the kb using this status will be 'aligned' with the 
; rest of the data by applying status 'applykbrules' to it.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_f1: control value for module data function.
; - p_f3:
;   - Set to 1 if you want to see the SQL query being applied.
;   - Set to 0 if you don't want to see the SQL query being applied (faster).
;
(define (kb-read-mod p_dbms p_kb1 p_f1 p_f3)
  (if (> p_f3 0)(ptit " " 1 1 "Reading modules..."))
  (if (= p_f1 1)(kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'applykbrules' WHERE Status = 'getfromnetwork';" p_f3)))

  
; kb-think - apply rules from sde_rules to all items sporting status 'applykbrules'.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_f1: control value for think data function.
; - p_f3:
;   - Set to 1 if you want to see the rules being applied.
;   - Set to 0 if you don't want to see the rules being applied (faster).
;
(define (kb-think p_dbms p_kb1 p_f1 p_f3)
  (if (> p_f3 0)(ptit " " 1 1 "Applying rules..."))
  (let (( db-obj (dbi-open "sqlite3" p_kb1)))
    (let ((sql-res1 #t)
	  (sql-res2 #f)
	  (condition "c")
	  (action "a")
	  (con "c")
	  (act "a")
	  (i 0))
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
	     (dbi-query db-obj condition)
	     (set! sql-res2 (dbi-get_row db-obj))
	     ; Equiv to if.
	     (while (not (equal? sql-res2 #f))
		    (dbi-query db-obj action)
		    (if (equal? p_f3 2)(begin (ptit "-" 60 1 "Rule applied: ")
					      (ptit " " 1 1 condition)
					      (ptit " " 1 1 action)))
		    (set! sql-res2 #f))
	     (set! sql-res2 #f)
	     (dbi-query db-obj "SELECT Condition, Action from sde_rules WHERE Status = 'enabled'")
	     (let ((j 0))
	       (while (not (equal? i j))
		      (set! sql-res1 (dbi-get_row db-obj))
		      (set! j (+ j 1))))))
  (dbi-close db-obj))
  ; Once all rules in sde_rules have been reviewed, change status.
  (if (= p_f1 1)(kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'sentodb' WHERE Status = 'applykbrules';" p_f3)))

  
; kb-write-act - write to actuators.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_f1: control value for actuator data function.
; - p_f3:
;   - Set to 1 if you want to see the SQL query being applied.
;   - Set to 0 if you don't want to see the SQL query being applied (faster).
;
(define (kb-write-act p_dbms p_kb1 p_f1 p_f3)
  (if (> p_f3 0)(ptit " " 1 1 "Sending data to actuators..."))
  (if (= p_f1 1)(kb-query p_dbms p_kb1 "UPDATE sde_facts SET Status = 'sentodb' WHERE Status = 'applykbrules';" p_f3)))


; kb-get-value-from-item - returns the value of an item as a numeric variable.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_tb1: sde*facts table.
; - p_it1: item.
;
(define (kb-get-value-from-item p_dbms p_kb1 p_tb1 p_it1)
  (let ((ret 0)
	(sql-res #f)
	(a "';")
	(b "SELECT Value FROM ")(c " WHERE Item = '"))
    (let ((db-obj (dbi-open "sqlite3" p_kb1)))
      (let ((sql-sen (string-append b (string-append p_tb1 (string-append c (string-append p_it1 a))))))
	(dbi-query db-obj sql-sen)
	(set! sql-res (dbi-get_row db-obj)))
        (dbi-close db-obj))
      
    ; If sql-res false (no record found) set ret to zero. Otherwise, set it
    ; to to adequate value obtained by cdr.
    (if (equal? sql-res #f)
	(set! ret 0)
	(begin (set! ret (cdr (list-ref sql-res 0)))))
    (* ret 1)))

  
; kb-display-table - Displays the content of a table as defined by p_sql.
;
; Arguments:
; - p_dbms: database management system to be used.
; - p_kb1: knowledge base name.
; - p_sql: SQL query.
; - p_tit: title or header for listing.
;   - "sql": to use p_sql as value for p_tit.
;
(define (kb-display-table p_dbms p_kb1 p_sql p_tit)
  (let ((sql-res #f))
    (if (equal? p_tit "sql")(set! p_tit p_sql))
    (ptit "=" 60 1 p_tit)
    (let ((db-obj (dbi-open "sqlite3" p_kb1)))   
      (dbi-query db-obj p_sql)
      (display db-obj)
      (newline)
      (write (dbi-get_row db-obj))
      (newline)
      (set! sql-res (dbi-get_row db-obj))
      (while (not (equal? sql-res #f))
	     (display sql-res)(newline)
	     (set! sql-res (dbi-get_row db-obj)))
      (display sql-res)
      (newline)
      (dbi-close db-obj)
      (write (dbi-get_row db-obj))
      (newline))))


