/*
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
*/



/* Set background color in XGKS.  Callable from FORTRAN.  
 * Values passed are ws id and color index.
 * J Davison 1.11.94
 */

/* Changed include order of gks_implem.h to remove errors in compile (set 
 * **before** stdlib.h) for linux port *jd* 1.28.97
 *
 * Check to make sure display is actually set to avoid crashes in
 * -gif mode *js* 5.99
 */

/* *kob* 10/03 v553 - gcc v3.x needs wchar.h included */

#include <wchar.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "udposix.h"
#include "gks_implem.h"
#include "pplmem.h"

void FORTRAN(set_background)(int *ws_id, int *ndx)
{
  WS_STATE_ENTRY *ws;
  int             scr;

/****************************************************************************/

  ws  = OPEN_WSID (*ws_id);
  if (ws && ws->dpy){
    scr = DefaultScreen (ws->dpy);

    if (*ndx == 0)
      XSetWindowBackground (ws->dpy,ws->win,BlackPixel(ws->dpy,scr));
    else
      XSetWindowBackground (ws->dpy,ws->win,WhitePixel(ws->dpy,scr));
  }
}

