	SUBROUTINE ALG_ID( text, natom, at_start, at_end,
     .			   at_type, at_id, status )

*
*
*  This software was developed by the Thermal Modeling and Analysis
*  Project(TMAP) of the National Oceanographic and Atmospheric
*  Administration's (NOAA) Pacific Marine Environmental Lab(PMEL),
*  hereafter referred to as NOAA/PMEL/TMAP.
*
*  Access and use of this software shall impose the following
*  obligations and understandings on the user. The user is granted the
*  right, without any fee or cost, to use, copy, modify, alter, enhance
*  and distribute this software, and any derivative works thereof, and
*  its supporting documentation for any purpose whatsoever, provided
*  that this entire notice appears in all copies of the software,
*  derivative works and supporting documentation.  Further, the user
*  agrees to credit NOAA/PMEL/TMAP in any publications that result from
*  the use of this software or in any product that includes this
*  software. The names TMAP, NOAA and/or PMEL, however, may not be used
*  in any advertising or publicity to endorse or promote any products
*  or commercial entity unless specific written permission is obtained
*  from NOAA/PMEL/TMAP. The user also understands that NOAA/PMEL/TMAP
*  is not obligated to provide the user with any support, consulting,
*  training or assistance of any kind with regard to the use, operation
*  and performance of this software nor to provide the user with any
*  updates, revisions, new versions or "bug fixes".
*
*  THIS SOFTWARE IS PROVIDED BY NOAA/PMEL/TMAP "AS IS" AND ANY EXPRESS
*  OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
*  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED. IN NO EVENT SHALL NOAA/PMEL/TMAP BE LIABLE FOR ANY SPECIAL,
*  INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER
*  RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF
*  CONTRACT, NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN
*  CONNECTION WITH THE ACCESS, USE OR PERFORMANCE OF THIS SOFTWARE. 
*
*
* identify the atoms from the text

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system

* V200: 12/21/89
* Unix/RISC port - 1/91 - cannot "//" with CHAR*(*) variables
* V450: 12/2/96 - check that functions are followed by left parens.
*		  Else, they are variable names.
*		- Also, id grid-changing fcns as category alg_grid_chg_fcn
*		- and check for negative constants 
*		==> Note that this may modify natom
* V495: 7/7/98 - allow variable names in single quotes - bypass name check
*     : 9/30/98 - NAG F90 (linux) received error on above change.  
*                 need to put single  tick between double quotes  *kob*
* V500: 12/98 - allow "{1,3,5}" notation
*	 1/99 - allow strings in double quotes (as args to function)
* V553:1/04   - check variable to see if its a counter_var.
* V554 1/04 *acm* - add counter variables for named REPEAT/RANGE control
*      6/04 ywei - change MATCH_NAME function
* V600 8/05 *acm* - Add variable type attrib_val for definitions of the form
*                   varname.attname
* V600  4/06 *acm* - additional declarations found by Solaris compiler
* V600 *acm* 6/06 - fix declarations, found by solaris compiler
* V671 7/11  *acm* Ticket 1868 IFV - masking expressions with ifValid, treating 
*		   zero as valid. 
*       *acm* 3/12 6D Ferret (common uses nferdims in tmap_dims.parm)
* V685+ 12/13 *acm*  bounds checking: tm_digit needs more care in the argument sent in.
* V693+ 12/14 *sh* allow _QD_ and _SQ_ for quotation alternatives 
* V720: 4/17 *acm* Add direction-changing functions as a subset of grid-changing ones

        IMPLICIT NONE
        include 'tmap_dims.parm'
	include 'ferret.parm'
	include 'errmsg.parm'
	include 'rpn.parm'
	include 'xalgebra.cmn'
	include 'xrisc.cmn'
        include 'xvariables.cmn'

* calling argument declarations:
	INTEGER		natom, at_start(maxatoms), at_end(maxatoms),
     .			at_type(maxatoms), at_id(maxatoms), status
	CHARACTER*(*)	text

* internal variable declarations:
	LOGICAL		TM_DIGIT, TM_LEGAL_NAME, ITSA_DIRC_FCN, 
     .			is_digit, single_quoted
	INTEGER		STR_MATCH, GCF_FIND_FCN, TM_LENSTR1,
     .			imatch, i, i2, j, brac_pos, aend,
     .			num_indices, dot, new_nat, first, second, slen
        CHARACTER*512   varname
        
        new_nat = 0

	DO 100 i = 1, natom

* operator ?
	   imatch = STR_MATCH (	text(at_start(i):at_end(i)),
     .				alg_op, num_operators )
	   IF ( imatch .NE. atom_not_found ) THEN
	      at_type(i) = alg_operator
	      at_id(i)   = imatch
	      GOTO 100
	   ENDIF

* punctuation?
	   imatch = STR_MATCH (	text(at_start(i):at_end(i)),
     .				alg_punct, num_punctuations )
	   IF ( imatch .NE. atom_not_found ) THEN
	      at_type(i) = alg_punctuation
	      at_id(i)   = imatch
	      GOTO 100
	   ENDIF

* function ?
	   imatch = STR_MATCH (	text(at_start(i):at_end(i)),
     .				alg_fcn, num_functions )
	   IF ( imatch .NE. atom_not_found ) THEN
	      at_type(i) = alg_function
	      at_id(i)   = imatch
	      GOTO 100
	   ENDIF

* grid-changing function ?
	   imatch = GCF_FIND_FCN( text(at_start(i):at_end(i)) )
	   IF ( imatch .NE. unspecified_int4 ) THEN
	      at_type(i) = alg_grid_chg_fcn
	      IF (ITSA_DIRC_FCN(imatch) ) at_type(i) = alg_dir_chg_fcn
	      at_id(i)   = imatch
	      GOTO 100
	   ENDIF

* logic structure ?
	   imatch = STR_MATCH (	text(at_start(i):at_end(i)),
     .				alg_struct, num_log_structs )
	   IF ( imatch .NE. atom_not_found ) THEN
	      at_type(i) = alg_log_struct
	      at_id(i)   = imatch
	      GOTO 100
	   ENDIF

* logic structure with IFV?
	   imatch = STR_MATCH (	text(at_start(i):at_end(i)),
     .				alg_vstruct, num_log_structs )
	   IF ( imatch .NE. atom_not_found ) THEN
	      at_type(i) = alg_log_vstruct
	      at_id(i)   = imatch
	      GOTO 100
	   ENDIF

* constant ?
          is_digit = TM_DIGIT( text(at_start(i):at_start(i)) )
	  IF ( is_digit ) THEN
	      IF (at_end(i).GT.at_start(i) .AND. text(at_start(i):at_start(i)).EQ.'.') THEN
	         IF (text(at_start(i)+1:at_start(i)+1) .EQ. '.') is_digit = .FALSE.
	      ENDIF
	      IF (is_digit) THEN
 	         at_type(i) = alg_constant
	         at_id(i)   = unspecified_int4
 
	         GOTO 100
	      ENDIF
	   ENDIF


* pseudo-variable ?
* (look for "[" as name end first)
	   brac_pos = INDEX( text(at_start(i):at_end(i)), '[' )
	   IF ( brac_pos .GT. 0 ) THEN
	      aend = at_start(i) + brac_pos - 2
	   ELSE
	      aend = at_end(i)
	   ENDIF
*	   imatch = STR_MATCH (	text(at_start(i):aend),
*     .				alg_pvar, num_pseudo_vars )
*	   IF ( imatch .NE. atom_not_found ) THEN
*	      at_type(i) = alg_pseudo_var
*	      at_id(i)   = imatch
*	      GOTO 100
*	   ENDIF

           CALL string_array_find_caseblind(alg_pvar_head,
     .                         text(at_start(i):aend),
     .                         LEN(text(at_start(i):aend)),
     .                         string_array_result(1),
     .                         max_uvar,
     .                         num_indices)
          IF(num_indices.GT.0) THEN
	      at_type(i) = alg_pseudo_var
	      at_id(i)   = string_array_result(1)
              GOTO 100              
          ENDIF

* constant array of the form "{1,3,5}" ?
	  IF ( text(at_start(i):at_start(i)).EQ."{"
     .	 .AND. text(at_end  (i):at_end  (i)).EQ."}" ) THEN
	      at_type(i) = alg_const_var
	      at_id(i)   = unspecified_int4
	      GOTO 100
	   ENDIF

* string in double quotes? (1/99)
	  IF ( text(at_start(i):at_start(i)).EQ.'"'
     .	 .AND. text(at_end  (i):at_end  (i)).EQ.'"' ) THEN
	      at_type(i) = alg_string
	      at_id(i)   = unspecified_int4
	      GOTO 100
	   ENDIF

* string in _DQ_ style double quotes? 
	  IF (at_end(i)-at_start(i)+1 .GE. 8) THEN
	     IF ( text(at_start(i):at_start(i)+3).EQ.p_DQ_quote
     .	    .AND. text(at_end(i)-3:at_end  (i)  ).EQ.p_DQ_quote ) THEN
	         at_type(i) = alg_string
!*   ... trim string to have only a simple enclosing "_"
!	         at_start(i) = at_start(i) + 3  
!	         at_end  (i) = at_end  (i) - 3
	         at_id(i)   = unspecified_int4
	         GOTO 100
	      ENDIF
	   ENDIF

* attribute value variable.attname (will check later whether the
* variable is in a netCDF dataset and whether the attribute exists)

c           IF (INDEX(text(at_start(i):at_end(i)), '.') .GT. 0 
c     .          .AND. INDEX(text(at_start(i):at_end(i)), '.') .LT.
c     .          at_end(i) - at_start(i)+1 ) THEN

           IF (INDEX(text(at_start(i):at_end(i)), '.') .GT. 0 ) THEN
              
* Is the dot a decimal point within an expression, as in LIST a[y=0.5:9.5]
* or LIST a[gx=sst[d=1],y=1.5]. Look for opening bracket before the dot and 
* closing bracket after the dot. Use varname as a temporary buffer to avoid
* confusion between indices within the whole buffer -text- and indices within 
* the atom we are now looking at.

              varname = text(at_start(i):at_end(i))
              slen = TM_LENSTR1(varname)
              dot = INDEX(varname, '.')

              IF ((INDEX(varname(1:dot-1),'[') .GT. 0) .AND. 
     .            (INDEX(varname(dot+1:slen),']') .GT. 0) ) GOTO 99

* Is this just a number in parentheses?
              IF ( (INDEX(varname(1:1),'(') .GT. 0)  .AND. 
     .             TM_DIGIT(varname(2:slen)) ) GOTO 99

              IF ( (INDEX(varname(1:1),'(') .GT. 0)   .AND. 
     .             (INDEX(varname(slen:slen),')') .GT. 0) .AND. 
     .             TM_DIGIT(varname(2:slen-1)) ) GOTO 99

* is the name in quotations? If so then it may contain a dot and not
* be varname.attname. See if its all within quotes, if so this is a 
* variable name containg a dot.

              first = INDEX(varname, "'" )
              second = 0
              IF (slen .GT. 1) second = INDEX(varname(2:at_end(i)), "'" )
              
              IF (first .GT. 0 .AND. second .GT. 0 .AND. 
     .            dot .GT. first .AND. dot .LT. second) GOTO 99

* identical logic to the previous check, but now looking for _SQ_-enclosed name
              first = INDEX(varname, p_SQ_quote)
              second = 0
              IF (slen .GT. 4) second = INDEX(varname(5:at_end(i)), p_SQ_quote )
              
              IF (first .GT. 0 .AND. second .GT. 0 .AND. 
     .            dot .GT. first .AND. dot .LT. second) GOTO 99

* Otherwise this is a varname.attname  
              at_type(i) = alg_attrib_val
	      at_id(i)   = unspecified_int4

* Is the end of varname a parentheses? Then is this part of (axisname).attname
              IF ( INDEX(text(at_start(i):at_end(i)), ")" ) .GT. 0) THEN
                 j = i - 1
                 new_nat = 0
                 DO WHILE (j .GT. 0 .AND. new_nat .EQ. 0 ) 
                    IF (INDEX(text(at_start(j):at_end(j)), "(" ) .GT. 0) THEN
                       at_type(j) = at_type(i)
                       at_end(j) = at_end(i)
                       at_id(j) = at_id(i)
                       new_nat = j
                    ENDIF
                    j = j - 1
                 ENDDO
              ENDIF

* Is the dot at the end of varname? if so then merge the next atom with this one.

              IF ( text(at_end(i):at_end(i)) .EQ. "." ) THEN
                 new_nat = natom-1
                 at_end(i) = at_end(i+1)
                 DO 110 j = i+1, natom
                    at_start(j) = at_start(j-1)
                    at_end(j) = at_end(j-1)
  110            CONTINUE
              ENDIF

              GOTO 100
	   ENDIF

* cant identify it - we will call it an variable for now
* check for legal name not enclosed in quotation marks or _SQ_
 99	   single_quoted = text(at_start(i):at_start(i)) .EQ. "'"
	   IF (.NOT.single_quoted .AND. at_end(i)-at_start(i).GE.7)
     .         single_quoted = text(at_start(i):at_start(i)+3) .EQ. p_SQ_quote
	   IF (.NOT.single_quoted) THEN
	     IF ( .NOT.TM_LEGAL_NAME(text(at_start(i):aend)) ) GOTO 5100
	   ENDIF
	   at_type(i) = alg_variable
	   at_id(i)   = unspecified_int4

 100	CONTINUE

        IF (new_nat .NE. 0) natom = new_nat

* A function name not followed by a left paren is actually a variable (12/96)
	DO 200  i = 1, natom
	   IF ( at_type(i) .EQ. alg_function
     .	   .OR. at_type(i) .EQ. alg_grid_chg_fcn ) THEN
	      IF (i .EQ. natom) THEN
	          at_type(i) = alg_variable
	          at_id(i)   = unspecified_int4
	      ELSEIF ( at_type(i+1) .NE. alg_punctuation
     .		  .OR. at_id  (i+1) .NE. left_paren ) THEN
	          at_type(i) = alg_variable
	          at_id(i)   = unspecified_int4
	      ENDIF
	   ENDIF
 200	CONTINUE

* Just see if it is in the list of counter variables.  These need to be
* treated as a constant at the start of interp_stack (in is_uvar_grid and so on)

* start by checking counter variable names
	DO 240 i = 1, natom
*           len_test = TM_LENSTR(text(at_start(i):at_end(i)))
*           DO 220 j = 1, num_counter_vars
*              len_mchars = TM_LENSTR(countervar_name(j))
*              IF ( MATCH_NAME(text(at_start(i):at_end(i)),len_test, 
*     .             countervar_name(j),len_mchars ) ) THEN
*	         at_type(i) = alg_counter_var
*	         at_id(i)   = unspecified_int4
*	      ENDIF
* 220	   CONTINUE
 	CALL string_array_find(countervar_name_head,
     .                         text(at_start(i):at_end(i)),
     .                         LEN(text(at_start(i):at_end(i))),
     .                         string_array_result(1),
     .                         max_uvar,
     .                         num_indices)
        IF(num_indices.GT.0) THEN
	   at_type(i) = alg_counter_var
	   at_id(i)   = unspecified_int4
        ENDIF
 240	CONTINUE

* 12/96 kludge ...
* In ALG_BREAK_UP the operators EQ, LT, GT, ... are just names so that routine
* misinterprets the negative in  "a EQ -1". Correct that here.
 290	DO 310 i = 3, natom
	   IF ( at_type(i) .EQ. alg_constant ) THEN
	      IF ( at_type(i-1) .EQ. alg_operator
     .	     .AND. at_id  (i-1) .EQ. 2
     .	     .AND. at_type(i-2) .EQ. alg_operator
     .	     .AND. at_end (i-1) .EQ. at_start(i)-1    ) THEN
* ... this minus sign actually belongs to the constant
	         at_start(i) = at_start(i-1)
	         DO 300 i2 = i, natom 	   
	            at_start(i2-1) = at_start(i2)
	            at_end  (i2-1) = at_end  (i2)
	            at_type (i2-1) = at_type (i2)
	            at_id   (i2-1) = at_id   (i2)
 300	         CONTINUE
	         natom = natom - 1
	         GOTO 290
	      ENDIF
	   ENDIF
 310	CONTINUE

* insert flag indicating end of atom list
	at_type(natom+1)  = alg_finished
	at_start(natom+1) = 1
	at_end(natom+1)   = 1

* successful completion
	status = ferr_ok
	RETURN

* error exits
 5000	RETURN
 5100	risc_buff = text(at_start(i):aend)
	CALL ERRMSG( ferr_syntax, status,
     .		     'illegal name: '//risc_buff(:at_start(i)-aend+1), *5000 )
	END
