#
# Makefile for Ferret External Functions
#
# January 20 1998
# Jonathan Callahan
#
#  15-Nov-1999 Ansley Manke  
#  remove refs to ef_utility/*.o  (now in ferret executable)
#
#  ACM 2/2001  debug macros 
#
# include platform specific macro definitions
#

include ../ef_utility/site_specific.mk
include ../ef_utility/platform_specific.mk.$(BUILDTYPE)

#
# Macros
#

.SUFFIXES: .so

#
# Rules
#

.F.so:
	$(FC) $(FFLAGS) -c $<
	$(LD) $(LD_DYN_FLAGS) $*.o -o $*.so 

#
# Targets
#

# all:	zaxreplace_avg.so zaxreplace_bin.so zaxreplace_lin.so zaxreplace_zlev.so zaxreplace_rev.so
all:	zaxreplace_xyt.so zaxreplace_lin.so  eaxreplace_lin.so  taxreplace_lin.so 

debug:
	$(MAKE) "FFLAGS = $(FFLAGS) $(FFLAGS_DEBUG)" "CFLAGS = $(CFLAGS) $(CFLAGS_DEBUG)" all

install:
	cp *.so $(FER_LOCAL_EXTFCNS)

clean:
	-rm -f *.o *.so

#
# End of Makefile
#
