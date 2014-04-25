
PREFIX=ut_vga
TOPMOD=main

all: bit

synthesize:
	@echo " - [1/5] Synthesize"
	@mkdir -p xst/projnav.tmp
	@cp make_xst $(PREFIX).xst
	@cp make_prj $(PREFIX).prj
	@xst -ifn $(PREFIX).xst -ofn $(PREFIX).syr > log-1-synthesize

translate: synthesize
	@echo " - [2/5] Translate"
	@ngdbuild -dd _ngo -nt timestamp -uc ek-miniterm-r02.ucf -p xc3s250e-vq100-4 $(TOPMOD).ngc $(PREFIX).ngd > log-2-translate

map: translate
	@echo " - [3/5] Map"
	@map -intstyle ise -p xc3s250e-vq100-4 -cm area -ir off -pr off -c 100 -o $(PREFIX)_map.ncd $(PREFIX).ngd $(PREFIX).pcf > log-3-map

route: map
	@echo " - [4/5] Place and Route"
	@par -w -intstyle ise -ol high -t 1 $(PREFIX)_map.ncd $(PREFIX).ncd $(PREFIX).pcf > log-4-route

bit: route
	@echo " - [5/5] Bitsream"
	@bitgen -w $(PREFIX).ncd $(PREFIX).bit > log-5-bitgen

clean:
	rm -f *~ log-?-* *.log
	rm -f *_bd.bmm *.bit
	rm -f *.bgn *.bld *.ncd *.cmd_log *.drc *.html *.ncd *.lso *_map.*
	rm -f *.ngc *.ngd *.ngr *.pad *_pad.* *.par *_par.* *.pcf *.ptwx
	rm -f *.prj *.unroutes *.stx *.syr *.xpi *.xwbt *.xrpt *.xml *.xst
	rm -rf xst/ _xmsgs/ _ngo/ xlnx_auto_0_xdb/
