
WORK                 = CONVOLUTION
SRC_PATH             = ../../../src
DUMMY_PLUG_SRC_PATH  = ../../../Dummy_Plug/src/main/vhdl
PIPEWORK_SRC_PATH    = ../../../PipeWork/src/
DUMMY_PLUG_WORK_PATH = ./dummy_plug/
PIPEWORK_WORK_PATH   = ./pipework/
VHDL_SRC_PATH        = $(SRC_PATH)/main/vhdl
SCENARIO_PATH        = $(SRC_PATH)/test/scenarios/image_window_buffer


GHDL       = ghdl
GHDLFLAGS  = --mb-comments -P$(DUMMY_PLUG_WORK_PATH) -P$(PIPEWORK_WORK_PATH) 

all:  conv_types.o conv_int_adder.o conv_int_adder_tree.o conv_int_accumulator.o conv_int_multiplier.o conv_components.o conv_int_core.o

pipework   : $(PIPEWORK_WORK_PATH)/pipework-obj93.cf

$(PIPEWORK_WORK_PATH)/pipework-obj93.cf :
	@if [ ! -d $(PIPEWORK_WORK_PATH) ]; \
	    then echo "mkdir -p $(PIPEWORK_WORK_PATH)"; mkdir -p $(PIPEWORK_WORK_PATH); \
	fi
	../../../PipeWork/tools/vhdl-archiver.rb \
            --library PIPEWORK \
            --use_entity 'QUEUE_ARBITER(INTEGER_ARCH)' \
            --use_entity 'SDPRAM(MODEL)' \
            --execute '$(GHDL) -a $(GHDLFLAGS) --work=#{library_name} --workdir=$(PIPEWORK_WORK_PATH) #{file_name}' \
            $(PIPEWORK_SRC_PATH)

dummy_plug : $(DUMMY_PLUG_WORK_PATH)/dummy_plug-obj93.cf

$(DUMMY_PLUG_WORK_PATH)/dummy_plug-obj93.cf :
	@if [ ! -d $(DUMMY_PLUG_WORK_PATH) ]; \
	    then echo "mkdir -p $(DUMMY_PLUG_WORK_PATH)"; mkdir -p $(DUMMY_PLUG_WORK_PATH); \
	fi
	../../../PipeWork/tools/vhdl-archiver.rb \
	    --library DUMMY_PLUG \
	    --exclude $(DUMMY_PLUG_SRC_PATH)/core/sync_alt.vhd \
	    --exclude $(DUMMY_PLUG_SRC_PATH)/axi4/axi3_signal_printer.vhd \
	    --execute '$(GHDL) -a $(GHDLFLAGS) --work=#{library_name} --workdir=$(DUMMY_PLUG_WORK_PATH) #{file_name}' \
	    $(DUMMY_PLUG_SRC_PATH)


clean:
	rm -f *.o *.cf $(TEST_BENCH)
	rm -rf ./dummy_plug/ ./pipework/

conv_types.o                : $(VHDL_SRC_PATH)/conv_types.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

conv_components.o           : $(VHDL_SRC_PATH)/conv_components.vhd conv_types.o pipework
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

conv_int_adder.o            : $(VHDL_SRC_PATH)/conv_int_adder.vhd      conv_types.o pipework
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

conv_int_adder_tree.o       : $(VHDL_SRC_PATH)/conv_int_adder_tree.vhd conv_types.o pipework
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

conv_int_accumulator.o      : $(VHDL_SRC_PATH)/conv_int_accumulator.vhd conv_types.o pipework
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

conv_int_multiplier.o       : $(VHDL_SRC_PATH)/conv_int_multiplier.vhd  conv_types.o pipework
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

conv_int_core.o             : $(VHDL_SRC_PATH)/conv_int_core.vhd  conv_types.o pipework
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

