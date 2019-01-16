CONV_INT_ENTITY_FILES = conv_int_adder.vhd       \
                        conv_int_adder_tree.vhd  \
                        conv_int_accumulator.vhd \
                        ${ENDLIST}

conv_int_components.vhd : ${CONV_INT_ENTITY_FILES}
	../../../PipeWork/tools/MakeComponentPackage.rb --verbose \
            --brief   'CONVOLUTION INTEGER COMPONENT LIBRARY DESCRIPTION' \
            --version 0.1.0 \
            --author  'Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>' \
            --library CONVOLUTION \
            --package CONV_INT_COMPONENTS \
            --output  conv_int_components.vhd \
            ${CONV_INT_ENTITY_FILES}

clean:
	-rm conv_int_components.vhd
