-----------------------------------------------------------------------------------
--!     @file    conv_types.vhd
--!     @brief   Convolution Engine Types Package.
--!     @version 0.1.0
--!     @date    2019/2/6
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
use     ieee.numeric_std.all;
library PipeWork;
use     PipeWork.IMAGE_TYPES.all;
-----------------------------------------------------------------------------------
--! @brief Convolution Engine で使用する各種タイプ/定数を定義しているパッケージ.
-----------------------------------------------------------------------------------
package CONV_TYPES is
    -------------------------------------------------------------------------------
    --! @brief Convolution Kernel の大きさを定義するレコードタイプ.
    -------------------------------------------------------------------------------
    type      CONV_KERNEL_SIZE_TYPE is record
                  X                 :  IMAGE_VECTOR_RANGE_TYPE;
                  Y                 :  IMAGE_VECTOR_RANGE_TYPE;
    end record;
    -------------------------------------------------------------------------------
    --! @brief Convolution Kernel の大きさを設定する関数群
    -------------------------------------------------------------------------------
    function  NEW_CONV_KERNEL_SIZE(X_SIZE   ,Y_SIZE   :integer) return CONV_KERNEL_SIZE_TYPE;
    function  NEW_CONV_KERNEL_SIZE(X_LO,X_HI,Y_LO,Y_HI:integer) return CONV_KERNEL_SIZE_TYPE;
    constant  CONV_KERNEL_SIZE_1x1  :  CONV_KERNEL_SIZE_TYPE := NEW_CONV_KERNEL_SIZE(1,1);
    constant  CONV_KERNEL_SIZE_3x3  :  CONV_KERNEL_SIZE_TYPE := NEW_CONV_KERNEL_SIZE(-1,1,-1,1);

    -------------------------------------------------------------------------------
    --! @brief Image Data(一回の転送単位) の要素フィールドを定義するレコードタイプ.
    -------------------------------------------------------------------------------
    type      CONV_DATA_ELEM_FIELD_TYPE is record
                  LO                :  integer;
                  HI                :  integer;
                  SIZE              :  integer;
                  C_SIZE            :  integer;
                  D_SIZE            :  integer;
                  X_SIZE            :  integer;
                  Y_SIZE            :  integer;
    end record;

    -------------------------------------------------------------------------------
    --! @brief Convolution Data(一回の転送単位) 内の各種属性のフィールドを定義するレコードタイプ.
    -------------------------------------------------------------------------------
    type      CONV_DATA_ATRB_CHANNEL_FIELD_TYPE is record
                   VALID             :  IMAGE_VECTOR_RANGE_TYPE;
                   START_POS         :  integer;
                   LAST_POS          :  integer;
                   LO                :  integer;
                   HI                :  integer;
                   SIZE              :  integer;
    end record;

    -------------------------------------------------------------------------------
    --! @brief Convolution Data(一回の転送単位) の属性フィールドを定義するレコードタイプ.
    -------------------------------------------------------------------------------
    type      CONV_DATA_ATRB_FIELD_TYPE is record
                  LO                :  integer;
                  HI                :  integer;
                  SIZE              :  integer;
                  C                 :  CONV_DATA_ATRB_CHANNEL_FIELD_TYPE;
                  D                 :  CONV_DATA_ATRB_CHANNEL_FIELD_TYPE;
                  X                 :  CONV_DATA_ATRB_CHANNEL_FIELD_TYPE;
                  Y                 :  CONV_DATA_ATRB_CHANNEL_FIELD_TYPE;
    end record;

    -------------------------------------------------------------------------------
    --! @brief Convolution Data(一回の転送単位) の各種フィールドを定義するレコードタイプ.
    -------------------------------------------------------------------------------
    type      CONV_DATA_FIELD_TYPE is record
                  LO                :  integer;
                  HI                :  integer;
                  SIZE              :  integer;
                  ELEM_FIELD        :  CONV_DATA_ELEM_FIELD_TYPE;
                  ATRB_FIELD        :  CONV_DATA_ATRB_FIELD_TYPE;
                  INFO_FIELD        :  IMAGE_VECTOR_RANGE_TYPE;
    end record;

    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の各種パラメータを定義するレコードタイプ.
    --!        Convolution Pipeline のデータには C(Input Channel),D(Output Channel)
    --!        X,Yの４次元の要素が含まれている.
    -------------------------------------------------------------------------------
    type      CONV_PIPELINE_PARAM_TYPE is record
                  ELEM_BITS         :  integer;                       -- 1要素(Element)のビット数
                  INFO_BITS         :  integer;                       -- その他情報のビット数
                  SHAPE             :  IMAGE_SHAPE_TYPE;              -- Convolution Stream の形
                  STRIDE            :  IMAGE_STREAM_STRIDE_PARAM_TYPE;-- Convolution Stream の移動距離
                  DATA              :  CONV_DATA_FIELD_TYPE;          -- Dataのフィールド情報
    end record;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の各種パラメータを設定する関数群
    -------------------------------------------------------------------------------
    function  NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS         :  integer;
                  INFO_BITS         :  integer := 0;
                  SHAPE             :  IMAGE_SHAPE_TYPE;
                  STRIDE            :  IMAGE_STREAM_STRIDE_PARAM_TYPE)
                  return               CONV_PIPELINE_PARAM_TYPE;
    function  NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS         :  integer;
                  INFO_BITS         :  integer := 0;
                  C                 :  integer := 1;
                  D                 :  integer := 1;
                  X                 :  integer := 1;
                  Y                 :  integer := 1)
                  return               CONV_PIPELINE_PARAM_TYPE;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline Data から要素を取り出す関数
    -------------------------------------------------------------------------------
    function  GET_ELEMENT_FROM_DATA(
                  PARAM             :  CONV_PIPELINE_PARAM_TYPE;
                  C                 :  integer;
                  D                 :  integer;
                  X                 :  integer;
                  Y                 :  integer;
                  DATA              :  std_logic_vector)
                  return               std_logic_vector;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline Data に要素を追加するプロシージャ
    -------------------------------------------------------------------------------
    procedure SET_ELEMENT_TO_DATA(
                  PARAM             :  in    CONV_PIPELINE_PARAM_TYPE;
                  C                 :  in    integer;
                  D                 :  in    integer;
                  X                 :  in    integer;
                  Y                 :  in    integer;
                  ELEMENT           :  in    std_logic_vector;
        variable  DATA              :  inout std_logic_vector);

    -------------------------------------------------------------------------------
    --! @brief Convolution の各種パラメータを定義するレコードタイプ.
    -------------------------------------------------------------------------------
    type      CONV_PARAM_TYPE       is record
                  KERNEL_SIZE       :  CONV_KERNEL_SIZE_TYPE;
                  STRIDE            :  IMAGE_STREAM_STRIDE_PARAM_TYPE;
                  I_STREAM          :  IMAGE_STREAM_PARAM_TYPE;  -- イメージ入力側の IMAGE_STREAM パラメータ
                  I_SHAPE           :  IMAGE_SHAPE_TYPE;         -- イメージ入力側の IMAGE_SHAPE  パラメータ
                  O_STREAM          :  IMAGE_STREAM_PARAM_TYPE;  -- イメージ出力側の IMAGE_STREAM パラメータ
                  O_SHAPE           :  IMAGE_SHAPE_TYPE;         -- イメージ出力側の IMAGE_SHAPE  パラメータ
                  A_STREAM          :  IMAGE_STREAM_PARAM_TYPE;  -- 内部バッファの   IMAGE_STREAM パラメータ
                  A_SHAPE           :  IMAGE_SHAPE_TYPE;         -- 内部バッファの   IMAGE_SHAPE  パラメータ
                  B_STREAM          :  IMAGE_STREAM_PARAM_TYPE;  -- バイアス入力の   IMAGE_STREAM パラメータ
                  W_STREAM          :  IMAGE_STREAM_PARAM_TYPE;  -- ウェイト入力の   IMAGE_STREAM パラメータ
                  A_PIPELINE        :  CONV_PIPELINE_PARAM_TYPE; -- 内部のイメージ入力 Convolution Pipeline パラメータ
                  B_PIPELINE        :  CONV_PIPELINE_PARAM_TYPE; -- 内部のバイアス入力 Convolution Pipeline パラメータ
                  W_PIPELINE        :  CONV_PIPELINE_PARAM_TYPE; -- 内部のウェイト入力 Convolution Pipeline パラメータ
                  M_PIPELINE        :  CONV_PIPELINE_PARAM_TYPE; -- 内部の乗算出力     Convolution Pipeline パラメータ
                  O_PIPELINE        :  CONV_PIPELINE_PARAM_TYPE; -- 内部の積算出力     Convolution Pipeline パラメータ
                  C_UNROLL          :  integer;
                  D_UNROLL          :  integer;
                  X_UNROLL          :  integer;
                  Y_UNROLL          :  integer;
    end record;
    -------------------------------------------------------------------------------
    --! @brief Convolution の各種パラメータを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_PARAM(
                  KERNEL_SIZE       :  CONV_KERNEL_SIZE_TYPE;
                  STRIDE            :  IMAGE_STREAM_STRIDE_PARAM_TYPE;
                  I_STREAM          :  IMAGE_STREAM_PARAM_TYPE;
                  I_SHAPE           :  IMAGE_SHAPE_TYPE;
                  B_ELEM_BITS       :  integer ;
                  W_ELEM_BITS       :  integer ;
                  M_ELEM_BITS       :  integer ;
                  O_ELEM_BITS       :  integer ;
                  O_SHAPE_C         :  IMAGE_SHAPE_SIDE_TYPE;
                  C_UNROLL          :  integer := 1;
                  D_UNROLL          :  integer := 1;
                  X_UNROLL          :  integer := 1;
                  Y_UNROLL          :  integer := 1;
                  X_BORDER          :  IMAGE_STREAM_BORDER_TYPE := IMAGE_STREAM_BORDER_NONE;
                  Y_BORDER          :  IMAGE_STREAM_BORDER_TYPE := IMAGE_STREAM_BORDER_NONE)
                  return               CONV_PARAM_TYPE;

    -------------------------------------------------------------------------------
    --! @brief イメージ入力 Stream を Convolution Pipeline に変換する関数
    -------------------------------------------------------------------------------
    function  CONV_PIPELINE_FROM_IMAGE_STREAM(
                  PIPELINE_PARAM    :  CONV_PIPELINE_PARAM_TYPE;
                  STREAM_PARAM      :  IMAGE_STREAM_PARAM_TYPE;
                  KERNEL_SIZE       :  CONV_KERNEL_SIZE_TYPE;
                  STRIDE            :  IMAGE_STREAM_STRIDE_PARAM_TYPE;
                  STREAM_DATA       :  std_logic_vector)
                  return               std_logic_vector;

    -------------------------------------------------------------------------------
    --! @brief ウェイト入力 Stream を Convolution Pipeline に変換する関数
    -------------------------------------------------------------------------------
    function  CONV_PIPELINE_FROM_WEIGHT_STREAM(
                  PIPELINE_PARAM    :  CONV_PIPELINE_PARAM_TYPE;
                  STREAM_PARAM      :  IMAGE_STREAM_PARAM_TYPE;
                  KERNEL_SIZE       :  CONV_KERNEL_SIZE_TYPE;
                  STREAM_DATA       :  std_logic_vector)
                  return               std_logic_vector;
end CONV_TYPES;
-----------------------------------------------------------------------------------
--! @brief Image の各種タイプ/定数を定義しているパッケージ.
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PipeWork;
use     PipeWork.IMAGE_TYPES.all;
package body CONV_TYPES is
    -------------------------------------------------------------------------------
    --! @brief Convolution Kernel の大きさを設定する関数群
    -------------------------------------------------------------------------------
    function  NEW_CONV_KERNEL_SIZE(X_SIZE   ,Y_SIZE   :integer) return CONV_KERNEL_SIZE_TYPE is
        variable  kernel_size  :  CONV_KERNEL_SIZE_TYPE;
    begin
        kernel_size.X := NEW_IMAGE_VECTOR_RANGE(X_SIZE);
        kernel_size.Y := NEW_IMAGE_VECTOR_RANGE(Y_SIZE);
        return kernel_size;
    end function;

    function  NEW_CONV_KERNEL_SIZE(X_LO,X_HI,Y_LO,Y_HI:integer) return CONV_KERNEL_SIZE_TYPE is
        variable  kernel_size  :  CONV_KERNEL_SIZE_TYPE;
    begin
        kernel_size.X := NEW_IMAGE_VECTOR_RANGE(X_LO, X_HI);
        kernel_size.Y := NEW_IMAGE_VECTOR_RANGE(Y_LO, Y_HI);
        return kernel_size;
    end function;

    -------------------------------------------------------------------------------
    --! @brief Convolution Data(一回の転送単位) 内の要素フィールドパラメータを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_DATA_ELEM_FIELD(
                  LO        :  integer;
                  ELEM_BITS :  integer;
                  SHAPE     :  IMAGE_SHAPE_TYPE)
                  return       CONV_DATA_ELEM_FIELD_TYPE
    is
        variable  elem_field:  CONV_DATA_ELEM_FIELD_TYPE;
    begin
        elem_field.C_SIZE := 1;
        elem_field.D_SIZE := 1 * SHAPE.C.SIZE;
        elem_field.X_SIZE := 1 * SHAPE.C.SIZE * SHAPE.D.SIZE;
        elem_field.Y_SIZE := 1 * SHAPE.C.SIZE * SHAPE.D.SIZE * SHAPE.X.SIZE;
        elem_field.SIZE   := 1 * SHAPE.C.SIZE * SHAPE.D.SIZE * SHAPE.X.SIZE * SHAPE.Y.SIZE * ELEM_BITS;
        elem_field.LO     := 0;
        elem_field.HI     := elem_field.SIZE-1;
        return elem_field;
    end function;

    -------------------------------------------------------------------------------
    --! @brief Convolution Data(一回の転送単位) 内の各種属性のフィールドパラメータを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_DATA_ATRB_CHANNEL_FIELD(
                  LO        :  integer;
                  SIZE      :  integer)
                  return       CONV_DATA_ATRB_CHANNEL_FIELD_TYPE
    is
        variable param      :  CONV_DATA_ATRB_CHANNEL_FIELD_TYPE;
    begin
        param.VALID.LO  := LO;
        param.VALID.HI  := param.VALID.LO  + SIZE-1;
        param.START_POS := param.VALID.HI  + 1;
        param.LAST_POS  := param.START_POS + 1;
        param.LO        := param.VALID.LO;
        param.HI        := param.LAST_POS;
        param.SIZE      := param.HI - param.LO + 1;
        return param;
    end function;

    -------------------------------------------------------------------------------
    --! @brief Convolution Data(一回の転送単位) 内の各種属性のフィールドパラメータを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_DATA_ATRB_FIELD(
                  LO        :  integer;
                  SHAPE     :  IMAGE_SHAPE_TYPE)
                  return       CONV_DATA_ATRB_FIELD_TYPE
    is
        variable param      :  CONV_DATA_ATRB_FIELD_TYPE;
    begin
        param.LO   := LO;
        param.C    := NEW_CONV_DATA_ATRB_CHANNEL_FIELD(param.LO    , SHAPE.C.SIZE);
        param.D    := NEW_CONV_DATA_ATRB_CHANNEL_FIELD(param.C.HI+1, SHAPE.D.SIZE);
        param.X    := NEW_CONV_DATA_ATRB_CHANNEL_FIELD(param.D.HI+1, SHAPE.X.SIZE);
        param.Y    := NEW_CONV_DATA_ATRB_CHANNEL_FIELD(param.X.HI+1, SHAPE.Y.SIZE);
        param.HI   := param.Y.HI;
        param.SIZE := param.HI - param.LO + 1;
        return param;
    end function;

    -------------------------------------------------------------------------------
    --! @brief Convolution Data(一回の転送単位) の各種フィールドを定義する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_DATA_FIELD(
                  ELEM_BITS  :  integer;
                  INFO_BITS  :  integer;
                  SHAPE      :  IMAGE_SHAPE_TYPE)
                  return        CONV_DATA_FIELD_TYPE
    is
        variable  param      :  CONV_DATA_FIELD_TYPE;
    begin
        param.LO             := 0;
        param.ELEM_FIELD     := NEW_CONV_DATA_ELEM_FIELD(param.LO, ELEM_BITS  , SHAPE);
        param.ATRB_FIELD     := NEW_CONV_DATA_ATRB_FIELD(param.ELEM_FIELD.HI+1, SHAPE);
        if (INFO_BITS > 0) then
            param.INFO_FIELD := NEW_IMAGE_VECTOR_RANGE(param.ATRB_FIELD.HI+1, param.ATRB_FIELD.HI+INFO_BITS);
            param.HI         := param.INFO_FIELD.HI;
        else
            param.INFO_FIELD := NEW_IMAGE_VECTOR_RANGE(0);
            param.HI         := param.ATRB_FIELD.HI;
        end if;
        param.SIZE           := param.HI - param.LO + 1;
        return param;
    end function;

    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の各種パラメータを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS  :  integer;
                  INFO_BITS  :  integer := 0;
                  SHAPE      :  IMAGE_SHAPE_TYPE;
                  STRIDE     :  IMAGE_STREAM_STRIDE_PARAM_TYPE)
                  return        CONV_PIPELINE_PARAM_TYPE
    is
        variable  param      :  CONV_PIPELINE_PARAM_TYPE;
    begin
        param.ELEM_BITS      := ELEM_BITS;
        param.INFO_BITS      := INFO_BITS;
        param.SHAPE          := SHAPE;
        param.STRIDE         := STRIDE;
        param.DATA           := NEW_CONV_DATA_FIELD(
                                    ELEM_BITS => param.ELEM_BITS,
                                    INFO_BITS => param.INFO_BITS,
                                    SHAPE     => param.SHAPE
                                );
        return param;
    end function;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の各種パラメータを設定する関数(簡易版)
    -------------------------------------------------------------------------------
    function  NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS  :  integer;
                  INFO_BITS  :  integer := 0;
                  C          :  integer := 1;
                  D          :  integer := 1;
                  X          :  integer := 1;
                  Y          :  integer := 1)
                  return        CONV_PIPELINE_PARAM_TYPE
    is
    begin
        return NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS  => ELEM_BITS,
                  INFO_BITS  => INFO_BITS,
                  SHAPE      => NEW_IMAGE_SHAPE_CONSTANT(ELEM_BITS,C,D,X,Y),
                  STRIDE     => NEW_IMAGE_STREAM_STRIDE_PARAM(1,1)
               );
    end function;

    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline Data から要素を取り出す関数
    -------------------------------------------------------------------------------
    function  GET_ELEMENT_FROM_DATA(
                  PARAM      :  CONV_PIPELINE_PARAM_TYPE;
                  C          :  integer;
                  D          :  integer;
                  X          :  integer;
                  Y          :  integer;
                  DATA       :  std_logic_vector)
                  return        std_logic_vector
    is
        alias     input_data :  std_logic_vector(PARAM.DATA.SIZE           -1 downto 0) is DATA;
        variable  elem_data  :  std_logic_vector(PARAM.DATA.ELEM_FIELD.SIZE-1 downto 0);
        variable  element    :  std_logic_vector(PARAM.ELEM_BITS           -1 downto 0);
    begin
        elem_data := input_data(PARAM.DATA.ELEM_FIELD.HI downto PARAM.DATA.ELEM_FIELD.LO);
        element   := elem_data(((Y-PARAM.SHAPE.Y.LO)*PARAM.DATA.ELEM_FIELD.Y_SIZE +
                                (X-PARAM.SHAPE.X.LO)*PARAM.DATA.ELEM_FIELD.X_SIZE +
                                (D-PARAM.SHAPE.D.LO)*PARAM.DATA.ELEM_FIELD.D_SIZE +
                                (C-PARAM.SHAPE.C.LO)*PARAM.DATA.ELEM_FIELD.C_SIZE + 1)*PARAM.ELEM_BITS-1 downto
                               ((Y-PARAM.SHAPE.Y.LO)*PARAM.DATA.ELEM_FIELD.Y_SIZE +
                                (X-PARAM.SHAPE.X.LO)*PARAM.DATA.ELEM_FIELD.X_SIZE +
                                (D-PARAM.SHAPE.D.LO)*PARAM.DATA.ELEM_FIELD.D_SIZE +
                                (C-PARAM.SHAPE.C.LO)*PARAM.DATA.ELEM_FIELD.C_SIZE    )*PARAM.ELEM_BITS);
        return element;
    end function;

    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline Data に要素を追加するプロシージャ
    -------------------------------------------------------------------------------
    procedure SET_ELEMENT_TO_DATA(
                  PARAM      :  in    CONV_PIPELINE_PARAM_TYPE;
                  C          :  in    integer;
                  D          :  in    integer;
                  X          :  in    integer;
                  Y          :  in    integer;
                  ELEMENT    :  in    std_logic_vector;
        variable  DATA       :  inout std_logic_vector)
    is
    begin
        DATA(((Y-PARAM.SHAPE.Y.LO)*PARAM.DATA.ELEM_FIELD.Y_SIZE +
              (X-PARAM.SHAPE.X.LO)*PARAM.DATA.ELEM_FIELD.X_SIZE +
              (D-PARAM.SHAPE.D.LO)*PARAM.DATA.ELEM_FIELD.D_SIZE +
              (C-PARAM.SHAPE.C.LO)*PARAM.DATA.ELEM_FIELD.C_SIZE + 1)*PARAM.ELEM_BITS -1 + PARAM.DATA.ELEM_FIELD.LO downto
             ((Y-PARAM.SHAPE.Y.LO)*PARAM.DATA.ELEM_FIELD.Y_SIZE +
              (X-PARAM.SHAPE.X.LO)*PARAM.DATA.ELEM_FIELD.X_SIZE +
              (D-PARAM.SHAPE.D.LO)*PARAM.DATA.ELEM_FIELD.D_SIZE +
              (C-PARAM.SHAPE.C.LO)*PARAM.DATA.ELEM_FIELD.C_SIZE    )*PARAM.ELEM_BITS    + PARAM.DATA.ELEM_FIELD.LO) := ELEMENT;
    end procedure;

    function  UPDATE_IMAGE_SHAPE_SIDE(
                  I_SHAPE_SIDE      :  IMAGE_SHAPE_SIDE_TYPE;
                  BORDER_TYPE       :  IMAGE_STREAM_BORDER_TYPE;
                  KERNEL_LO         :  integer;
                  KERNEL_HI         :  integer;
                  FORCE_DATA_ATRB   :  boolean := FALSE)
                  return               IMAGE_SHAPE_SIDE_TYPE
    is
        variable  o_shape_side      :  IMAGE_SHAPE_SIDE_TYPE;
        variable  data_atrb         :  boolean;
    begin
        if (FORCE_DATA_ATRB) then
            data_atrb := TRUE;
        else
            data_atrb := I_SHAPE_SIDE.DATA_ATRB;
        end if;
        if I_SHAPE_SIDE.DICIDE_TYPE = IMAGE_SHAPE_SIDE_DICIDE_CONSTANT then
            if BORDER_TYPE = IMAGE_STREAM_BORDER_NONE then
                o_shape_side := NEW_IMAGE_SHAPE_SIDE_CONSTANT(I_SHAPE_SIDE.SIZE-(KERNEL_HI-KERNEL_LO), data_atrb);
            else
                o_shape_side := NEW_IMAGE_SHAPE_SIDE_CONSTANT(I_SHAPE_SIDE.SIZE, data_atrb);
            end if;
        else
                o_shape_side := NEW_IMAGE_SHAPE_SIDE_AUTO(I_SHAPE_SIDE.MAX_SIZE, data_atrb);
        end if;
        return o_shape_side;
    end function;
                 
    -------------------------------------------------------------------------------
    --! @brief Convolution の各種パラメータを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_PARAM(
                  KERNEL_SIZE       :  CONV_KERNEL_SIZE_TYPE;
                  STRIDE            :  IMAGE_STREAM_STRIDE_PARAM_TYPE;
                  I_STREAM          :  IMAGE_STREAM_PARAM_TYPE;
                  I_SHAPE           :  IMAGE_SHAPE_TYPE;
                  B_ELEM_BITS       :  integer ;
                  W_ELEM_BITS       :  integer ;
                  M_ELEM_BITS       :  integer ;
                  O_ELEM_BITS       :  integer ;
                  O_SHAPE_C         :  IMAGE_SHAPE_SIDE_TYPE;
                  C_UNROLL          :  integer := 1;
                  D_UNROLL          :  integer := 1;
                  X_UNROLL          :  integer := 1;
                  Y_UNROLL          :  integer := 1;
                  X_BORDER          :  IMAGE_STREAM_BORDER_TYPE := IMAGE_STREAM_BORDER_NONE;
                  Y_BORDER          :  IMAGE_STREAM_BORDER_TYPE := IMAGE_STREAM_BORDER_NONE)
                  return               CONV_PARAM_TYPE
    is
        variable  param             :  CONV_PARAM_TYPE;
        variable  a_shape_c         :  IMAGE_SHAPE_SIDE_TYPE; 
        variable  a_shape_d         :  IMAGE_SHAPE_SIDE_TYPE; 
        variable  a_shape_x         :  IMAGE_SHAPE_SIDE_TYPE; 
        variable  a_shape_y         :  IMAGE_SHAPE_SIDE_TYPE;
        variable  o_shape_d         :  IMAGE_SHAPE_SIDE_TYPE; 
        variable  o_shape_x         :  IMAGE_SHAPE_SIDE_TYPE; 
        variable  o_shape_y         :  IMAGE_SHAPE_SIDE_TYPE;
        variable  a_stream_x_size   :  integer;
        variable  a_stream_y_size   :  integer;
        variable  pipeline_shape_c  :  IMAGE_SHAPE_SIDE_TYPE;
        variable  pipeline_shape_d  :  IMAGE_SHAPE_SIDE_TYPE;
        variable  pipeline_shape_x  :  IMAGE_SHAPE_SIDE_TYPE;
        variable  pipeline_shape_y  :  IMAGE_SHAPE_SIDE_TYPE;
        variable  pipeline_stride   :  IMAGE_STREAM_STRIDE_PARAM_TYPE;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.KERNEL_SIZE := KERNEL_SIZE;
        param.STRIDE      := STRIDE;
        param.C_UNROLL    := C_UNROLL;
        param.D_UNROLL    := D_UNROLL;
        param.X_UNROLL    := X_UNROLL;
        param.Y_UNROLL    := Y_UNROLL;
        param.I_STREAM    := I_STREAM;
        param.I_SHAPE     := I_SHAPE;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        pipeline_shape_c  := NEW_IMAGE_SHAPE_SIDE_CONSTANT(C_UNROLL*KERNEL_SIZE.X.SIZE*KERNEL_SIZE.Y.SIZE);
        pipeline_shape_d  := NEW_IMAGE_SHAPE_SIDE_CONSTANT(D_UNROLL);
        pipeline_shape_x  := NEW_IMAGE_SHAPE_SIDE_CONSTANT(X_UNROLL);
        pipeline_shape_y  := NEW_IMAGE_SHAPE_SIDE_CONSTANT(Y_UNROLL);
        pipeline_stride   := NEW_IMAGE_STREAM_STRIDE_PARAM(X_UNROLL, Y_UNROLL);
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        a_stream_x_size   := KERNEL_SIZE.X.SIZE + STRIDE.X*(X_UNROLL-1);
        a_stream_y_size   := KERNEL_SIZE.Y.SIZE + STRIDE.Y*(Y_UNROLL-1);
        param.A_STREAM    := NEW_IMAGE_STREAM_PARAM(
                                 ELEM_BITS => I_STREAM.ELEM_BITS,
                                 SHAPE     => NEW_IMAGE_SHAPE(
                                                  ELEM_BITS => I_STREAM.ELEM_BITS,
                                                  C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(C_UNROLL),
                                                  D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(D_UNROLL),
                                                  X         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(KERNEL_SIZE.X.LO, KERNEL_SIZE.X.LO + a_stream_x_size - 1),
                                                  Y         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(KERNEL_SIZE.Y.LO, KERNEL_SIZE.Y.LO + a_stream_y_size - 1)
                                              ),
                                 STRIDE    => NEW_IMAGE_STREAM_STRIDE_PARAM(
                                                  X         => STRIDE.X + X_UNROLL,
                                                  Y         => STRIDE.Y + Y_UNROLL
                                              )
                             );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.B_STREAM    := NEW_IMAGE_STREAM_PARAM(
                                 ELEM_BITS => B_ELEM_BITS,
                                 SHAPE     => NEW_IMAGE_SHAPE(
                                                  ELEM_BITS => B_ELEM_BITS,
                                                  C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(0),
                                                  D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(D_UNROLL),
                                                  X         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(0),
                                                  Y         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(0)
                                              ),
                                 STRIDE    => NEW_IMAGE_STREAM_STRIDE_PARAM(
                                                  X         => 1,
                                                  Y         => 1
                                              )
                             );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.W_STREAM    := NEW_IMAGE_STREAM_PARAM(
                                 ELEM_BITS => W_ELEM_BITS,
                                 SHAPE     => NEW_IMAGE_SHAPE(
                                                  ELEM_BITS => W_ELEM_BITS,
                                                  C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(C_UNROLL),
                                                  D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(D_UNROLL),
                                                  X         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(KERNEL_SIZE.X.LO, KERNEL_SIZE.X.HI),
                                                  Y         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(KERNEL_SIZE.Y.LO, KERNEL_SIZE.Y.HI)
                                              ),
                                 STRIDE    => NEW_IMAGE_STREAM_STRIDE_PARAM(
                                                  X         => 1,
                                                  Y         => 1
                                              )
                             );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.A_PIPELINE  := NEW_CONV_PIPELINE_PARAM(
                                 ELEM_BITS => I_STREAM.ELEM_BITS,
                                 SHAPE     => NEW_IMAGE_SHAPE(
                                                  ELEM_BITS => I_STREAM.ELEM_BITS,
                                                  C         => pipeline_shape_c,
                                                  D         => pipeline_shape_d,
                                                  X         => pipeline_shape_x,
                                                  Y         => pipeline_shape_y
                                              ),
                                 STRIDE    => pipeline_stride
                             );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.W_PIPELINE  := NEW_CONV_PIPELINE_PARAM(
                                 ELEM_BITS => W_ELEM_BITS,
                                 SHAPE     => NEW_IMAGE_SHAPE(
                                                  ELEM_BITS => W_ELEM_BITS,
                                                  C         => pipeline_shape_c,
                                                  D         => pipeline_shape_d,
                                                  X         => pipeline_shape_x,
                                                  Y         => pipeline_shape_y
                                              ),
                                 STRIDE    => pipeline_stride
                             );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.M_PIPELINE  := NEW_CONV_PIPELINE_PARAM(
                                 ELEM_BITS => M_ELEM_BITS,
                                 SHAPE     => NEW_IMAGE_SHAPE(
                                                  ELEM_BITS => M_ELEM_BITS    ,
                                                  C         => pipeline_shape_c,
                                                  D         => pipeline_shape_d,
                                                  X         => pipeline_shape_x,
                                                  Y         => pipeline_shape_y
                                              ),
                                 STRIDE    => pipeline_stride
                             );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.O_PIPELINE  := NEW_CONV_PIPELINE_PARAM(
                                 ELEM_BITS => O_ELEM_BITS,
                                 SHAPE     => NEW_IMAGE_SHAPE(
                                                  ELEM_BITS => O_ELEM_BITS     ,
                                                  C         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(1),
                                                  D         => pipeline_shape_d,
                                                  X         => pipeline_shape_x,
                                                  Y         => pipeline_shape_y
                                              ),
                                 STRIDE    => pipeline_stride
                             );
            
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        param.O_STREAM    := NEW_IMAGE_STREAM_PARAM(
                                 ELEM_BITS => O_ELEM_BITS,
                                 SHAPE     => NEW_IMAGE_SHAPE(
                                                  ELEM_BITS => O_ELEM_BITS,
                                                  C         => pipeline_shape_d,
                                                  D         => NEW_IMAGE_SHAPE_SIDE_CONSTANT(0),
                                                  X         => pipeline_shape_x,
                                                  Y         => pipeline_shape_y
                                             ),
                                 STRIDE    => pipeline_stride
                             );
        ---------------------------------------------------------------------------
        -- 
        ---------------------------------------------------------------------------
        a_shape_c := UPDATE_IMAGE_SHAPE_SIDE(I_SHAPE.C, I_STREAM.BORDER_TYPE, 0               , 0               );
        a_shape_d := UPDATE_IMAGE_SHAPE_SIDE(O_SHAPE_C, I_STREAM.BORDER_TYPE, 0               , 0               );
        a_shape_x := UPDATE_IMAGE_SHAPE_SIDE(I_SHAPE.X, I_STREAM.BORDER_TYPE, KERNEL_SIZE.X.LO, KERNEL_SIZE.X.HI);
        a_shape_y := NEW_IMAGE_SHAPE_SIDE_AUTO(I_SHAPE.Y.MAX_SIZE, TRUE);
        param.A_SHAPE := NEW_IMAGE_SHAPE(
                             ELEM_BITS => I_STREAM.ELEM_BITS,
                             C         => a_shape_c,
                             D         => a_shape_d,
                             X         => a_shape_x,
                             Y         => a_shape_y
                         );
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        o_shape_d := NEW_IMAGE_SHAPE_SIDE_CONSTANT(0);
        o_shape_x := UPDATE_IMAGE_SHAPE_SIDE(I_SHAPE.X, I_STREAM.BORDER_TYPE, KERNEL_SIZE.X.LO, KERNEL_SIZE.X.HI);
        o_shape_y := UPDATE_IMAGE_SHAPE_SIDE(I_SHAPE.Y, I_STREAM.BORDER_TYPE, KERNEL_SIZE.Y.LO, KERNEL_SIZE.Y.HI);
        param.O_SHAPE := NEW_IMAGE_SHAPE(
                             ELEM_BITS => O_ELEM_BITS,
                             C         => O_SHAPE_C,
                             D         => o_shape_d,
                             X         => o_shape_x,
                             Y         => o_shape_y
                         );
        return param;
    end function;

    -------------------------------------------------------------------------------
    --! @brief イメージ入力 Stream を Convolution Pipeline に変換する関数
    -------------------------------------------------------------------------------
    function  CONV_PIPELINE_FROM_IMAGE_STREAM(
                  PIPELINE_PARAM    :  CONV_PIPELINE_PARAM_TYPE;
                  STREAM_PARAM      :  IMAGE_STREAM_PARAM_TYPE;
                  KERNEL_SIZE       :  CONV_KERNEL_SIZE_TYPE;
                  STRIDE            :  IMAGE_STREAM_STRIDE_PARAM_TYPE;
                  STREAM_DATA       :  std_logic_vector)
                  return               std_logic_vector
    is
        alias     i_data            :  std_logic_vector(STREAM_PARAM  .DATA.SIZE-1 downto 0) is STREAM_DATA;
        variable  o_data            :  std_logic_vector(PIPELINE_PARAM.DATA.SIZE-1 downto 0);
        variable  element           :  std_logic_vector(STREAM_PARAM  .ELEM_BITS-1 downto 0);
        variable  i_c_atrb          :  IMAGE_STREAM_ATRB_TYPE;
        variable  i_d_atrb          :  IMAGE_STREAM_ATRB_TYPE;
        variable  i_x_atrb          :  IMAGE_STREAM_ATRB_TYPE;
        variable  i_y_atrb          :  IMAGE_STREAM_ATRB_TYPE;
        variable  o_c_valid         :  std_logic_vector(PIPELINE_PARAM.DATA.ATRB_FIELD.C.VALID.SIZE-1 downto 0);
        variable  o_d_valid         :  std_logic_vector(PIPELINE_PARAM.DATA.ATRB_FIELD.D.VALID.SIZE-1 downto 0);
        variable  o_x_valid         :  std_logic_vector(PIPELINE_PARAM.DATA.ATRB_FIELD.X.VALID.SIZE-1 downto 0);
        variable  o_y_valid         :  std_logic_vector(PIPELINE_PARAM.DATA.ATRB_FIELD.Y.VALID.SIZE-1 downto 0);
    begin
        o_data := (others => '0');
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        o_c_valid := (others => '0');
        for o_y_pos in 0 to PIPELINE_PARAM.SHAPE.Y.SIZE-1 loop
        for o_x_pos in 0 to PIPELINE_PARAM.SHAPE.X.SIZE-1 loop
            for i_y_pos in 0 to STREAM_PARAM.SHAPE.Y.SIZE-1 loop
            for i_x_pos in 0 to STREAM_PARAM.SHAPE.X.SIZE-1 loop
            for i_c_pos in 0 to STREAM_PARAM.SHAPE.C.SIZE-1 loop
                element := GET_ELEMENT_FROM_IMAGE_STREAM_DATA(
                               PARAM   => STREAM_PARAM,
                               C       => i_c_pos + STREAM_PARAM.SHAPE.C.LO,
                               D       => 0,
                               X       => i_x_pos + STREAM_PARAM.SHAPE.X.LO + (o_x_pos * STRIDE.X),
                               Y       => i_y_pos + STREAM_PARAM.SHAPE.Y.LO + (o_y_pos * STRIDE.Y),
                               DATA    => i_data
                           );
                i_c_atrb := GET_ATRB_C_FROM_IMAGE_STREAM_DATA(
                               PARAM   => STREAM_PARAM,
                               C       => i_c_pos + STREAM_PARAM.SHAPE.C.LO,
                               DATA    => i_data
                           );
                i_x_atrb := GET_ATRB_X_FROM_IMAGE_STREAM_DATA(
                               PARAM   => STREAM_PARAM,
                               X       => i_x_pos + STREAM_PARAM.SHAPE.X.LO + (o_x_pos * STRIDE.X),
                               DATA    => i_data
                           );
                i_y_atrb := GET_ATRB_Y_FROM_IMAGE_STREAM_DATA(
                               PARAM   => STREAM_PARAM,
                               Y       => i_y_pos + STREAM_PARAM.SHAPE.Y.LO + (o_y_pos * STRIDE.Y),
                               DATA    => i_data
                            );
                for o_d_pos in 0 to PIPELINE_PARAM.SHAPE.D.SIZE-1 loop
                    SET_ELEMENT_TO_DATA(
                               PARAM   => PIPELINE_PARAM,
                               C       => i_c_pos + PIPELINE_PARAM.SHAPE.C.LO
                                        +(i_x_pos * STREAM_PARAM.SHAPE.C.SIZE)
                                        +(i_y_pos * STREAM_PARAM.SHAPE.C.SIZE * KERNEL_SIZE.X.SIZE),
                               D       => o_d_pos + PIPELINE_PARAM.SHAPE.D.LO,
                               X       => o_x_pos + PIPELINE_PARAM.SHAPE.X.LO,
                               Y       => o_y_pos + PIPELINE_PARAM.SHAPE.Y.LO,
                               ELEMENT => element,
                               DATA    => o_data
                    );
                end loop;
                if (i_c_atrb.VALID = TRUE and i_x_atrb.VALID = TRUE and i_y_atrb.VALID = TRUE) then
                    o_c_valid((i_c_pos                                                 ) +
                              (i_x_pos * STREAM_PARAM.SHAPE.C.SIZE                     ) +
                              (i_y_pos * STREAM_PARAM.SHAPE.C.SIZE * KERNEL_SIZE.X.SIZE)) := '1';
                end if;
            end loop;
            end loop;
            end loop;
        end loop;
        end loop;
        o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.C.VALID.HI downto PIPELINE_PARAM.DATA.ATRB_FIELD.C.VALID.LO) := o_c_valid;
        if (IMAGE_STREAM_DATA_IS_START_C(STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.C.START_POS) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.C.START_POS) := '0';
        end if;
        if (IMAGE_STREAM_DATA_IS_LAST_C( STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.C.LAST_POS ) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.C.LAST_POS ) := '0';
        end if;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        o_d_valid := (others => '0');
        for o_d_pos in 0 to PIPELINE_PARAM.SHAPE.D.SIZE-1 loop
                i_d_atrb := GET_ATRB_D_FROM_IMAGE_STREAM_DATA(
                                PARAM => STREAM_PARAM,
                                D     => o_d_pos + STREAM_PARAM.SHAPE.D.LO,
                                DATA  => i_data
                            );
                if (i_d_atrb.VALID) then
                    o_d_valid(o_d_pos) := '1';
                end if;
        end loop;
        o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.D.VALID.HI downto PIPELINE_PARAM.DATA.ATRB_FIELD.D.VALID.LO) := o_d_valid;
        if (IMAGE_STREAM_DATA_IS_START_D(STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.D.START_POS) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.D.START_POS) := '0';
        end if;
        if (IMAGE_STREAM_DATA_IS_LAST_D( STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.D.LAST_POS ) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.D.LAST_POS ) := '0';
        end if;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        o_x_valid := (others => '0');
        for o_x_pos in 0 to PIPELINE_PARAM.SHAPE.X.SIZE-1 loop
            for k_x_pos in 0 to KERNEL_SIZE.X.SIZE-1 loop
                i_x_atrb := GET_ATRB_X_FROM_IMAGE_STREAM_DATA(
                                PARAM => STREAM_PARAM,
                                X     => k_x_pos + STREAM_PARAM.SHAPE.X.LO + (o_x_pos * STRIDE.X),
                                DATA  => i_data
                            );
                if (i_x_atrb.VALID) then
                    o_x_valid(o_x_pos) := '1';
                end if;
            end loop;
        end loop;
        o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.X.VALID.HI downto PIPELINE_PARAM.DATA.ATRB_FIELD.X.VALID.LO) := o_x_valid;
        if (IMAGE_STREAM_DATA_IS_START_X(STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.X.START_POS) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.X.START_POS) := '0';
        end if;
        if (IMAGE_STREAM_DATA_IS_LAST_X( STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.X.LAST_POS ) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.X.LAST_POS ) := '0';
        end if;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        o_y_valid := (others => '0');
        for o_y_pos in 0 to PIPELINE_PARAM.SHAPE.Y.SIZE-1 loop
            for k_y_pos in 0 to KERNEL_SIZE.Y.SIZE-1 loop
                i_y_atrb := GET_ATRB_Y_FROM_IMAGE_STREAM_DATA(
                                PARAM => STREAM_PARAM,
                                Y     => k_y_pos + STREAM_PARAM.SHAPE.Y.LO + (o_y_pos * STRIDE.Y),
                                DATA  => i_data
                            );
                if (i_y_atrb.VALID) then
                    o_y_valid(o_y_pos) := '1';
                end if;
            end loop;
        end loop;
        o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.Y.VALID.HI downto PIPELINE_PARAM.DATA.ATRB_FIELD.Y.VALID.LO) := o_y_valid;
        if (IMAGE_STREAM_DATA_IS_START_Y(STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.Y.START_POS) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.Y.START_POS) := '0';
        end if;
        if (IMAGE_STREAM_DATA_IS_LAST_Y( STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.Y.LAST_POS ) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.Y.LAST_POS ) := '0';
        end if;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        return o_data;
    end function;

    -------------------------------------------------------------------------------
    --! @brief ウェイト入力 Stream を Convolution Pipeline に変換する関数
    -------------------------------------------------------------------------------
    function  CONV_PIPELINE_FROM_WEIGHT_STREAM(
                  PIPELINE_PARAM    :  CONV_PIPELINE_PARAM_TYPE;
                  STREAM_PARAM      :  IMAGE_STREAM_PARAM_TYPE;
                  KERNEL_SIZE       :  CONV_KERNEL_SIZE_TYPE;
                  STREAM_DATA       :  std_logic_vector)
                  return               std_logic_vector
    is
        alias     i_data            :  std_logic_vector(STREAM_PARAM  .DATA.SIZE-1 downto 0) is STREAM_DATA;
        variable  o_data            :  std_logic_vector(PIPELINE_PARAM.DATA.SIZE-1 downto 0);
        variable  element           :  std_logic_vector(STREAM_PARAM  .ELEM_BITS-1 downto 0);
        variable  i_c_atrb          :  IMAGE_STREAM_ATRB_TYPE;
        variable  i_d_atrb          :  IMAGE_STREAM_ATRB_TYPE;
        variable  i_x_atrb          :  IMAGE_STREAM_ATRB_TYPE;
        variable  i_y_atrb          :  IMAGE_STREAM_ATRB_TYPE;
        variable  o_c_valid         :  std_logic_vector(PIPELINE_PARAM.DATA.ATRB_FIELD.C.VALID.SIZE-1 downto 0);
        variable  o_d_valid         :  std_logic_vector(PIPELINE_PARAM.DATA.ATRB_FIELD.D.VALID.SIZE-1 downto 0);
        variable  o_x_valid         :  std_logic_vector(PIPELINE_PARAM.DATA.ATRB_FIELD.X.VALID.SIZE-1 downto 0);
        variable  o_y_valid         :  std_logic_vector(PIPELINE_PARAM.DATA.ATRB_FIELD.Y.VALID.SIZE-1 downto 0);
    begin
        o_data := (others => '0');
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        o_c_valid := (others => '0');
        for i_y_pos in 0 to STREAM_PARAM.SHAPE.Y.SIZE-1 loop
        for i_x_pos in 0 to STREAM_PARAM.SHAPE.X.SIZE-1 loop
        for i_c_pos in 0 to STREAM_PARAM.SHAPE.C.SIZE-1 loop
            for i_d_pos in 0 to STREAM_PARAM.SHAPE.D.SIZE-1 loop
                element := GET_ELEMENT_FROM_IMAGE_STREAM_DATA(
                               PARAM   => STREAM_PARAM,
                               C       => i_c_pos + STREAM_PARAM.SHAPE.C.LO,
                               D       => i_d_pos + STREAM_PARAM.SHAPE.D.LO,
                               X       => i_x_pos + STREAM_PARAM.SHAPE.X.LO,
                               Y       => i_y_pos + STREAM_PARAM.SHAPE.Y.LO,
                               DATA    => i_data
                            );
                for o_y_pos in 0 to PIPELINE_PARAM.SHAPE.Y.SIZE-1 loop
                for o_x_pos in 0 to PIPELINE_PARAM.SHAPE.X.SIZE-1 loop
                    SET_ELEMENT_TO_DATA(
                               PARAM   => PIPELINE_PARAM,
                               C       => i_c_pos + PIPELINE_PARAM.SHAPE.C.LO
                                        +(i_x_pos * STREAM_PARAM.SHAPE.C.SIZE)
                                        +(i_y_pos * STREAM_PARAM.SHAPE.C.SIZE * KERNEL_SIZE.X.SIZE),
                               D       => i_d_pos + PIPELINE_PARAM.SHAPE.D.LO,
                               X       => o_x_pos + PIPELINE_PARAM.SHAPE.X.LO,
                               Y       => o_y_pos + PIPELINE_PARAM.SHAPE.Y.LO,
                               ELEMENT => element,
                               DATA    => o_data
                    );
                end loop;
                end loop;
            end loop;
            i_c_atrb := GET_ATRB_C_FROM_IMAGE_STREAM_DATA(
                           PARAM   => STREAM_PARAM,
                           C       => i_c_pos + STREAM_PARAM.SHAPE.C.LO,
                           DATA    => i_data
                        );
            i_x_atrb := GET_ATRB_X_FROM_IMAGE_STREAM_DATA(
                           PARAM   => STREAM_PARAM,
                           X       => i_x_pos + STREAM_PARAM.SHAPE.X.LO,
                           DATA    => i_data
                        );
            i_y_atrb := GET_ATRB_Y_FROM_IMAGE_STREAM_DATA(
                           PARAM   => STREAM_PARAM,
                           Y       => i_y_pos + STREAM_PARAM.SHAPE.Y.LO,
                           DATA    => i_data
                        );
            if (i_c_atrb.VALID = TRUE and i_x_atrb.VALID = TRUE and i_y_atrb.VALID = TRUE) then
                o_c_valid((i_c_pos                                                 ) +
                          (i_x_pos * STREAM_PARAM.SHAPE.C.SIZE                     ) +
                          (i_y_pos * STREAM_PARAM.SHAPE.C.SIZE * KERNEL_SIZE.X.SIZE)) := '1';
            end if;
        end loop;
        end loop;
        end loop;
        o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.C.VALID.HI downto PIPELINE_PARAM.DATA.ATRB_FIELD.C.VALID.LO) := o_c_valid;
        if (IMAGE_STREAM_DATA_IS_START_C(STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.C.START_POS) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.C.START_POS) := '0';
        end if;
        if (IMAGE_STREAM_DATA_IS_LAST_C( STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.C.LAST_POS ) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.C.LAST_POS ) := '0';
        end if;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        o_d_valid := (others => '0');
        for o_d_pos in 0 to PIPELINE_PARAM.SHAPE.D.SIZE-1 loop
                i_d_atrb := GET_ATRB_D_FROM_IMAGE_STREAM_DATA(
                                PARAM => STREAM_PARAM,
                                D     => o_d_pos + STREAM_PARAM.SHAPE.D.LO,
                                DATA  => i_data
                            );
                if (i_d_atrb.VALID) then
                    o_d_valid(o_d_pos) := '1';
                end if;
        end loop;
        o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.D.VALID.HI downto PIPELINE_PARAM.DATA.ATRB_FIELD.D.VALID.LO) := o_d_valid;
        if (IMAGE_STREAM_DATA_IS_START_D(STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.D.START_POS) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.D.START_POS) := '0';
        end if;
        if (IMAGE_STREAM_DATA_IS_LAST_D( STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.D.LAST_POS ) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.D.LAST_POS ) := '0';
        end if;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        o_x_valid := (others => '0');
        for o_x_pos in 0 to PIPELINE_PARAM.SHAPE.X.SIZE-1 loop
            for k_x_pos in 0 to KERNEL_SIZE.X.SIZE-1 loop
                i_x_atrb := GET_ATRB_X_FROM_IMAGE_STREAM_DATA(
                                PARAM => STREAM_PARAM,
                                X     => k_x_pos + STREAM_PARAM.SHAPE.X.LO,
                                DATA  => i_data
                            );
                if (i_x_atrb.VALID) then
                    o_x_valid(o_x_pos) := '1';
                end if;
            end loop;
        end loop;
        o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.X.VALID.HI downto PIPELINE_PARAM.DATA.ATRB_FIELD.X.VALID.LO) := o_x_valid;
        if (IMAGE_STREAM_DATA_IS_START_X(STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.X.START_POS) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.X.START_POS) := '0';
        end if;
        if (IMAGE_STREAM_DATA_IS_LAST_X( STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.X.LAST_POS ) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.X.LAST_POS ) := '0';
        end if;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        o_y_valid := (others => '0');
        for o_y_pos in 0 to PIPELINE_PARAM.SHAPE.Y.SIZE-1 loop
            for k_y_pos in 0 to KERNEL_SIZE.Y.SIZE-1 loop
                i_y_atrb := GET_ATRB_Y_FROM_IMAGE_STREAM_DATA(
                                PARAM => STREAM_PARAM,
                                Y     => k_y_pos + STREAM_PARAM.SHAPE.Y.LO,
                                DATA  => i_data
                            );
                if (i_y_atrb.VALID) then
                    o_y_valid(o_y_pos) := '1';
                end if;
            end loop;
        end loop;
        o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.Y.VALID.HI downto PIPELINE_PARAM.DATA.ATRB_FIELD.Y.VALID.LO) := o_y_valid;
        if (IMAGE_STREAM_DATA_IS_START_Y(STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.Y.START_POS) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.Y.START_POS) := '0';
        end if;
        if (IMAGE_STREAM_DATA_IS_LAST_Y( STREAM_PARAM, i_data) = TRUE) then
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.Y.LAST_POS ) := '1';
        else
            o_data(PIPELINE_PARAM.DATA.ATRB_FIELD.Y.LAST_POS ) := '0';
        end if;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        return o_data;
    end function;
end package body;
