
WORK                  := WORK
SRC_PATH              := ../../../src
DUMMY_PLUG_SRC_PATH   := ../../../Dummy_Plug/src/main/vhdl
PIPEWORK_SRC_PATH     := ../../../PipeWork/src/
CONVOLUTION_SRC_PATH  := ../../../src/main/vhdl/
DUMMY_PLUG_WORK_PATH  := ./dummy_plug/
PIPEWORK_WORK_PATH    := ./pipework/
CONVOLUTION_WORK_PATH := ./convolution/
VHDL_SRC_PATH         := $(SRC_PATH)/test/vhdl
SCENARIO_PATH         := $(SRC_PATH)/test/scenarios/conv_parameter_buffer

GHDL                  := ghdl
GHDLFLAGS             := --mb-comments -P$(DUMMY_PLUG_WORK_PATH) -P$(PIPEWORK_WORK_PATH) -P$(CONVOLUTION_WORK_PATH) 

TEST_BENCH            := conv_parameter_buffer_test_bench_1x1x1x1   \
                         conv_parameter_buffer_test_bench_1x1x1x1_1x1x1x1 \
                         conv_parameter_buffer_test_bench_1x1x1x4   \
                         conv_parameter_buffer_test_bench_1x1x2x4   \
                         conv_parameter_buffer_test_bench_3x3x1x1   \
                         conv_parameter_buffer_test_bench_3x3x2x4   \
                         $(END_LIST)

.PHONY all: $(TEST_BENCH)

conv_parameter_buffer_test_bench_1x1x1x1         : conv_parameter_buffer_test_bench.o test_1x1x1x1.snr
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

conv_parameter_buffer_test_bench_1x1x1x1_1x1x1x1 : conv_parameter_buffer_test_bench.o test_1x1x1x1_1x1x1x1.snr
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

conv_parameter_buffer_test_bench_1x1x1x4         : conv_parameter_buffer_test_bench.o test_1x1x1x4.snr
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

conv_parameter_buffer_test_bench_1x1x2x4         : conv_parameter_buffer_test_bench.o test_1x1x2x4.snr
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

conv_parameter_buffer_test_bench_3x3x1x1         : conv_parameter_buffer_test_bench.o test_3x3x1x1.snr
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

conv_parameter_buffer_test_bench_3x3x2x4         : conv_parameter_buffer_test_bench.o test_3x3x2x4.snr
	$(GHDL) -e $(GHDLFLAGS) --work=WORK $@
	$(GHDL) -r $(GHDLFLAGS) --work=WORK $@

test_1x1x1x1.snr         : $(SCENARIO_PATH)/test_1x1x1x1.snr
	cp $< $@

test_1x1x1x1_1x1x1x1.snr : $(SCENARIO_PATH)/test_1x1x1x1_1x1x1x1.snr
	cp $< $@

test_1x1x1x4.snr         : $(SCENARIO_PATH)/test_1x1x1x4.snr
	cp $< $@

test_1x1x2x4.snr         : $(SCENARIO_PATH)/test_1x1x2x4.snr
	cp $< $@

test_3x3x1x1.snr         : $(SCENARIO_PATH)/test_3x3x1x1.snr
	cp $< $@

test_3x3x2x4.snr         : $(SCENARIO_PATH)/test_3x3x2x4.snr
	cp $< $@

convolution: $(CONVOLUTION_WORK_PATH)/convolution-obj93.cf

$(CONVOLUTION_WORK_PATH)/convolution-obj93.cf :
	@if [ ! -d $(CONVOLUTION_WORK_PATH) ]; \
	    then echo "mkdir -p $(CONVOLUTION_WORK_PATH)"; mkdir -p $(CONVOLUTION_WORK_PATH); \
	fi
	../../../PipeWork/tools/vhdl-archiver.rb \
            --library CONVOLUTION \
            --execute '$(GHDL) -a $(GHDLFLAGS) --work=#{library_name} --workdir=$(CONVOLUTION_WORK_PATH) #{file_name}' \
            $(CONVOLUTION_SRC_PATH)

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
	rm -rf ./dummy_plug/ ./pipework/ ./convolution/

analyze: pipework dummy_plug convolution image_stream_models.o image_stream_player.o image_stream_slave_player.o conv_parameter_buffer_test_bench.o

image_stream_models.o           : $(VHDL_SRC_PATH)/image_stream_models/image_stream_models.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

image_stream_player.o           : $(VHDL_SRC_PATH)/image_stream_models/image_stream_player.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

image_stream_slave_player.o     : $(VHDL_SRC_PATH)/image_stream_models/image_stream_slave_player.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<

conv_parameter_buffer_test_bench.o : $(VHDL_SRC_PATH)/conv_parameter_buffer/conv_parameter_buffer_test_bench.vhd
	$(GHDL) -a $(GHDLFLAGS) --work=$(WORK) $<
