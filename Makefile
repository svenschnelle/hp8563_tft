DESIGN=top
#TARGET=xcr3256xl-7-tq144
TARGET=xc3s500e-4-fg320
INTSTYLE=-intstyle silent

PROMGENFLAGS=-w -p mcs -c FF
MAPFLAGS=-cm area -pr b -c 100
NGDFLAGS=-nt timestamp -uc src/$(DESIGN).ucf -dd build
PARFLAGS=-w -ol std -t 1

FILES=$(wildcard src/*.vhdl)
SIMFILES=$(wildcard sim/*.vhdl)

.PHONY: sim mkbuilddir

all: build/$(DESIGN).mcs

sim: $(DESIGN)_tb.ghw
		gtkwave ./$(DESIGN)_tb.ghw sim/$(DESIGN)_tb.sav

build/$(DESIGN).mcs:		build/$(DESIGN).bit
		promgen $(PROMGENFLAGS) -o $@ -u 0 $< -s 4096

build/$(DESIGN).bit:		build/$(DESIGN)_par.ncd
		bitgen -w $< $@

build/$(DESIGN)_par.ncd:	build/$(DESIGN).ncd
		par $(PARFLAGS) $< $@

build/$(DESIGN).ncd:		build/$(DESIGN).ngd
		map -p $(TARGET) $(MAPFLAGS) -o $@ $<
		#cpldfit -p $(TARGET) $(CPLDFITFLAGS) $<
build/$(DESIGN).ngd:		build/$(DESIGN).ngc src/$(DESIGN).ucf
		ngdbuild -p $(TARGET) $(NGDFLAGS) $< $@

build/$(DESIGN).xst:  build/$(DESIGN).prj Makefile
		echo "run\n-ifn build/$(DESIGN).prj\n-ifmt mixed\n-top $(DESIGN)\n-ofn build/$(DESIGN)\n-ofmt NGC\n-p $(TARGET)\n-opt_mode Speed\n-opt_level 1\n" >$@

build/$(DESIGN).ngc:  $(FILES) Makefile build/$(DESIGN).xst
		xst -ifn build/$(DESIGN).xst

build/$(DESIGN).prj:
		mkdir -p build
		rm -f build/$(DESIGN).prj
		ls src/*.vhdl|sed 's/^/vhdl work /' >> build/$(DESIGN).prj

clean:
		rm -rf build work xst unisim netlist.lst settings.srp $(DESIGN).lso $(DESIGN)_map.xrpt $(DESIGN)_par.xrpt $(DESIGN).srp flashsim_tb output.txt xilinx_device_details.xml _xmsgs xlnx_auto_*xdb $(DESIGN)_tb.ghw

download:	build/$(DESIGN).bit
		xc3sprog $<

$(DESIGN)_tb.ghw:	$(FILES) $(SIMFILES) Makefile
		rm -rf work unisim
		mkdir -p work unisim
		ghdl -i --work=unisim --workdir=unisim $(XILINX)/vhdl/src/unisims/*.vhd
		ghdl -i --work=unisim --workdir=unisim $(XILINX)/vhdl/src/unisims/primitive/*.vhd
		ghdl -i -g --workdir=work src/*.vhdl sim/*.vhdl
		ghdl -m -g -Punisim -fexplicit --workdir=work --ieee=synopsys $(DESIGN)_tb
		ghdl -r $(DESIGN)_tb  --stop-time=10us --wave=$@ --stack-size=100000000
