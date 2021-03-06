	subroutine inside(x,y,xb,yb,nb,ind) 
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
C**    @(#)inside.f	1.1    3/10/88
C**
C**
C***********************************************************************
C**
C**                 PLOT+ Scientific Graphics System
C**
C***********************************************************************
C**
C**
c     given a point x,y and the series xb(k),yb(k) (k=1...nb) defining 
c     vertices of a closed polygon.  ind is set to 1 if the point is in 
c     the polygon and 0 if outside.  each time a new set of bound points 
c     is introduced ind should be set to 999 on input. 
c     it is best to do a series of y for a single fixed x. 
c     method ... a count is made of the no. of times the boundary cuts 
c     the meridian thru (x,y) south of (x,y).   an odd count indicates 
c     the point is inside , even indicates outside. 
c     see a long way from euclid by constance reid  p 174 . 
c     oceanography emr   oct/69 
c 
	dimension xb(2),yb(2),yc(20) 
	if(nb)10,10,20 
10	ind=1 
	return 
20	if(ind-999)30,40,30 
30	if(x-xprev)40,300,40 
c 
40	xprev=x 
	nc=0 
	do 200 k=1,nb 
	kp1=k+1-k*(k/nb) 
	kw=k 
	if(xb(k)-xb(kp1))60,200,50 
50	kw=kp1 
60	ke=k+kp1-kw 
	if(x-xb(ke))80,90,200 
80	if(x-xb(kw))200,200,90 
90	nc=nc+1 
	slope=(yb(ke)-yb(kw))/(xb(ke)-xb(kw)) 
	yc(nc)=yb(kw)+(x-xb(kw))*slope 
200	continue 
c 
300	ind=0 
	if(nc)340,340,310 
310	do 330 k=1,nc 
	if(yc(k)-y)320,330,330 
320	ind=1-ind 
330	continue 
340	return 
	end 
