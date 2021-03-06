	SUBROUTINE SHOW_GRID_XML( lun, grid, cx_expr )

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
*
*  list the axes for a grid in xml-style format

* programmer - Ansley Manke, based on show_grid.F
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program
* 6-Aug-2003
* V580 *acm* 11/4/04 add <axes> tags
* v6.5 *acm* 3/10 Cleanup - remove commented-out includes
* V67  *acm* 2/11 XML fixes. New attribute formatting, ![CDATA] escape, upper/lowercase handling.
*      *acm* 3/12 Add E and F dimensions (use nferdims in tmap_dims.parm)
* v685 *acm* 4/12 The flag line_write tells us whether to write the axis name to the xml
* V698 2/16 *acm*  For ticket 1786: if mode_upcase is canceled write axis name
*                  using original upper/lowercase spelling

        IMPLICIT NONE
	include 'tmap_dims.parm'
#	include "tmap_dset.parm"
	include 'xdset_info.cmn_text'
	external xdset_info_data
	include 'xtm_grid.cmn_text'
	external xgt_grid_data
	include	'ferret.parm'
	include	'xvariables.cmn'
	include	'xtext_info.cmn'
	include	'xprog_state.cmn'
	include	'xrisc.cmn'
	include	'xcontext.cmn'


* calling argument declarations
	INTEGER lun, grid, cx_expr

* local variable declarations:
	LOGICAL original 
	INTEGER TM_LENSTR1, TM_LENSTR, STR_DNCASE, STR_SAME,
     .		idim, slen, line, iwrite, status
        CHARACTER*1 axdir
	CHARACTER outstring*512, axname*64

 2020   FORMAT ('<grid name="',A,'">' )
 2030   FORMAT ('<axes>' )
 2040   FORMAT( '<', A1, 'axis>' ,A , '</', A1, 'axis>' )
 2050   FORMAT ('</axes>')
 2060   FORMAT ('</grid>')

* list the axes of the grid

        CALL ESCAPE_FOR_XML (grid_name(grid), outstring, slen)
	WRITE ( risc_buff, 2020 ) outstring(1:slen)
	CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
	WRITE ( risc_buff, 2030 ) 
	CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

	iwrite = 0
	original = .TRUE.
	DO 110 idim = 1, nferdims
	   slen = 0
           line = grid_line(idim, grid)
	   CALL CHOOSE_LINE_NAME(line, original, axname)
           IF (line .GT. 0 .AND. 
     .	          STR_SAME(axname, 'ABSTRACT') .NE. 0) THEN
	      slen = TM_LENSTR(axname)
	      status = STR_DNCASE(axdir, ww_dim_name(idim))
	      IF (slen .EQ. 0) GOTO 110
	      CALL ESCAPE_FOR_XML (axname, outstring, slen)

              IF (cx_expr .EQ. unspecified_int4) THEN
                 WRITE (risc_buff, 2040 ) axdir, outstring(1:slen), axdir
	         CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
	         line_write(line) = .TRUE.
	         iwrite = iwrite + 1
              ELSE
                 IF ( cx_hi_ss(cx_expr,idim).NE.unspecified_int4 .AND. 
     .	           cx_lo_ss(cx_expr,idim).NE.unspecified_int4 ) THEN
                    WRITE (risc_buff, 2040 ) axdir, outstring(1:slen), axdir
	            CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
	            line_write(line) = .TRUE.
	         iwrite = iwrite + 1
                ENDIF
              ENDIF

	   ENDIF
 110	CONTINUE

* (hack:) If there are axes, but nothing has been written yet, then 
* just write the axes.

        IF (iwrite .EQ. 0) THEN
	   DO 120 idim = 1, nferdims
	      slen = 0
              line = grid_line(idim, grid)
              IF (line .GT. 0 .AND. 
     .	          STR_SAME(axname, 'ABSTRACT') .NE. 0) THEN
	         slen = TM_LENSTR(axname)
	         status = STR_DNCASE(axdir, ww_dim_name(idim))
	         IF (slen .EQ. 0) GOTO 120
	         CALL ESCAPE_FOR_XML (axname, outstring, slen)

                 WRITE (risc_buff, 2040 ) axdir, outstring(1:slen), axdir
                 CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
	         line_write(line) = .TRUE.

	      ENDIF
 120	   CONTINUE
        ENDIF

        WRITE ( risc_buff, 2050 )
        CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)
        WRITE ( risc_buff, 2060 )
        CALL SPLIT_LIST(pttmode_explct, lun, risc_buff, 0)

        RETURN

	END

