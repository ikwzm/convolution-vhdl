-----------------------------------------------------------------------------------
--!     @file    conv_components.vhd                                             --
--!     @brief   CONVOLUTION COMPONENT LIBRARY DESCRIPTION                       --
--!     @version 0.1.0                                                           --
--!     @date    2019/02/11                                                      --
--!     @author  Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>                     --
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
--                                                                               --
--      Copyright (C) 2019 Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>           --
--      All rights reserved.                                                     --
--                                                                               --
--      Redistribution and use in source and binary forms, with or without       --
--      modification, are permitted provided that the following conditions       --
--      are met:                                                                 --
--                                                                               --
--        1. Redistributions of source code must retain the above copyright      --
--           notice, this list of conditions and the following disclaimer.       --
--                                                                               --
--        2. Redistributions in binary form must reproduce the above copyright   --
--           notice, this list of conditions and the following disclaimer in     --
--           the documentation and/or other materials provided with the          --
--           distribution.                                                       --
--                                                                               --
--      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS      --
--      "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT        --
--      LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR    --
--      A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT    --
--      OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,    --
--      SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT         --
--      LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,    --
--      DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY    --
--      THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT      --
--      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE    --
--      OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.     --
--                                                                               --
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
library CONVOLUTION;
use     CONVOLUTION.CONV_TYPES.all;
library PIPEWORK;
use     PIPEWORK.IMAGE_TYPES.all;
-----------------------------------------------------------------------------------
--! @brief CONVOLUTION COMPONENT LIBRARY DESCRIPTION                             --
-----------------------------------------------------------------------------------
package CONV_COMPONENTS is
-----------------------------------------------------------------------------------
--! @brief CONV_INT_ADDER                                                        --
-----------------------------------------------------------------------------------
component CONV_INT_ADDER
    generic (
        I_PARAM         : --! @brief INPUT  PIPELINE DATA PARAMETER :
                          --! パイプラインデータ入力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     I_PARAM.SHAPE.C.SIZE >= O_PARAM.SHAPE.C.SIZE
                          --!     I_PARAM.SHAPE.D.SIZE  = O_PARAM.SHAPE.D.SIZE
                          --!     I_PARAM.SHAPE.X.SIZE  = O_PARAM.SHAPE.X.SIZE
                          --!     I_PARAM.SHAPE.Y.SIZE  = O_PARAM.SHAPE.Y.SIZE
                          --!     I_PARAM.ELEM_BITS    <= O_PARAM.ELEM_BITS (桁あふれに注意)
                          CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,2,1,1,1);
        O_PARAM         : --! @brief OUTPUT PIPELINE DATA PARAMETER :
                          --! パイプラインデータ出力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     O_PARAM.SHAPE.C.SIZE <= I_PARAM.SHAPE.C.SIZE
                          --!     O_PARAM.SHAPE.D.SIZE  = I_PARAM.SHAPE.D.SIZE
                          --!     O_PARAM.SHAPE.X.SIZE  = I_PARAM.SHAPE.X.SIZE
                          --!     O_PARAM.SHAPE.Y.SIZE >= I_PARAM.SHAPE.Y.SIZE
                          --!     O_PARAM.ELEM_BITS    >= I_PARAM.ELEM_BITS (桁あふれに注意)
                          CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,1,1,1,1);
        QUEUE_SIZE      : --! パイプラインレジスタの深さを指定する.
                          --! * QUEUE_SIZE=0 の場合は出力にキューが挿入されずダイレ
                          --!   クトに出力される.
                          integer := 2;
        SIGN            : --! 演算時の正負符号の有無を指定する.
                          --! * SIGN=TRUE  の場合、符号有り(  signed)で計算する.
                          --! * SIGN=FALSE の場合、符号無し(unsigned)で計算する.
                          boolean := TRUE
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
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA          : --! @brief INPUT CONVOLUTION PIPELINE DATA :
                          --! パイプラインデータ入力.
                          in  std_logic_vector(I_PARAM.DATA.SIZE-1 downto 0);
        I_VALID         : --! @brief INPUT CONVOLUTION PIPELINE DATA VALID :
                          --! 入力パイプラインデータ有効信号.
                          --! * I_DATAが有効であることを示す.
                          --! * I_VALID='1'and I_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          in  std_logic;
        I_READY         : --! @brief INPUT CONVOLUTION PIPELINE DATA READY :
                          --! 入力パイプラインデータレディ信号.
                          --! * 次のパイプラインデータを入力出来ることを示す.
                          --! * I_VALID='1'and I_READY='1'でパイプラインデータが
                          --!   取り込まれる.
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
                          --! * O_VALID='1'and O_READY='1'でパイプラインデータが
                          --!   キューから取り除かれる.
                          in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief CONV_INT_ADDER_TREE                                                   --
-----------------------------------------------------------------------------------
component CONV_INT_ADDER_TREE
    generic (
        I_PARAM         : --! @brief INPUT  PIPELINE DATA PARAMETER :
                          --! パイプラインデータ入力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     I_PARAM.SHAPE.C.SIZE >= O_PARAM.SHAPE.C.SIZE
                          --!     I_PARAM.SHAPE.D.SIZE  = O_PARAM.SHAPE.D.SIZE
                          --!     I_PARAM.SHAPE.X.SIZE  = O_PARAM.SHAPE.X.SIZE
                          --!     I_PARAM.SHAPE.Y.SIZE  = O_PARAM.SHAPE.Y.SIZE
                          --!     I_PARAM.ELEM_BITS    <= O_PARAM.ELEM_BITS (桁あふれに注意)
                          CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,2,1,1,1);
        O_PARAM         : --! @brief OUTPUT PIPELINE DATA PARAMETER :
                          --! パイプラインデータ出力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     O_PARAM.SHAPE.C.SIZE <= I_PARAM.SHAPE.C.SIZE
                          --!     O_PARAM.SHAPE.D.SIZE  = I_PARAM.SHAPE.D.SIZE
                          --!     O_PARAM.SHAPE.X.SIZE  = I_PARAM.SHAPE.X.SIZE
                          --!     O_PARAM.SHAPE.Y.SIZE >= I_PARAM.SHAPE.Y.SIZE
                          --!     O_PARAM.ELEM_BITS    >= I_PARAM.ELEM_BITS (桁あふれに注意)
                          CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,1,1,1,1);
        QUEUE_SIZE      : --! パイプラインレジスタの深さを指定する.
                          --! * QUEUE_SIZE=0 の場合は出力にキューが挿入されずダイレ
                          --!   クトに出力される.
                          integer := 2;
        SIGN            : --! 演算時の正負符号の有無を指定する.
                          --! * SIGN=TRUE  の場合、符号有り(  signed)で計算する.
                          --! * SIGN=FALSE の場合、符号無し(unsigned)で計算する.
                          boolean := TRUE
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
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA          : --! @brief INPUT CONVOLUTION PIPELINE DATA :
                          --! パイプラインデータ入力.
                          in  std_logic_vector(I_PARAM.DATA.SIZE-1 downto 0);
        I_VALID         : --! @brief INPUT CONVOLUTION PIPELINE DATA VALID :
                          --! 入力パイプラインデータ有効信号.
                          --! * I_DATAが有効であることを示す.
                          --! * I_VALID='1'and I_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          in  std_logic;
        I_READY         : --! @brief INPUT CONVOLUTION PIPELINE DATA READY :
                          --! 入力パイプラインデータレディ信号.
                          --! * 次のパイプラインデータを入力出来ることを示す.
                          --! * I_VALID='1'and I_READY='1'でパイプラインデータが
                          --!   取り込まれる.
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
                          --! * O_VALID='1'and O_READY='1'でパイプラインデータが
                          --!   キューから取り除かれる.
                          in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief CONV_INT_ACCUMULATOR                                                  --
-----------------------------------------------------------------------------------
component CONV_INT_ACCUMULATOR
    generic (
        I_PARAM         : --! @brief INPUT  PIPELINE DATA PARAMETER :
                          --! パイプラインデータ入力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     I_PARAM.SHAPE = O_PARAM.SHAPE
                          --!     I_PARAM.SHAPE = B_PARAM.SHAPE
                          --!     I_PARAM.ELEM_BITS <= O_PARAM.ELEM_BITS (桁あふれに注意)
                          CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,1,1,1,1);
        O_PARAM         : --! @brief OUTPUT PIPELINE DATA PARAMETER :
                          --! パイプラインデータ出力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     O_PARAM.SHAPE = I_PARAM.SHAPE
                          --!     O_PARAM.SHAPE = B_PARAM.SHAPE
                          --!     O_PARAM.ELEM_BITS >= I_PARAM.ELEM_BITS (桁あふれに注意)
                          --!     O_PARAM.ELEM_BITS >= B_PARAM.ELEM_BITS (桁あふれに注意)
                          CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,1,1,1,1);
        B_PARAM         : --! @brief INPUT PIPELINE BIAS DATA PARAMETER :
                          --! バイアスデータ入力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     B_PARAM.SHAPE = I_PARAM.SHAPE
                          --!     B_PARAM.SHAPE = O_PARAM.SHAPE
                          --!     B_PARAM.ELEM_BITS <= O_PARAM.ELEM_BITS (桁あふれに注意)
                          CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,1,1,1,1);
        QUEUE_SIZE      : --! パイプラインレジスタの深さを指定する.
                          --! * QUEUE_SIZE=0 の場合は出力にキューが挿入されずダイレ
                          --!   クトに出力される.
                          integer := 2;
        SIGN            : --! 演算時の正負符号の有無を指定する.
                          --! * SIGN=TRUE  の場合、符号有り(  signed)で計算する.
                          --! * SIGN=FALSE の場合、符号無し(unsigned)で計算する.
                          boolean := TRUE
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
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA          : --! @brief INPUT CONVOLUTION PIPELINE DATA :
                          --! パイプラインデータ入力.
                          in  std_logic_vector(I_PARAM.DATA.SIZE-1 downto 0);
        I_VALID         : --! @brief INPUT CONVOLUTION PIPELINE DATA VALID :
                          --! 入力パイプラインデータ有効信号.
                          --! * I_DATAが有効であることを示す.
                          --! * I_VALID='1'and I_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          in  std_logic;
        I_READY         : --! @brief INPUT CONVOLUTION PIPELINE DATA READY :
                          --! 入力パイプラインデータレディ信号.
                          --! * 次のパイプラインデータを入力出来ることを示す.
                          --! * I_VALID='1'and I_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          out std_logic;
        B_DATA          : --! @brief INPUT CONVOLUTION PIPELINE BIAS DATA :
                          --! バイアスデータ入力.
                          in  std_logic_vector(I_PARAM.DATA.SIZE-1 downto 0);
        B_VALID         : --! @brief INPUT CONVOLUTION PIPELINE BIAS DATA VALID :
                          --! 入力バイアスデータ有効信号.
                          --! * B_DATAが有効であることを示す.
                          --! * B_VALID='1'and B_READY='1'でバイアスデータが
                          --!   取り込まれる.
                          in  std_logic;
        B_READY         : --! @brief INPUT CONVOLUTION PIPELINE BIAS DATA READY :
                          --! 入力バイアスデータレディ信号.
                          --! * 次のバイアスデータを入力出来ることを示す.
                          --! * B_VALID='1'and B_READY='1'でバイアスデータが
                          --!   取り込まれる.
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
                          --! * O_VALID='1'and O_READY='1'でパイプラインデータが
                          --!   キューから取り除かれる.
                          in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief CONV_INT_MULTIPLIER                                                   --
-----------------------------------------------------------------------------------
component CONV_INT_MULTIPLIER
    generic (
        I_PARAM         : --! @brief INPUT  CONVOLUTION PIPELINE IMAGE DATA PARAMETER :
                          --! パイプラインデータ入力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     I_PARAM.SHAPE = O_PARAM.SHAPE
                          --!     I_PARAM.SHAPE = W_PARAM.SHAPE
                          --!     I_PARAM.ELEM_BITS+W_PARAM.ELEM_BITS <= O_PARAM.ELEM_BITS (桁あふれに注意)
                          CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,1,1,1,1);
        W_PARAM         : --! @brief INPUT  CONVOLUTION PIPELINE WEIGHT DATA PARAMETER :
                          --! パイプラインデータ入力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     W_PARAM.SHAPE = I_PARAM.SHAPE
                          --!     W_PARAM.SHAPE = O_PARAM.SHAPE
                          --!     W_PARAM.ELEM_BITS+I_PARAM.ELEM_BITS <= O_PARAM.ELEM_BITS (桁あふれに注意)
                          CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,1,1,1,1);
        O_PARAM         : --! @brief OUTPUT CONVOLUTION PIPELINE DATA PARAMETER :
                          --! パイプラインデータ出力ポートのパラメータを指定する.
                          --! * 次の条件を満していなければならない.
                          --!     O_PARAM.SHAPE = I_PARAM.SHAPE
                          --!     O_PARAM.SHAPE = W_PARAM.SHAPE
                          --!     O_PARAM.ELEM_BITS >= I_PARAM.ELEM_BITS+W_PARAM.ELEM_BITS (桁あふれに注意)
                          CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(16,0,1,1,1,1);
        QUEUE_SIZE      : --! パイプラインレジスタの深さを指定する.
                          --! * QUEUE_SIZE=0 の場合は出力にキューが挿入されずダイレ
                          --!   クトに出力される.
                          integer := 2;
        SIGN            : --! 演算時の正負符号の有無を指定する.
                          --! * SIGN=TRUE  の場合、符号有り(  signed)で計算する.
                          --! * SIGN=FALSE の場合、符号無し(unsigned)で計算する.
                          boolean := TRUE
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
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA          : --! @brief INPUT CONVOLUTION PIPELINE IMAGE DATA :
                          --! パイプラインデータ入力.
                          in  std_logic_vector(I_PARAM.DATA.SIZE-1 downto 0);
        I_VALID         : --! @brief INPUT CONVOLUTION PIPELINE IMAGE DATA VALID :
                          --! 入力パイプラインデータ有効信号.
                          --! * I_DATAが有効であることを示す.
                          --! * I_VALID='1'and I_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          in  std_logic;
        I_READY         : --! @brief INPUT CONVOLUTION PIPELINE IMAGE DATA READY :
                          --! 入力パイプラインデータレディ信号.
                          --! * 次のパイプラインデータを入力出来ることを示す.
                          --! * I_VALID='1'and I_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          out std_logic;
        W_DATA          : --! @brief INPUT CONVOLUTION PIPELINE WEIGHT DATA :
                          --! パイプラインデータ入力.
                          in  std_logic_vector(W_PARAM.DATA.SIZE-1 downto 0);
        W_VALID         : --! @brief INPUT CONVOLUTION PIPELINE WEIGHT DATA VALID :
                          --! 入力パイプラインデータ有効信号.
                          --! * W_DATAが有効であることを示す.
                          --! * W_VALID='1'and W_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          in  std_logic;
        W_READY         : --! @brief INPUT CONVOLUTION PIPELINE WEIGHT DATA READY :
                          --! 入力パイプラインデータレディ信号.
                          --! * 次のパイプラインデータを入力出来ることを示す.
                          --! * W_VALID='1'and W_READY='1'でパイプラインデータが
                          --!   取り込まれる.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA          : --! @brief OUTPUT CONVOLUTION PIPELINE IMAGE DATA :
                          --! パイプラインデータ出力.
                          out std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
        O_VALID         : --! @brief OUTPUT CONVOLUTION PIPELINE IMAGE DATA VALID :
                          --! 出力パイプラインデータ有効信号.
                          --! * O_DATA が有効であることを示す.
                          --! * O_VALID='1'and O_READY='1'でパイプラインデータが
                          --!   キューから取り除かれる.
                          out std_logic;
        O_READY         : --! @brief OUTPUT CONVOLUTION PIPELINE IMAGE DATA READY :
                          --! 出力パイプラインデータレディ信号.
                          --! * O_VALID='1'and O_READY='1'でパイプラインデータが
                          --!   キューから取り除かれる.
                          in  std_logic
    );
end component;
-----------------------------------------------------------------------------------
--! @brief CONV_INT_CORE                                                         --
-----------------------------------------------------------------------------------
component CONV_INT_CORE
    generic (
        PARAM           : --! @brief CONVOLUTION PARAMETER :
                          --! 畳み込みのパラメータを指定する.
                          CONV_PARAM_TYPE := NEW_CONV_PARAM(
                              KERNEL_SIZE => CONV_KERNEL_SIZE_3x3,
                              STRIDE      => NEW_IMAGE_STREAM_STRIDE_PARAM(1,1),
                              I_STREAM    => NEW_IMAGE_STREAM_PARAM(8,1,1,1),
                              I_SHAPE     => NEW_IMAGE_SHAPE_CONSTANT(8,32,0,32,32),
                              B_ELEM_BITS => 16,
                              W_ELEM_BITS =>  8,
                              M_ELEM_BITS => 16,
                              O_ELEM_BITS => 16,
                              O_SHAPE_C   => NEW_IMAGE_SHAPE_SIDE_CONSTANT(32)
                          );
        SIGN            : --! 演算時の正負符号の有無を指定する.
                          --! * SIGN=TRUE  の場合、符号有り(  signed)で計算する.
                          --! * SIGN=FALSE の場合、符号無し(unsigned)で計算する.
                          boolean := TRUE
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
    -- 各種パラメータ入力 I/F
    -------------------------------------------------------------------------------
        C_SIZE          : --! @brief CONVOLUTION C CHANNEL SIZE :
                          in  integer range 0 to PARAM.SHAPE.C.MAX_SIZE := PARAM.SHAPE.C.SIZE;
        D_SIZE          : --! @brief CONVOLUTION D CHANNEL SIZE :
                          in  integer range 0 to PARAM.SHAPE.D.MAX_SIZE := PARAM.SHAPE.D.SIZE;
        X_SIZE          : --! @brief CONVOLUTION X SIZE :
                          in  integer range 0 to PARAM.SHAPE.X.MAX_SIZE := PARAM.SHAPE.X.SIZE;
        Y_SIZE          : --! @brief CONVOLUTION Y SIZE :
                          in  integer range 0 to PARAM.SHAPE.Y.MAX_SIZE := PARAM.SHAPE.Y.SIZE;
    -------------------------------------------------------------------------------
    -- 入力側 I/F
    -------------------------------------------------------------------------------
        I_DATA          : --! @brief INPUT IMAGE DATA :
                          --! イメージデータ入力.
                          in  std_logic_vector(PARAM.I_STREAM.DATA.SIZE-1 downto 0);
        I_VALID         : --! @brief INPUT IMAGE DATA VALID :
                          --! 入力イメージデータ有効信号.
                          --! * I_DATAが有効であることを示す.
                          --! * I_VALID='1'and I_READY='1'でイメージデータが取り込
                          --!   まれる.
                          in  std_logic;
        I_READY         : --! @brief INPUT IMAGE DATA READY :
                          --! 入力イメージデータレディ信号.
                          --! * 次のイメージデータを入力出来ることを示す.
                          --! * I_VALID='1'and I_READY='1'でイメージデータが取り込
                          --!   まれる.
                          out std_logic;
        W_DATA          : --! @brief INPUT WEIGHT DATA :
                          --! 重みデータ入力.
                          in  std_logic_vector(PARAM.W_STREAM.DATA.SIZE-1 downto 0);
        W_VALID         : --! @brief INPUT WEIGHT DATA VALID :
                          --! 入力重みデータ有効信号.
                          --! * W_DATAが有効であることを示す.
                          --! * W_VALID='1'and W_READY='1'で重みデータが取り込ま
                          --!   れる.
                          in  std_logic;
        W_READY         : --! @brief INPUT WEIGHT DATA READY :
                          --! 入力重みデータレディ信号.
                          --! * 次の重みデータを入力出来ることを示す.
                          --! * W_VALID='1'and W_READY='1'で重みデータが取り込ま
                          --!   れる.
                          out std_logic;
        B_DATA          : --! @brief INPUT BIAS DATA :
                          --! バイアスデータ入力.
                          in  std_logic_vector(PARAM.B_STREAM.DATA.SIZE-1 downto 0);
        B_VALID         : --! @brief INPUT BIAS DATA VALID :
                          --! 入力バイアスデータ有効信号.
                          --! * B_DATAが有効であることを示す.
                          --! * B_VALID='1'and B_READY='1'でバイアスデータが取り込
                          --!   まれる.
                          in  std_logic;
        B_READY         : --! @brief INPUT BIAS DATA READY :
                          --! 入力バイアスデータレディ信号.
                          --! * 次のバイアスデータを入力出来ることを示す.
                          --! * B_VALID='1'and B_READY='1'でバイアスデータが取り込
                          --!   まれる.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA          : --! @brief OUTPUT IMAGE DATA :
                          --! イメージデータ出力.
                          out std_logic_vector(PARAM.O_STREAM.DATA.SIZE-1 downto 0);
        O_VALID         : --! @brief OUTPUT IMAGE DATA VALID :
                          --! 出力イメージデータ有効信号.
                          --! * O_DATA が有効であることを示す.
                          --! * O_VALID='1'and O_READY='1'でイメージデータがキュー
                          --!   から取り除かれる.
                          out std_logic;
        O_READY         : --! @brief OUTPUT IMAGE DATA READY :
                          --! 出力イメージデータレディ信号.
                          --! * O_VALID='1'and O_READY='1'でイメージデータがキュー
                          --!   から取り除かれる.
                          in  std_logic
    );
end component;
end CONV_COMPONENTS;
