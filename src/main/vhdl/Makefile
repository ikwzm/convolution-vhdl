ENTITY_FILES = conv_int_adder_tree.vhd                 \
               ${ENDLIST}

components.vhd : ${ENTITY_FILES}
	../../../PipeWork/tools/MakeComponentPackage.rb --verbose \
            --brief   'CONVOLUTION COMPONENT LIBRARY DESCRIPTION' \
            --version 0.1.0 \
            --author  'Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>' \
            --library CONVOLUTION \
            --package COMPONENTS \
            --output  components.vhd \
            ${ENTITY_FILES}

clean:
	-rm components.vhd
