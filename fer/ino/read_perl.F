	SUBROUTINE READ_PERL (  cx, mr, status )
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
* read a stream formatted file 
* stolen from read_ez

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* written for VAX computer under VMS operating system
*
* 9/99 *js*  First version hacked from read_binary
* V552 *acm* 4/03- up VAR_CODE  to 128
* v604 *acm* 7/07 increase length of ds_name
* V63  *acm* 10/09 Changes for 1 build
*       *acm* 3/12 cleanup old VMS ifdef
* V702: *sh* 1/17 - bug fix: mr_protected must *end* at mr_not_in_use (=0)
*                   note: this fix was never tested -- applied blindly
*                   by analogy with other ino/read*.F routines
*		  - and for trac #2369 -- dynamic memory management 
*		    (was dynamic memory ever used in this routine?)

        IMPLICIT NONE
	include	'tmap_errors.parm'
	include	'tmap_dims.parm'
	include	'xdset_info.cmn_text'
	external xdset_info_data
	include	'xtm_grid.cmn_text'
	external xgt_grid_data
	include 'xstep_files.cmn_text'
	external xstep_files_data
	include	'ferret.parm'
	include	'errmsg.parm'
	include	'xcontext.cmn'
	include	'xvariables.cmn'
	include	'xprog_state.cmn'
	include	'xtext_info.cmn'

* calling argument declarations:
	INTEGER	cx, mr, status, fstatus

* functions
	INTEGER PL_OPEN, PL_READ_VAR

* internal variable declarations:
	INTEGER		nferdimsp1 
	PARAMETER	(nferdimsp1 = nferdims+1)
	INTEGER 	CGRID_SIZE, 
     .			idim, ask_var, category, data_set, grid, ivar,
     .			fvar, nvar20, the_var, nleft, 
     .			cx0, cx1, cx20(20), mr20(20),
     .			mr1, rec1, 
     .			rec_to_read, nrepeat, columns, num_names
	INTEGER         lengths(nferdimsp1)
	LOGICAL         firstTime
	CHARACTER	VAR_CODE*128
	CHARACTER*256   cerrmsg,ferrmsg
	CHARACTER*1024  cname

* --- end of introductory code ---

* nvar20  and the_var - value from 1 to 20      --> variable # within EZ set
* ask_var and fvar    - value from 1 to maxvars --> var # within DSET common

* initialize
	cx0 = cx_stack_ptr
	data_set = cx_data_set( cx )
	category = cx_category( cx )
	ask_var  = cx_variable( cx )
	grid = cx_grid( cx )
	fvar      = 0
	nvar20    = 0
	rec_to_read = 2**30      ! was 99999 - limited file reads
	firstTime = .true.

* how many values of each variable are repeated on each record ?
	columns = ds_ntuple(data_set)
	num_names = ds_basic_axes(1, data_set)
	nrepeat = columns / num_names

* purge from memory any variables from this data set to avoid duplication
* (1 variable may be deleted at any time by memory management but this routine
*  always reads all of 'em)
* note: problem arises if variable is in use
!	CALL PURGE_DSET( data_set )

* create a memory variable for each of up-to-20 variables in the file
	DO ivar = 1, 20

* ... locate the next variable in this data set
	   DO fvar = fvar+1, maxvars
	      IF ( ds_var_setnum( fvar ) .EQ. data_set ) then
* ... is it a dummy '-' placeholder in the variable list ?
 		 IF (INDEX( ds_var_code(fvar),'-') .EQ. 0 ) THEN

* save record of which is the desired var
		    nvar20 = nvar20 + 1
		    IF ( fvar .EQ. ask_var ) the_var = nvar20

* ... create a context describing this variable
		    CALL STACK_PTR_UP( cx_stack_ptr, max_context, status )
		    IF ( status .NE. ferr_ok ) RETURN
		    cx20(nvar20) = cx_stack_ptr
		    CALL TRANSFER_CONTEXT( cx, cx_stack_ptr )
		    cx_variable( cx_stack_ptr ) = fvar
		    cx_grid( cx_stack_ptr ) = ds_grid_number( fvar )
		    cx_bad_data( cx_stack_ptr ) = ds_bad_flag( fvar ) ! 12/93 add'n
		    DO idim = 1, nferdims
		       cx_lo_ss( cx_stack_ptr, idim ) = ds_grid_start( idim, fvar )
		       cx_hi_ss( cx_stack_ptr, idim ) = ds_grid_end  ( idim, fvar )
		       cx_by_ss( idim, cx_stack_ptr ) = .TRUE.
* 3/99 *kob* - nag F90 wants to use eqv for logical expressions
		       if (firstTime .eqv. .TRUE.) THEN
			  lengths(idim) = ds_grid_end(idim,fvar) - 
     .		          ds_grid_start(idim,fvar) + 1
		       end if
		       CALL CONFINE_AXIS( idim, cx_stack_ptr, status )
		       IF ( status .NE. ferr_ok ) RETURN
		       CALL FLESH_OUT_AXIS( idim, cx_stack_ptr, status )
		       IF ( status .NE. ferr_ok ) RETURN
		    END DO
		    firstTime = .FALSE.

*       read only what will fit into smallest grid
		    rec1 = CGRID_SIZE(cx_stack_ptr) / nrepeat
		    rec_to_read = MIN( rec_to_read, rec1 )

*       reserve and catalog space for the result
		    CALL CREATE_MEM_VAR( cx_stack_ptr, mr20(nvar20), status )
		    IF ( status .NE. ferr_ok ) GOTO 5000
		 END IF
	      END IF
	   END DO
	END DO

* point to asked-for variable and create dummy entries for the rest
 500	mr = mr20( the_var )
	DO nleft = nvar20+1, 20
	   mr20(nleft) = dummy_mr
	END DO

* initialize the Perl reader
	call toChar(ds_name(data_set), cname)
	if (PL_OPEN(cname) .eq. 0) goto 6000

	fvar = 0
	nvar20 = 0
	DO ivar = 1, 20
	   DO fvar = fvar+1, maxvars
	      IF ( ds_var_setnum( fvar ) .EQ. data_set ) then
 		 IF (INDEX( ds_var_code(fvar),'-') .EQ. 0 ) THEN
		    nvar20 = nvar20 + 1
		    fstatus = PL_READ_VAR( memry(mr20(nvar20))%ptr,
     1		                 lengths )
		 END IF
		 if (fstatus .EQ. 0) goto 6000
	      END IF
	   END DO
	END DO

* flag that all the data is available
	DO ivar = 1, nvar20
	   mr1 = mr20(ivar)
	   CALL MR_AVAILABLE(mr1)
	ENDDO

* the data region obtained may be inadequate for the request
* ("cx" is request, "cx1" is available)
	cx1 = cx20(the_var)
	DO 900 idim = 1, nferdims
	   IF ( cx_hi_ss(cx,idim) .GT. cx_hi_ss(cx1,idim) ) THEN
	      IF ( cx_hi_ss(cx_last,idim) .NE. unspecified_int4
     .	     .OR.  cx_given(idim,cx) ) THEN
* ... error: the user explicitly requested more than there is
	         GOTO 5600
              ELSEIF (cx_lo_ss(cx,idim) .GT. cx_hi_ss(cx1,idim)) THEN
* ... requested data is completely out of range of disk data (2/93 bug fix)
                 GOTO 5600
	      ELSE
* ... no error: the region was filled in by FERRET automatically
	         cx_hi_ss(cx,idim) = cx_hi_ss(cx1,idim)
	         cx_hi_ww(idim,cx) = cx_hi_ww(idim,cx1)
	      ENDIF
	   ENDIF
 900	CONTINUE

* successful completion
	cx_stack_ptr = cx0
	CALL PL_CLOSE()
	RETURN

* error exit
 4900	nvar20 = nvar20 + 1		! delete all
 5000	cx_stack_ptr = cx0
	DO 5010 nleft = 1, nvar20-1	! delete all except last
 5010	CALL DELETE_VARIABLE(mr20(nleft))
	CALL PL_CLOSE()
 5500	RETURN
 5600	CALL ERRMSG( ferr_limits, status,
     .		ww_dim_name(idim)//' axis of '//VAR_CODE(cat_file_var,ask_var),
     .		*5500 )
 6000	CALL PL_GET_ERROR(cerrmsg)
	CALL TM_CTOF_STRNG(cerrmsg, ferrmsg, 255)
	CALL TM_SPLIT_MESSAGE(err_lun, ' **ERROR: '//ferrmsg(1:LEN(ferrmsg)))
        CALL ERRMSG( ferr_TMAP_error, status, ' ', *4900 )
	END	

