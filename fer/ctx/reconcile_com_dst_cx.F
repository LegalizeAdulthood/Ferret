	SUBROUTINE RECONCILE_COM_DST_CX( com_cx, dst_cx, protected_ax )

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
* The component context is fully fleshed out (necessarily, since
* the component has already been obtained) whereas the destination (result)
* context may still have some unknown axis limits.  So pass the component
* information over to the destination on all except the critical axis
* on which the transformation/regrid, etc is about to be performed

* programmer - steve hankin
* NOAA/PMEL, Seattle, WA - Tropical Modeling and Analysis Program

* V420: 11/95 - code lifted from IS_REGRID **including warnings about untested
*			alternatives**
* V530: *sh* 3/01 - bug fix: preserve cx_has_impl_grid
*       *acm* 3/12 6D Ferret (common uses nferdims in tmap_dims.parm)

        IMPLICIT NONE
	include 'tmap_dims.parm'
	include	'ferret.parm'
	include	'xcontext.cmn'

* calling argument declarations:
	INTEGER	com_cx, dst_cx, protected_ax

* local variable declarations
	LOGICAL has_impl

* Make the destination context like the source data context on all except
* the regrid axis.  That one keeps the user-requested size.
* (Other axes may have been modified by information embedded within a
* user-variable definition.  An alternative (untested 8/89) approach is to
* call PASS_AMBIG_LI** for uvars)

* save the implicit grid status of the destination
	has_impl = cx_has_impl_grid(dst_cx)

	CALL TRANSFER_CONTEXT( com_cx, cx_buff )

	CALL TRANSFER_AXIS( protected_ax, dst_cx, cx_buff )

	CALL TRANSFER_CONTEXT( cx_buff, dst_cx )

* restore the implicit grid status of the destination
	cx_has_impl_grid(dst_cx) = has_impl

	RETURN
	END	
