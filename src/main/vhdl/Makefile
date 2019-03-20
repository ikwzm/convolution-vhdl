
ENTITY_FILES = conv_int_adder.vhd               \
               conv_int_adder_tree.vhd          \
               conv_int_accumulator.vhd         \
               conv_int_multiplier.vhd          \
               conv_int_core.vhd                \
               conv_parameter_buffer_writer.vhd \
               conv_parameter_buffer_reader.vhd \
               conv_parameter_buffer.vhd        \
               ${ENDLIST}

conv_components.vhd : ${ENTITY_FILES}
	../../../PipeWork/tools/MakeComponentPackage.rb --verbose \
            --brief   'CONVOLUTION COMPONENT LIBRARY DESCRIPTION' \
            --version 0.1.0 \
            --author  'Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>' \
            --library CONVOLUTION \
            --package CONV_COMPONENTS \
            --output  conv_components.vhd \
            ${ENTITY_FILES}

clean:
	-rm conv_components.vhd
