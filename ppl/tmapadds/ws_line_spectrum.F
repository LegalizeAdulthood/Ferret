	SUBROUTINE WS_LINE_SPECTRUM (zwsid,zwstype, low_index)

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
*  the use of this software or in any product that INCLUDEs this
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
*	Routine to set up the line bundles for generic WS's.
*	J Davison JISAO/PMEL/TMAP 3.23.89
*	*jd* 2.19.92 mod to support atc gks
*	*jd* 8.10.93 mod to support XGKS line colors -- force setting
*       *js* 7.31.97 mod to change call to gqlwk to query_xgks_wkstn

*       *acm* 8/2001  add polymarker call for PLOT/SYMBOL=DOT  
*       *acm* 4/2002  add polymarker calls for circles of different sizes
*                     and colors 1-6 are colored dots, 7-12 are small circles
*                     13-18 are larger circles.  /THICK makes them thicker.

* gsplr: wkid, line index, line type, linewidth scale factor, color index
* gspmr: wkid, marker index, marker type(dot=1), size (const for dot), color index

*        *acm* 12/4/02 NOTE: With changes to gksm2ps.c which multiply the 
*              size of the dots by 4, the output is consistent from 
*              ferret metafiles transformed to postscript, from 
*              "ferret -batch" output, and gif files.
*       *acm* 2/2003 polymarker dot line bundles had not been set for pen > 6
*  v600 *acm* 5/2006 User can change the number of line colors.

	include 'pltcom_dat.decl'
	include 'PLTCOM.DAT'
	include 'gkscm1_inc.decl'
	include 'GKSCM1.INC'
	include 'gkscm2.cmn'
	include 'ppl_in_ferret.cmn'
        include 'ws_types.cmn'
        include 'shade_vars.cmn'
	include 'tmap_dims.parm'
        include 'xplot_setup.cmn'
        INCLUDE 'gkspar.inc'
        INCLUDE 'parampl5_dat.decl'
        INCLUDE 'PARAMPL5.DAT'
        INCLUDE 'plt_inc.decl'
        INCLUDE 'PLT.INC'
        INCLUDE 'pen_inc.decl'  ! with num_line_colors
        INCLUDE 'PEN.INC'
	INCLUDE 'save_colors.cmn'

	integer		zwsid,zwstype,i,j, low_index

#ifdef atc_gks
	integer 	ltype(6)
	data	 	ltype/1,2,3,4,-1001,-1004/
#else
	integer 	ltype(6)
	data		ltype/1,2,3,4,-3,-4/
#endif

	integer		max_pline,max_pmark,max_text,max_fill_area
	integer		max_pattern,max_color,error
	integer		fktr, marktype, index, line_color_reserve,
     .			icolr
                                       
	real		thickness, dotsize, grey, frac
	CHARACTER*100   err_msg


*******************************************************************************
*	WHAT IS AVAILABLE ON THIS WORKSTATION?
	call query_xgks_wkstn (zwstype,error,max_pline,max_pmark,
     .	            max_text,max_fill_area,max_pattern,max_color)
	if (error .ne. 0) goto 1000

        marktype = 1    ! polymarker type 1=dot
        dotsize = 1

*	COLOR OR MONOCHROME?
	if (max_color .le. 2) goto 100

*	COLOR WORKSTATIONS:

* Set up a color spectrum in the remaining space.

	IF ((max_color - num_line_colors) .LT. 0) GOTO 200

	line_color_reserve = num_line_colors
	
*   USE COLORS
        if (protect_used_colors) then
           lo_color_ndx(zwsid) = MAX(hi_color_ndx(zwsid) + 1, line_color_reserve + 1)
           protect_used_colors = .false.
        else
           lo_color_ndx(zwsid) = MAX(line_color_reserve + 1, lo_color_ndx(zwsid))
        endif

        usable_colors = max_color - line_color_reserve - lo_color_ndx(zwsid)

        if (usable_colors .lt. shd_levels) then
           write (6,'(/a)') ' PPL warning: You''re attempting to use '//
     .           'more colors than are available.'
           write (6,'(a/)') '             Using PPL SHASET RESET to re-use'//
     .		 ' protected colors may help.'
           lo_color_ndx(zwsid) = max (line_color_reserve + 1,
     .       max_color - line_color_reserve - shd_levels)
        endif
        hi_color_ndx(zwsid) = lo_color_ndx(zwsid) + shd_levels - 1

*	CHOOSE CUSTOM COLORS OR THE DEFAULT SELECTION
        if (custom_colors) then
           call setup_color_table (zwsid,lo_color_ndx(zwsid),shd_levels)
           if (meta_actv .and. .not. meta_clsplt) call setup_color_table 
     .			(meta_wsid,lo_color_ndx(zwsid),shd_levels)
        else
           call set_default_colors (zwsid,zwstype,lo_color_ndx(zwsid),
     .							shd_levels)
        end if


* Set line bundles
* (can we do 250 thin,medium, and thick lines?

	nthick = 3
	low_index = MAX(num_line_colors* nthick + 2, lo_color_ndx(zwsid))

	do 20 j = 1, shd_levels
	    
	   do 10 fktr = 1,nthick     ! thickness
              thickness = REAL(fktr)
	      icolr = j + lo_color_ndx(zwsid) - 1
              index = low_index + (fktr-1)* shd_levels + j

	      call gspmr (zwsid,index,marktype,dotsize,icolr)
	      call gsplr (zwsid,index,1,thickness,icolr)
       
10	   continue
20	continue

	i = index

* ERROR
1000	return

 100    err_msg = 'Not a color worksatation, cannot set spectrum for color lines'
        CALL errmsg (ferr_out_of_range, status, err_msg, *1000)

 200    err_msg = 'Too many colors in color spectrum for ribbon plot'
        CALL errmsg (ferr_out_of_range, status, err_msg, *1000)
	end