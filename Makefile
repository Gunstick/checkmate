#!/usr/bin/make -f
#


.s:
	#vasmm68k_mot -Ftos -pic -align -devpac -m68000 -showopt -nosym -o $@.tos $< 
	vasmm68k_mot -Ftos -align -devpac -m68000 -showopt -nosym -o $@.tos $< 
	#	./mktruerel.sh $@.tos 
.o:
	vlink $<

