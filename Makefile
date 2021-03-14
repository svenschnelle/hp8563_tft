DESIGN=top
TARGET=xc3s500e-4pq208
#TARGET=XC6SLX9-2TQG144
#TARGET=xc6slx16-2ftg256
INTSTYLE=-intstyle silent

PROMGENFLAGS=-w -spi -p mcs -c FF
MAPFLAGS=-w -pr b -c 100 -t 1
NGDFLAGS=-nt timestamp -uc src/$(DESIGN).ucf -dd build
PARFLAGS=-w -ol std
FILES=$(wildcard src/*.vhdl)
GHDL=/opt/ghdl/bin/ghdl
GHDL_FLAGS=-fsynopsys

SIMFILES=sim/test.vhdl

.PHONY: sim mkbuilddir

all: download

sim: $(DESIGN)_tb.ghw
		gtkwave work/$(DESIGN).ghw sim/$(DESIGN)_tb.sav

build/$(DESIGN).mcs:		build/$(DESIGN).bit
		promgen $(PROMGENFLAGS) -o $@ -u 0 $< -s 1024

build/$(DESIGN).bit:		build/$(DESIGN)_par.ncd
		bitgen -w $< $@

build/$(DESIGN)_par.ncd:	build/$(DESIGN).ncd
		par $(PARFLAGS) $< $@

build/$(DESIGN).ncd:		build/$(DESIGN).ngd
		map -p $(TARGET) $(MAPFLAGS) -o $@ $<

build/$(DESIGN).ngd:		build/$(DESIGN).ngc src/$(DESIGN).ucf
		ngdbuild -p $(TARGET) $(NGDFLAGS) $< $@

build/$(DESIGN).xst:  build/$(DESIGN).prj Makefile
		/bin/echo -e "run\n-ifn build/$(DESIGN).prj\n-ifmt mixed\n-top $(DESIGN)\n-ofn build/$(DESIGN)\n-ofmt NGC\n-p $(TARGET)\n-opt_mode Area\n-opt_level 2\n" >$@

build/$(DESIGN).ngc:  $(FILES) Makefile build/$(DESIGN).xst
		xst -ifn build/$(DESIGN).xst

build/$(DESIGN).jed: build/$(DESIGN).ncd
		hprep6 -i top

build/$(DESIGN).prj:
		mkdir -p build
		rm -f build/$(DESIGN).prj
		ls src/*.vhdl|sed 's/^/vhdl work /' >> build/$(DESIGN).prj

clean:
		rm -rf build work xst unisim netlist.lst top.*\
		$(DESIGN)_map.xrpt $(DESIGN)_par.xrpt \
		flashsim_tb output.txt xilinx_device_details.xml _xmsgs xlnx_auto_*xdb \
		$(DESIGN)_build.xml $(DESIGN)_pad.csv

download:	build/$(DESIGN).bit
		xc3sprog $<

$(DESIGN)_tb.ghw:	$(FILES) $(SIMFILES) Makefile
		rm -rf work unisim
		mkdir -p work unisim
		$(GHDL) -a $(GHDL_FLAGS) $(FILES)
#		$(GHDL) -a $(GHDL_FLAGS) -fsynopsys $(SIMFILES_SYNOPSYS)
		$(GHDL) -a $(GHDL_FLAGS) -fsynopsys $(SIMFILES)
		$(GHDL) -r $(DESIGN)_tb --stop-time=1ms --wave=work/$(DESIGN).ghw --assert-level=note

charcopy_tb.ghw:	$(FILES) $(SIMFILES) Makefile
			rm -rf work unisim
			mkdir -p work unisim
			$(GHDL) -a --std=08 -fsynopsis sim/package_timing.vhdl
			$(GHDL) -a -fsynopsis  sim/package_utility.vhdl
			$(GHDL) -a --std=08 -fsynopsis  sim/16M_Async_SRAM.vhdl
			$(GHDL) -a -fsynopsis sim/charcopy_tb.vhdl
			$(GHDL) -a -fsynopsis sim/test_tb.vhdl
			$(GHDL) -c -g --workdir=work  src/*.vhdl -r charcopy_tb --stop-time=1000us --wave=work/charcopy_tb.ghw
			gtkwave work/$@ sim/$@.sav

download: build/$(DESIGN).bit
	impact -batch impact.scr
