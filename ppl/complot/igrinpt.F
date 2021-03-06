      FUNCTION IGRNPT(window_id, show_menu, X,Y)
C** 
C**    @(#)igrinpt.F	1.2    3/27/88

*    modified 6/99 for Ferret V500 *sh* -- added new arguments and
*       return COMMON XGRINPT with information about what was digitized
*       New arguments:
*               show_menu
*    Note: this routine should really be split into two -- one to put up
*       the choice menu, another to get the position input. Taking the lazy
*       approach now ...
*
* v5.11 *kob* 5/00 - added ifdef to check for f90 - if so have to
*                    initialize has_new_mouse w/in block data since it
*                    exists in common
C**
C**
C***********************************************************************
C**
C**                 PLOT+ Scientific Graphics System
C**
C***********************************************************************
C**
C**
C
C     IGRNPT(X,Y)
C
C     THIS FUNCTION ALLOWS THE USER TO INPUT GRAPHICS INFORMATION
C     FROM A TEKTRONIX GRAPHICS TERMINAL TO HIS PROGRAM.  ON ALL
C     TEKTERMINALS OTHER THAN THE PLOTTERS, WHEN IGRNPT IS
C     CALLED, A FULL-SCREEN CROSS-HAIR CURSOR APPEARS.  THE CROSS
C     HAIR MAY BE POSITIONED ON THE SCREEN BY USE OF THE THUMB-
C     WHEELS OR JOYSTICK AS APPROPRIATE.  THE USER CAN CAUSE THE
C     COORDINATES OF THE CROSS HAIR TO BE SENT TO IGRNPT BY EN-
C     TERING A CHARACTER FROM THE KEYBOARD.  THE ASCII CODE FOR
C     THIS CHARACTER IS RETURNED AS THE VALUE OF THE FUNCTION, AND
C     THE COORDINATES IN USER'S UNITS ARE RETURNED IN THE PARAM-
C     ETERS.  ON THE TEKTRONIX PLOTTER, WHEN IGRNPT IS CALLED,
C     THE PROMPT LIGHT (4662) OR POINT LIGHT (4663) IS TURNED ON.
C     IF NECESSARY, THE PEN MAY BE POSITIONED BY USE OF THE JOY-
C     STICK.  THE USER CAN CAUSE THE COORDINATES OF THE PEN TO BE
C     SENT TO IGRNPT BY MOMENTARILY DEPRESSING THE CALL BUTTON
C     (4662) OR A POINT FUNCTION (4663).  THE PEN POSITION (0 =
C     UP, 1 = DOWN) IS RETURNED AS THE VALUE OF THE FUNCTION, AND
C     THE COORDINATES IN USER'S UNITS ARE RETURNED IN THE PARAM-
C     ETERS.
C
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
*	Mods J Davison 3.21.94 for xgks
*	1) Change PET to 3
*	2) Change echo area for xgks coords in GINCH and not call GINLC
* 	*jd* linux port 12.96 change hp -> NEED_IAND for CPP choices

C
C V6.3 *acm* 9/09 Allow mouse clicks in windows other than window 1.
C            Note we get wrong rewults if the plot is in a viewport.
C
        LOGICAL show_menu
	INTEGER window_id
#ifndef core
C
C	GKS DATA FOR CHOICE AND LOCATOR INPUT
C
	INTEGER*4 SIZES(5),PET
	INTEGER*4 ERRIND,MODE,ESW,LDR,ISTAT,ICHOICE
	INTEGER*4 XFORM,WSTYPE,DCUNIT,NULLI
	INTEGER   CHCE(5)
	CHARACTER*10 STRING(5)
	CHARACTER*80 RECORD(10),CONID
	REAL EAREA(4),LOCX,LOCY,WIND(4),VIEW(4),NULLR
#else
	include 'CORECM.INC'
c
	integer initializedevice,setechoposition
	integer setecho,setechosurface
	integer awtbuttongetloc2,terminatedevice
	logical lablin
#endif
	CHARACTER*1 IMODE
	DIMENSION IN(8)
#ifdef unix
	INTEGER*2 T4662N(3),T4662F(3),T4663(6)
#else
	byte INN(8)
	byte T4662N(3),T4662F(3),T4663(6)
#endif
C
#ifdef unix
	include 'PLTCOM.DAT'
        include 'xgrinpt.cmn'
#else
	include 'pplinc:PLTCOM.DAT'
#endif
        integer iwkid
C
#ifndef core
	DATA CHCE/70,76,82,67,32/
#else
	data lablin/.false./
#endif
C
C
C
	DATA T4662N/27,67,75/,T4662F/27,67,76/,
     *  T4663/27,67,65,71,49,59/


CC	Linux port:
	integer octal37

#ifdef FORTRAN_90
	data 	octal37/O'37'/
#else
	data 	octal37/'37'O/
#endif

#ifdef FORTRAN_90
        external XGRINPT_BLKDAT
#else
        DATA has_new_mouse/ .FALSE. /   ! at program initialization
#endif


CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC

C
C     SET ALPHAS MODE.
C
      IMODE = PMODE
      PMODE = ALPHA
C
C     IF THE LAST POINT WAS NOT PLOTTED BECAUSE THE PEN WAS UP,
C     PLOT THE POINT NOW.
C
      IF(SAVEF)CALL XYZPLT
C
C     RESTORE THE CURRENT PLOTTING MODE.
C
      PMODE = IMODE
C
C     CHECK THE PLOT TYPE.
C
	IF(PTYPE.GE.3)THEN
#ifdef core
c	    core device
c
c       locator stuff
c
        istat=initializedevice(LOCATOR,1)
        istat=initializedevice(BUTTON,1)
        istat=initializedevice(BUTTON,2)
        istat=initializedevice(BUTTON,3)
        istat=setechosurface(LOCATOR,1,vsurf)
	if(lablin)then
	    istat=setechoposition(LOCATOR,1,xsv,ysv)
	    istat=setecho(LOCATOR,1,2)
	else
            istat=setecho(LOCATOR,1,1)
	endif
c
        istat=awtbuttongetloc2(100000000,1,ibut,xout,yout)
        istat=awtbuttongetloc2(250000,1,ibut2,xout2,yout2)
        if(ibut2.ne.0.and.(.not.lablin))then
c
c       button pushed twice
c
            lablin=.true.
	    xsv=xout
	    ysv=yout
        else
            lablin=.false.
        endif
	if(bsize/asize .gt. 0.75)then
	    aold=xout*bsize/0.75
	    bold=bsize*yout/0.75
	else
	    aold=asize*xout
	    bold=yout*asize
	endif
	if(lablin)then
	    if(ibut.eq.1)then
		igrnpt=70
	    else
		igrnpt=76
	    endif
	else
	    if(ibut.eq.1)then
		igrnpt=32
	    else if(ibut.eq.2)then
		igrnpt=67
	    else
		igrnpt=82
	    endif
	endif
        istat=terminatedevice(BUTTON,1)
        istat=terminatedevice(BUTTON,2)
        istat=terminatedevice(BUTTON,3)
        istat=terminatedevice(LOCATOR,1)
#else
C
C	    GKS DEVICE
C
	    CALL PPLGFLUSH
	    iwkid = window_id  
	    CALL GQCHS(iwkid,1,10,ERRIND,MODE,ESW,ISTAT,ICHOICE,
     *	    PET,EAREA,LDR,RECORD)
	    STRING(5) = 'Left'
	    STRING(4) = 'Center'
	    STRING(3) = 'Right'
	    STRING(2) = 'Line'
	    STRING(1) = 'Arrow'
	    SIZES(5) = 4
	    SIZES(4) = 6
	    SIZES(3) = 5
	    SIZES(2) = 4
	    SIZES(1) = 5

#ifndef xgks
	    PET = 1
	    EAREA(1)=0.0
	    EAREA(2)=0.1
	    EAREA(3)=0.0
	    EAREA(4)=0.1
#else
            PET = 3
	    EAREA(1)=10.0
	    EAREA(2)=250.0
	    EAREA(3)=10.0
	    EAREA(4)=250.0
#endif
	    LDR=5
	    IRECSZ=10

	    CALL GPREC(0,NULLI,0,NULLR,5,SIZES,STRING,IRECSZ,
     *	    ISTAT,LDR,RECORD)
	    CALL GINCH(iwkid,1,1,5,PET,EAREA(1),EAREA(2),EAREA(3),
     *	    EAREA(4),LDR,RECORD)

        IF (show_menu) THEN     ! **************
	    CALL GRQCH(iwkid,1,ISTAT,ICHOICE)       ! put up menu and get answer
        ELSE
            ichoice = 5         ! always left justified
        ENDIF                   ! **************
	    IGRNPT=CHCE(ICHOICE)
	    CALL GSVPIP(1,0,0)
	    CALL GQLCS(iwkid,1,1,7,ERRIND,MODE,ESW,XFORM,LOCX,LOCY,
     *	    PET,EAREA,LDR,RECORD)
	    PET = 3
	    CALL GQWKC(iwkid,ERRIND,CONID,WSTYPE)
	    CALL GQDSP(WSTYPE,ERRIND,DCUNIT,DCX,DCY,IRSX,IRSY)
	    EAREA(2)=DCX
	    EAREA(4)=DCY

#ifndef xgks
	    CALL GINLC(iwkid,1,XFORM,LOCX,LOCY,PET,EAREA(1),EAREA(2),
     *	    EAREA(3),EAREA(4),LDR,RECORD)
#endif
	    CALL GSLCM(iwkid,1,0,1)
	    CALL GRQLC(iwkid,1,ISTAT,XFORM,LOCX,LOCY)  ! get mouse click (X,Y)
	    CALL GQNT(XFORM,ERRIND,WIND,VIEW)
	    AOLD= LOCX
	    BOLD= LOCY
#endif
	    GOTO 20
	ENDIF
      IF(.NOT.(IABS(PTYPE).EQ.2.OR.PTYPE.EQ.1))RETURN
C
C     CHECK THE TEKTERMINAL TYPE.
C
      IF(TTYPE .EQ. 4006)RETURN
C
C     WRITE OUT THE CHARACTER BUFFER.
C
      IF(TTYPE .EQ. -4662 .OR. TTYPE .EQ. -4663)GO TO 10
C
C     SELECT CROSS-HAIR CURSOR ADDRESS INPUT MODE ON OTHER TEK-
C     TRONIX GRAPHICS TERMINALS AND TURN ON THE CROSS HAIR.
C
        CALL CHOUT(ESC,1)
        CALL CHOUT(26,1)
C
C     READ THE CHARACTER THAT IS ENTERED FROM THE KEYBOARD AND THE
C     FOUR ADDITIONAL CHARACTERS GENERATED BY THE TEKTERMINAL.
C
	CALL CHDMP
#ifdef unix
	call chin(in,5,0)
# ifdef NEED_IAND
       IGRNPT = IAND(IN(1),127)
# else
       IGRNPT = AND(IN(1),127)
# endif
#else
	call chin(inn,5,0)
	do 100 ik=1,5
100	in(ik)=inn(ik)
	igrnpt = iand(in(1),'177'O)
#endif
C
C     CHECK THE TEKTERMINAL TYPE.
C
      IF(TTYPE .LT. 4100 .AND. TTYPE .NE. 4014)THEN
#ifdef unix
# ifdef NEED_IAND
C
C     CALCULATE THE COORDINATES OF THE POINT.  10 BIT TEK401X
C
        AOLD = FLOAT(IOR(ISHFT(IAND(IN(2),octal37),5),IAND(IN(3),octal37)
     *   )) / PLTOTA + AMIN
        BOLD = FLOAT(IOR(ISHFT(IAND(IN(4),octal37),5),IAND(IN(5),octal37)
     *   )) / PLTOTB + BMIN
      ELSE
C
C     CALCULATE THE COORDINATES OF THE POINT.  12 BIT TEK41XX
C
        AOLD = FLOAT(IOR(ISHFT(IAND(IN(2),octal37),7),ISHFT(IAND(IN(3),
     *   octal37),2))) / PLTOTA + AMIN
        BOLD = FLOAT(IOR(ISHFT(IAND(IN(4),octal37),7),ISHFT(IAND(IN(5),
     *   octal37),2))) / PLTOTB + BMIN
# else
C
C     CALCULATE THE COORDINATES OF THE POINT.  10 BIT TEK401X
C
        AOLD = FLOAT(OR(LSHIFT(AND(IN(2),31),5),AND(IN(3),31)
     *   )) / PLTOTA + AMIN
        BOLD = FLOAT(OR(LSHIFT(AND(IN(4),31),5),AND(IN(5),31)
     *   )) / PLTOTB + BMIN
      ELSE
C
C     CALCULATE THE COORDINATES OF THE POINT.  12 BIT TEK41XX
C
        AOLD = FLOAT(OR(LSHIFT(AND(IN(2),31),7),LSHIFT(AND(IN(3),
     *   31),2))) / PLTOTA + AMIN
        BOLD = FLOAT(OR(LSHIFT(AND(IN(4),31),7),LSHIFT(AND(IN(5),
     *   31),2))) / PLTOTB + BMIN
# endif
#else
C
C     CALCULATE THE COORDINATES OF THE POINT.  10 AIT TEK401X
C
        AOLD = FLOAT(IOR(ISHFT(IAND(IN(2),octal37),5),IAND(IN(3),octal37)
     *   )) / PLTOTA + AMIN
        BOLD = FLOAT(IOR(ISHFT(IAND(IN(4),octal37),5),IAND(IN(5),octal37)
     *   )) / PLTOTB + BMIN
      ELSE
C
C     CALCULATE THE COORDINATES OF THE POINT.  12 BIT TEK41XX
C
        AOLD = FLOAT(IOR(ISHFT(IAND(IN(2),octal37),7),ISHFT(IAND(IN(3),
     *   octal37),2))) / PLTOTA + AMIN
        BOLD = FLOAT(IOR(ISHFT(IAND(IN(4),octal37),7),ISHFT(IAND(IN(5),
     *   octal37),2))) / PLTOTB + BMIN
#endif
      ENDIF
      GO TO 20
C
C     CHECK THE GRAPHICS FLAG.
C
   10 IF(.NOT. GRAPHF)THEN
C
C     TRANSMIT THE 'PLOTTER ON' COMMAND TO THE TEKTRONIX PLOTTER.
C
        CALL CHOUT(TEKON,3)
      ENDIF
C
C     CHECK THE TEKTERMINAL TYPE.
C
      IF(TTYPE .EQ. -4662)THEN
C
C     TURN ON THE PROMPT LIGHT ON THE TEKTRONIX 4662 PLOTTER AND
C     READ THE SEVEN CHARACTERS GENERATED BY THE PLOTTER.  THEN
C     TURN OFF THE PROMPT LIGHT.
C
        CALL CHOUT(T4662N,3)
	CALL CHDMP
#ifdef unix
	call chin(in,7,0)
#else
	call chin(inn,7,0)
#endif
        CALL CHOUT(T4662F,3)
      ELSE
C
C     SELECT OPERATOR DIGITIZE MODE ON THE TEKTRONIX 4663 PLOTTER
C     AND READ THE SEVEN CHARACTERS GENERATED BY THE PLOTTER.
C
        CALL CHOUT(T4663,6)
	CALL CHDMP
#ifdef unix
	call chin(in,7,0)
#else
	call chin(inn,7,0)
#endif
      ENDIF
#ifdef unix
#ifdef sun
	igrnpt = rshift(and(in(7),4),2)
#else
# ifdef NEED_IAND
      IGRNPT = ISHFT(IAND(IN(7),4),-2)
# else
      IGRNPT = LSHIFT(AND(IN(7),4),-2)
# endif
#endif
#else
	do 200 ik=1,7
200	in(ik)=inn(ik)
	igrnpt=ishft(iand(in(7),4),-2)	
#endif
C
C     CALCULATE THE COORDINATES OF THE POINT.
C
#ifdef unix
#ifdef sun
      AOLD=FLOAT(OR(OR(LSHIFT(AND(IN(1),31),7),LSHIFT(AND(IN(3),
     * 31),2)),rSHIFT(AND(IN(5),31),3))) / PLTOTA + AMIN
      BOLD=FLOAT(OR(OR(LSHIFT(AND(IN(2),31),7),LSHIFT(AND(IN(4),
     * 31),2)),rSHIFT(AND(IN(6),31),3))) / PLTOTB + BMIN
#else
# ifdef NEED_IAND 
      AOLD=FLOAT(IOR(IOR(ISHFT(IAND(IN(1),octal37),7),ISHFT(IAND(IN(3),
     * octal37),2)),ISHFT(IAND(IN(5),octal37),-3))) / PLTOTA + AMIN
      BOLD=FLOAT(IOR(IOR(ISHFT(IAND(IN(2),octal37),7),ISHFT(IAND(IN(4),
     * octal37),2)),ISHFT(IAND(IN(6),octal37),-3))) / PLTOTB + BMIN
# else
      AOLD=FLOAT(OR(OR(LSHIFT(AND(IN(1),31),7),LSHIFT(AND(IN(3),
     * 31),2)),LSHIFT(AND(IN(5),31),-3))) / PLTOTA + AMIN
      BOLD=FLOAT(OR(OR(LSHIFT(AND(IN(2),31),7),LSHIFT(AND(IN(4),
     * 31),2)),LSHIFT(AND(IN(6),31),-3))) / PLTOTB + BMIN
# endif
#endif
#else
      AOLD=FLOAT(IOR(IOR(ISHFT(IAND(IN(1),octal37),7),ISHFT(IAND(IN(3),
     * octal37),2)),ISHFT(IAND(IN(5),octal37),-3))) / PLTOTA + AMIN
      BOLD=FLOAT(IOR(IOR(ISHFT(IAND(IN(2),octal37),7),ISHFT(IAND(IN(4),
     * octal37),2)),ISHFT(IAND(IN(6),octal37),-3))) / PLTOTB + BMIN
C
#endif
C
C     TRANSMIT THE 'PLOTTER OFF' COMMAND TO THE TEKTRONIX PLOTTER.
C
      CALL CHOUT(TEKOFF,5)
C
C     TRANSFORM THE POINT TO THE USER'S COORDINATE SYSTEM.
C
   20 CALL TFORMI(XNEW,YNEW,ZNEW)
      PENF = .FALSE.
      SAVEF = .TRUE.
      X = XNEW / XSCALE
      Y = YNEW / YSCALE
* ACM * How to detect if the plot is in a viewport and 
*       therefore if the mouse click was outside the 
*       viewport, the results of the mouse-click are
*       garbage ??  This is not quite it...
c      IF (AOLD.LT.1 .OR. BOLD.LT.1) THEN
c         X = -1.0E+34
c	 Y = -1.0E+34
c      ENDIF

* 6/99 send the results back to Ferret through COMMON
        has_new_mouse = .TRUE.
        xmouse = x
        ymouse = y
	wmouse = iwkid

C
C     RESET THE GRAPHICS FLAG.
C
      GRAPHF = .FALSE.
C
C     CHECK THE PLOTTING MODE.
C
      IF(PMODE .EQ. ALPHA)CALL ALPHAS
      RETURN
C
      END





