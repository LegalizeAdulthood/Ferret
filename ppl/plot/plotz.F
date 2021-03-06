	SUBROUTINE PLOTZ(Z,XF,YF,XLPLOT,YLPLOT,XHPLOT,YHPLOT)
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
C**     
C**     @(#)plotz.F	1.4    9/9/88
C**     
C**     
C***********************************************************************
C**     
C**     PLOT+ Scientific Graphics System
C**     
C***********************************************************************
C**     
C**     
C       lots of places ---> PPLMOD_PPLCMD ---> PPLMOD_PLTIT ---> PPLMOD_PLOTZ
C       
C       This subroutine is called for CONTOUR, SHADE and FILL plots
C       and puts the data on the proper grid and then plots it.
C 
C       Z      - actual 2D data array
C       XF     - X factor ( page? length / X range )
C       YF     - Y factor
C       XLPLOT - lower X page? coordinate
C       YLPLOT - lower Y page? coordinate
C       XHPLOT - upper X page? coordinate
C       YHPLOT - upper Y page? coordinate
C       
*       MOD *JD* to include AREA in TMAP PPL+
*       MOD *JD* moved dimension z(nx,ny) from below subroutine statement to
*       below includes so that CONTOUR will work on the MAC -- Ed Flinchem
*       had to do this to make that work. 3.29.93 DIMENSION --> REAL as well.
*       MOD *JD* To permit use of centered levels and specify the delta Z
*       value as well.  Added variables to CONT.INC common 8.3.95  
*	*jd* 8.28 fix bug in dz specification
*	*jd* 2.96 Change centered option so that data not spanning zero
*       is centered as well.
*       *jc* 4.97 Major clean up and commenting
*       *jc* 5.97 Added code for curvilinear coordinates
* V510 4/00 *sh - corrected faulty logic for centered levels (delta wrong)
* V540 10/01 *acm Set LWGT, LDIG when using previously defined levels; have 
*                 not been set if previous call was SHADE
* V540 10/01 *acm remove VMS include statements
* V540 12/01 *acm* do NOT set LWGT, LDIG here; set them in SHADE
* V541  5/02 *acm* Check that number levels not greater than size of 
*                  LWGT, LDIG, and ZLEV; issue an error message.
* V550 11/02 *acm* For fine grids, XLPLOT, XHPLOT, YLPLOT, YHPLOT computations
*                  need to be done in double precision.
* V550 11/02 *acm* New call to create LEVELS symbols, routine setlab_syms
* V554  9/03 *acm* Fix precision bug double precision, for fine grids in 
*                  curvlinear coordinates. See also pltit.F, setax.F
* v581 *acm* 3/05 open levels (-INF) (INF)
* V581 *acm* 7/05 fix bug 1279: fill/lev=(n) gave exactly N not nlev2=approx N
* V600 *acm* 1/06 prevent values of LOG10(0.0)
* V602 *acm* 2/07 check status coming out of CONSEG; part of fix to bug 1485
* V603 *acm* 5/07 Compute sig figs for labels along contours, and dash characteristics
*                 even when re-using previous levels. Those levels may have come from
*                 a previous SHADE plot as in SHADE/LINE and therefore the levels were
*                 set but not the contour label and line characteristics.
* V603 *acm* 7/07 Fix bug 1335, zero contours not dark. zlev(i) not seen as 0. Fix by 
*                 using TM_FPEQ to compare zlev(i) to 0., within machine accuracy.
* V604 *acm& 7/07 Fix bug 1519. The setting of levels info was incorrectly resetting the
*                 highest and lowest level when doing (-inf) and (inf) levels spec.
* v68  *acm* 4/08 Allow shade, vector plots of degenerate regions - world region 
*              within a grid cell
* V68  *acm* 1/12  changes for double-precision ferret, single-precision pplus
* V698 *acm* 3/16  Ticket 2375: outline color key in black even on an overlay.

	INCLUDE 'PARAMPL5.DAT'
	INCLUDE 'ZGRIDD.INC'
	INCLUDE 'ZGRID.INC'
	INCLUDE 'AXIS.INC'
	include	'cont_inc.decl'
	INCLUDE 'CONT.INC'
	INCLUDE 'HD.INC'
	INCLUDE 'TAXIS.INC'
	INCLUDE 'AXISL.INC'
	INCLUDE 'PEN.INC'
	INCLUDE 'LINES.INC'
	INCLUDE 'PLTL.INC'
	include 'xcurvilinear.cmn'
        INCLUDE 'errmsg.parm'

* Argument declarations
**	DIMENSION Z(NX,NY)
	REAL	  Z(NX,NY)
        REAL      XF,YF
        REAL*8    XLPLOT,YLPLOT,XHPLOT,YHPLOT

* Local declarations
        INTEGER   status, slen1, slen2, nlev1
        CHARACTER TM_FMT*48, buff1*20, buff2*20, err_msg*40
        REAL*8    DXFF, DXOF, DYFF, DYOF
        REAL      XFF, XOF, YFF, YOF, DMIN, DMAX, DZMAX
        LOGICAL   TM_FPEQ_SNGL

	logical		valid

C*       *jd* Linux port 12.96 add EXTERNAL calls below
        external scale, range

C	VAX/VMS
C
	DIMENSION IZMRKD(3)
	DATA IZMRKD/12,16,3/

C
C  Set the contour/color levels

        CALL SET_LEVELS_SHADE_FILL (status)
	IF (status .NE. ferr_ok) GOTO 5000


C       DRAW CONTOUR
C
C       from ppl/include/PPL.INC:
C
C       JTYPE: = 2 2-d irregular rectangular grid
C              = 1 1-d set
C              = 0 2-d regular rectangular grid (integer)
C              =-1 2-d second component of a vector regular grid
C              =-2 2-d second component of a vector irregular grid
C
C
C       from ppl/include/ZGRID.INC:
C
C       controls for the plotting of the positions of ungridded x,y,z data
C
C       IZTYP: =0 no points drawn
C              =1 points drawn along the x axis
C              =2 points drawn along the y axis
C              =3 points drawn at each raw input value
C       
C       IZMRK: =0 use the default mark
C              =n use mark n to denote the location
C
C       IZLEN: number of points in the x,y,z triplets

C
C       If it's a 2-d irregular grid plot and points have been drawn
C
	if (abs(jtype).eq.2 .and. iztyp.ne.0) then

	   call markh(hmark(1))

	   if (izmrk.eq.0) then
	      imrk=izmrkd(iztyp)
	   else
	      imrk=izmrk
	   endif

	   if (iztyp.eq.1) then

	      do 200 i=1,nx
		 call trans(0,z(i,ny+1),ylo,xt,y)
		 call plot(xt,y,0,imrk)
		 call mark(imrk)
 200	      continue

	   else if (iztyp.eq.2) then

	      do 210 j=1,ny
		 call trans(0,xlo,z(j,ny+2),x,yt)
		 call plot(x,yt,0,imrk)
		 call mark(imrk)
 210	      continue

	   else

	      do 230 i=1,nx
		 do 220 j=1,ny
		    call trans(0,z(i,ny+1),z(j,ny+2),xt,yt)
		    call plot(xt,yt,0,imrk)
		    call mark(imrk)
 220		 continue
 230	      continue

	   endif

	endif

C
C       If there are some x,y,z triplets and points have been drawn
C
	IF (IZLEN.NE.0.AND.IZTYP.NE.0) THEN

	   CALL MARKH(HMARK(1))

	   IF (IZMRK.EQ.0) THEN
	      IMRK=IZMRKD(IZTYP)
	   ELSE
	      IMRK=IZMRK
	   ENDIF

	   IF (IZTYP.EQ.1) THEN

	      call trans(0,xx(1),ylo,xt,y)
	      CALL PLOT(XT,Y,0,IMRK)
	      CALL MARK(IMRK)
	      DO 300 I=2,IZLEN
		 IF (XT.NE.XX(I)) THEN
		    call trans(0,xx(i),ylo,xt,y)
		    CALL PLOT(xt,Y,0,IMRK)
		    CALL MARK(IMRK)
		 ENDIF
 300	      CONTINUE

	   ELSE IF (IZTYP.EQ.2) THEN

	      call trans(0,xlo,yy(1),x,yt)
	      CALL PLOT(X,YT,0,IMRK)
	      CALL MARK(IMRK)
	      DO 310 I=2,IZLEN
		 IF (YT.NE.YY(I)) THEN
		    call trans(0,xlo,yy(i),x,yt)
		    CALL PLOT(X,yt,0,IMRK)
		    CALL MARK(IMRK)
		 ENDIF
 310	      CONTINUE

	   ELSE

	      DO 320 I=1,IZLEN
		 call trans(0,xx(i),yy(i),xt,yt)
		 CALL PLOT(xt,yt,0,IMRK)
		 CALL MARK(IMRK)
 320	      CONTINUE

	   ENDIF

	ENDIF

	CALL SCALE(1.,1.,XORG,YORG,0.,0.)
	IF (IWIND.NE.0) CALL WINDOW(0.0,0.0,XLEN,YLEN)
	CALL COLOR(IPEN(1))


C       Calculate the following quantities:
C       ~FF - multiplication factors to go from axis to page coords?
C       ~OF - page offset to the beginning of an axis?

	call trans(0,xmin,ymin,xtm,ytm)
	call trans(0,xmax,ymax,xtx,ytx)
	DXFF = (XHPLOT - XLPLOT)/(xtx-xtm)
	IF (TM_FPEQ_SNGL(xtx, xtm)) DXFF = 1.
	DXOF = (XLPLOT) - DXFF*xtm
	DYFF = (YHPLOT - YLPLOT)/(ytx-ytm)
	IF (TM_FPEQ_SNGL(xtx, xtm)) DXFF = 1.
	DYOF = (YLPLOT) - DYFF*ytm

	XFF = DXFF
	XOF = DXOF
	YFF = DYFF
	YOF = DYOF


C       If this is a 2-D plot on an irregular grid, use TRANS() to 
C       scale the points appropriately.  Values are returned in 
C       the xx() and yy() arrays.
C
	IF (abs(jtype).eq.2) THEN
       
	   do 400 i=1,nx
	      call trans(0,z(i,ny+1),ymin,xx(izlen+i),yt)
 400	   continue
	   do 410 j=1,ny
	      call trans(0,xmin,z(j,ny+2),xt,yy(izlen+j))
 410	   continue


C       For all other plot types fill in XX() and YY() by
C       multiplying the index value by the DX or DY delta values.

	ELSE

	   DX = (xtx - xtm)/(NX - 1)
	   DY = (ytx - ytm)/(NY - 1)
	   IF (NX .EQ. 1) DX = 1.
	   IF (NY .EQ. 1) DY = 1.

	   DO 500 I=1,NX
	      XX(IZLEN+I)=DX*(I-1)+xtm
 500	   CONTINUE
	   DO 510 J=1,NY
	      YY(IZLEN+J)=DY*(J-1)+ytm
 510	   CONTINUE

! TEST - fix XX if this is a subspan-modulo axis.
           IF ( .NOT. curvilinear ) THEN
              CALL box_centers ('X',xx(IZLEN+1),nx,xx(NX+IZLEN+1),valid)
	      DO i = 1, nx
	         xx(izlen+i) = xx(nx+izlen+i)
	      ENDDO

              CALL box_centers ('Y',yy(IZLEN+1),ny,yy(Ny+IZLEN+1),valid)
	      DO j = 1, ny
	         yy(izlen+j) = yy(ny+izlen+j)
	      ENDDO
	   ENDIF

	ENDIF

* Now that the levels are set, create the LEVELS symbols

        CALL setlab_syms (ZLEV, MAX(NLEV2,1) )

	 if (makep.eq.'CONTOUR') then
c *kob* 8/97 had to move the continuation marker to col 5 - it was in col 8
c       this bombed aix compiler, though it seems to work on others
	    CALL CONSEG(Z,NX,NY,XX(IZLEN+1),YY(IZLEN+1),NX,NY,
     1	 XFF,XOF,YFF,YOF,ZLEV,LDIG,LWGT,LCLR,NLEV2,HGT,
     2	 NARC,CANGLE,status)
             IF (status .NE. ferr_ok) GOTO 5002

* Ticket 2375: A color fill plot needs IPEN(0), so that if there is a
* color key it is labeled and outlined in black even on an overlay.
	 else if (makep.eq.'FILL') then
	    
	    CALL COLOR(IPEN(0))
            nlev1 = nlev
            nlev = nlev2
	    call arfill(z,xx(izlen+1),yy(izlen+1),nx,ny)
            nlev = nlev1

	 else
*******     SQRFILL NOT A TMAP PPL+ COMMAND *jd* 2.19.99
*******	    call sqrfill(z,xx(izlen+1),yy(izlen+1),nx,ny,
*******     1	 zlev,nlev2)

	 endif

C
C	END VAX/VMS
C
	CALL COLOR(IPEN(0))
	CALL SCALE(XF,YF,XORG,YORG,XLO,YLO)

	RETURN

C  Error exit when too many levels specified.
C  Arrays LWGT, LDIG, and ZLEV are length ICNLEV=500

 5000   ii = ICNLEV
        buff1 = TM_FMT(DBLE(ICNLEV), 0, 20, slen1)
        buff2 = TM_FMT(DBLE(NLEV2), 0, 20, slen2)
        err_msg = '# of contour levels > '// buff1(1:slen1) //
     .          '  (' // buff2(1:slen2) // ')'
        CALL errmsg (ferr_out_of_range, status, err_msg, *5002)

 5002   return

	END
