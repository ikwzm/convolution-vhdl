-----------------------------------------------------------------------------------
--!     @file    conv_input_buffer.vhd
--!     @brief   Convolution Input Buffer Module
--!     @version 0.1.0
--!     @date    2019/1/24
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
-----------------------------------------------------------------------------------
--
--      Copyright (C) 2019 Ichiro Kawazome
--      All rights reserved.
--
--      Redistribution and use in source and binary forms, with or without
--      modification, are permitted provided that the following conditions
--      are met:
--
--        1. Redistributions of source code must retain the above copyright
--           notice, this list of conditions and the following disclaimer.
--
--        2. Redistributions in binary form must reproduce the above copyright
--           notice, this list of conditions and the following disclaimer in
--           the documentation and/or other materials provided with the
--           distribution.
--
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
library CONVOLUTION;
use     CONVOLUTION.CONV_TYPES.all;
-----------------------------------------------------------------------------------
--! @brief Convolution Input Buffer Module
-----------------------------------------------------------------------------------
entity  CONV_INTPUT_BUFFER is
    generic (
        I_PARAM         : --! @brief INPUT  IMAGE STREAM PARAMETER :
                          --! 入力側のイメージストリームのパラメータを指定する.
                          --! I_PARAM.ELEM_SIZE    = O_PARAM.ELEM_SIZE    でなければならない.
                          IMAGE_STREAM_PARAM_TYPE  := NEW_IMAGE_STREAM_PARAM(8,1,1,1);
        O_PARAM         : --! @brief OUTPUT PIPELINE DATA PARAMETER :
                          --! パイプラインデータ出力ポートのパラメータを指定する.
                          CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,1,1,1,1);
        ELEMENT_SIZE    : --! @brief ELEMENT SIZE :
                          --! 列方向の要素数を指定する.
                          integer := 256;
        CHANNEL_SIZE    : --! @brief CHANNEL SIZE :
                          --! チャネル数を指定する.
                          --! チャネル数が可変の場合は 0 を指定する.
                          integer := 0;
        MAX_D_SIZE      : --! @brief MAX OUTPUT CHANNEL SIZE :
                          integer := 1
    );
    port (
    -------------------------------------------------------------------------------
    -- クロック&リセット信号
    -------------------------------------------------------------------------------
        CLK             : --! @brief CLOCK :
                          --! クロック信号
                          in  std_logic; 
        RST             : --! @brief ASYNCRONOUSE RESET :
                          --! 非同期リセット信号.アクティブハイ.
                          in  std_logic;
        CLR             : --! @brief SYNCRONOUSE RESET :
                          --! 同期リセット信号.アクティブハイ.
                          in  std_logic;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
        D_SIZE          : --! @brief OUTPUT CHANNEL SIZE :
                          in  integer range 0 to MAX_D_SIZE := 1;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA          : --! @brief INPUT IMAGE STREAM DATA :
                          --! イメージストリームデータ入力.
                          in  std_logic_vector(I_PARAM.DATA.SIZE-1 downto 0);
        I_VALID         : --! @brief INPUT IMAGE STREAM DATA VALID :
                          --! 入力イメージストリームデータ有効信号.
                          --! * I_DATAが有効であることを示す.
                          --! * I_VALID='1'and I_READY='1'でイメージストリームデー
                          --!   タがキューに取り込まれる.
                          in  std_logic;
        I_READY         : --! @brief INPUT IMAGE STREAM DATA READY :
                          --! 入力イメージストリームデータレディ信号.
                          --! * キューが次のイメージストリームデータを入力出来るこ
                          --!   とを示す.
                          --! * I_VALID='1'and I_READY='1'でイメージストリームデー
                          --!   タがキューに取り込まれる.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA          : --! @brief OUTPUT CONVOLUTION PIPELINE DATA :
                          --! パイプラインデータ出力.
                          out std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
        O_VALID         : --! @brief OUTPUT CONVOLUTION PIPELINE DATA VALID :
                          --! 出力パイプラインデータ有効信号.
                          --! * O_DATA が有効であることを示す.
                          --! * O_VALID='1'and O_READY='1'でパイプラインデータが
                          --!   キューから取り除かれる.
                          out std_logic;
        O_READY         : --! @brief OUTPUT CONVOLUTION PIPELINE DATA READY :
                          --! 出力パイプラインデータレディ信号.
                          --! * キューから次のパイプラインデータを取り除く準備が出
                          --!   来ていることを示す.
                          --! * O_VALID='1'and O_READY='1'でパイプラインデータが
                          --!   キューから取り除かれる.
                          in  std_logic
    );
end CONV_INTPUT_BUFFER;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
use     PIPEWORK.IMAGE_COMPONENTS.IMAGE_STREAM_BUFFER;
library CONVOLUTION;
use     CONVOLUTION.CONV_TYPES.all;
architecture RTL of CONV_INTPUT_BUFFER is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  OUTLET_IMAGE_PARAM    :  IMAGE_STREAM_PARAM_TYPE
                                    := NEW_IMAGE_STREAM_PARAM(
                                          ELEM_BITS    => O_PARAM.ELEM_BITS,
                                          SHAPE        => NEW_IMAGE_STREAM_SHAPE_PARAM(
                                                              C => NEW_IMAGE_VECTOR_RANGE(
                                                                       LO => O_PARAM.SHAPE.C.LO,
                                                                       HI => O_PARAM.SHAPE.C.HI
                                                                   ),
                                                              X => NEW_IMAGE_VECTOR_RANGE(
                                                                       LO => O_PARAM.SHAPE.X.LO,
                                                                       HI => O_PARAM.SHAPE.X.HI
                                                                   ),
                                                              Y => NEW_IMAGE_VECTOR_RANGE(
                                                                       LO => O_PARAM.SHAPE.Y.LO,
                                                                       HI => O_PARAM.SHAPE.Y.HI
                                                                   )
                                                          ),
                                          STRIDE       => NEW_IMAGE_STREAM_STRIDE_PARAM(
                                                              X => O_PARAM.STRIDE.X,
                                                              Y => O_PARAM.STRIDE.Y
                                                          )
                                      );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    outlet_data           :  std_logic_vector(OUTLET_IMAGE_PARAM.DATA.SIZE-1 downto 0);
    signal    outlet_d_atrb         :  IMAGE_STREAM_ATRB_VECTOR(0 to O_PARAM.SHAPE.D.SIZE-1);
    signal    outlet_valid          :  std_logic;
    signal    outlet_ready          :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    BUF: IMAGE_STREAM_BUFFER                         -- 
        generic map (                                -- 
            I_PARAM         => I_PARAM             , -- 
            O_PARAM         => OUTLET_IMAGE_PARAM  , --   
            ELEMENT_SIZE    => ELEMENT_SIZE        , --   
            CHANNEL_SIZE    => CHANNEL_SIZE        , --   
            MAX_D_SIZE      => MAX_D_SIZE          , --   
            D_STRIDE        => 1                   , --   
            D_UNROLL        => O_PARAM.SHAPE.D.SIZE, --   
            BANK_SIZE       => 0                   , --   
            LINE_SIZE       => 0                   , --   
            ID              => 0                     --   
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- クロック&リセット信号
        ---------------------------------------------------------------------------
            CLK             => CLK                 , --   
            RST             => RST                 , --   
            CLR             => CLR                 , --   
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
            D_SIZE          => D_SIZE              , --   
        ---------------------------------------------------------------------------
        -- 入力側 I/F
        ---------------------------------------------------------------------------
            I_DATA          => I_DATA              , --   
            I_VALID         => I_VALID             , --   
            I_READY         => I_READY             , --   
        ---------------------------------------------------------------------------
        -- 出力側 I/F
        ---------------------------------------------------------------------------
            O_FEED          => '1'                 , --   
            O_RETURN        => '0'                 , --   
            O_DATA          => outlet_data         , --   
            O_D_ATRB        => outlet_d_atrb       , --   
            O_VALID         => outlet_valid        , --   
            O_READY         => outlet_ready          --   
    );
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (outlet_data, outlet_d_atrb)
        variable  data :  std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
        variable  elem :  std_logic_vector(O_PARAM.ELEM_BITS-1 downto 0);
        procedure set_conv_pipeline_atrb(
                      I_ATRB_VEC   :  in    IMAGE_STREAM_ATRB_VECTOR;
                      I_ATRB_START :  in    boolean;
                      I_ATRB_LAST  :  in    boolean;
                      O_PARAM      :  in    CONV_PIPELINE_PARAM_TYPE;
                      O_ATRB_FIELD :  in    CONV_DATA_ATRB_FIELD_TYPE;
            variable  O_DATA       :  inout std_logic_vector)
        is 
        begin
            if (I_ATRB_START = TRUE) then
                O_DATA(O_ATRB_FIELD.START_POS) := '1';
            else
                O_DATA(O_ATRB_FIELD.START_POS) := '0';
            end if;
            if (I_ATRB_LAST  = TRUE) then
                O_DATA(O_ATRB_FIELD.LAST_POS ) := '1';
            else
                O_DATA(O_ATRB_FIELD.LAST_POS ) := '0';
            end if;
            for pos in I_ATRB_VEC'range loop
                if (I_ATRB_VEC(pos).VALID = TRUE) then
                    O_DATA(O_ATRB_FIELD.VALID.LO + pos - I_ATRB_VEC'low) := '1';
                else
                    O_DATA(O_ATRB_FIELD.VALID.LO + pos - I_ATRB_VEC'low) := '0';
                end if;
            end loop;
        end procedure;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        for y_pos in 0 to O_PARAM.SHAPE.Y.SIZE-1 loop
        for x_pos in 0 to O_PARAM.SHAPE.X.SIZE-1 loop
        for d_pos in 0 to O_PARAM.SHAPE.D.SIZE-1 loop
        for c_pos in 0 to O_PARAM.SHAPE.C.SIZE-1 loop
            elem := GET_ELEMENT_FROM_IMAGE_STREAM_DATA(
                        PARAM   => OUTLET_IMAGE_PARAM,
                        C       => c_pos - OUTLET_IMAGE_PARAM.SHAPE.C.LO,
                        X       => x_pos - OUTLET_IMAGE_PARAM.SHAPE.X.LO,
                        Y       => y_pos - OUTLET_IMAGE_PARAM.SHAPE.Y.LO,
                        DATA    => outlet_data
                    );
            SET_ELEMENT_TO_DATA(
                        PARAM   => O_PARAM,
                        C       => c_pos - O_PARAM.SHAPE.C.LO,
                        D       => d_pos - O_PARAM.SHAPE.D.LO,
                        X       => x_pos - O_PARAM.SHAPE.X.LO,
                        Y       => y_pos - O_PARAM.SHAPE.Y.LO,
                        ELEMENT => elem,
                        DATA    => data
            );
        end loop;
        end loop;
        end loop;
        end loop;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        set_conv_pipeline_atrb(
            I_ATRB_VEC   => GET_ATRB_C_VECTOR_FROM_IMAGE_STREAM_DATA(OUTLET_IMAGE_PARAM, outlet_data),
            I_ATRB_START => IMAGE_STREAM_DATA_IS_START_C(OUTLET_IMAGE_PARAM, outlet_data),
            I_ATRB_LAST  => IMAGE_STREAM_DATA_IS_LAST_C (OUTLET_IMAGE_PARAM, outlet_data),
            O_PARAM      => O_PARAM,
            O_ATRB_FIELD => O_PARAM.DATA.ATRB_C_FIELD,
            O_DATA       => data
        );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        set_conv_pipeline_atrb(
            I_ATRB_VEC   => outlet_d_atrb,
            I_ATRB_START => outlet_d_atrb(outlet_d_atrb'low ).START,
            I_ATRB_LAST  => outlet_d_atrb(outlet_d_atrb'high).LAST ,
            O_PARAM      => O_PARAM,
            O_ATRB_FIELD => O_PARAM.DATA.ATRB_D_FIELD,
            O_DATA       => data
        );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        set_conv_pipeline_atrb(
            I_ATRB_VEC   => GET_ATRB_X_VECTOR_FROM_IMAGE_STREAM_DATA(OUTLET_IMAGE_PARAM, outlet_data),
            I_ATRB_START => IMAGE_STREAM_DATA_IS_START_X(OUTLET_IMAGE_PARAM, outlet_data),
            I_ATRB_LAST  => IMAGE_STREAM_DATA_IS_LAST_X (OUTLET_IMAGE_PARAM, outlet_data),
            O_PARAM      => O_PARAM,
            O_ATRB_FIELD => O_PARAM.DATA.ATRB_X_FIELD,
            O_DATA       => data
        );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        set_conv_pipeline_atrb(
            I_ATRB_VEC   => GET_ATRB_Y_VECTOR_FROM_IMAGE_STREAM_DATA(OUTLET_IMAGE_PARAM, outlet_data),
            I_ATRB_START => IMAGE_STREAM_DATA_IS_START_Y(OUTLET_IMAGE_PARAM, outlet_data),
            I_ATRB_LAST  => IMAGE_STREAM_DATA_IS_LAST_Y (OUTLET_IMAGE_PARAM, outlet_data),
            O_PARAM      => O_PARAM,
            O_ATRB_FIELD => O_PARAM.DATA.ATRB_Y_FIELD,
            O_DATA       => data
        );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        O_DATA <= data;
    end process;
    O_VALID <= outlet_valid;
    outlet_ready <= O_READY;
end RTL;
