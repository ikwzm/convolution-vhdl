-----------------------------------------------------------------------------------
--!     @file    conv_types.vhd
--!     @brief   Convolution Engine Types Package.
--!     @version 0.1.0
--!     @date    2019/1/15
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
-----------------------------------------------------------------------------------
--! @brief Convolution Engine で使用する各種タイプ/定数を定義しているパッケージ.
-----------------------------------------------------------------------------------
package CONV_TYPES is
    -------------------------------------------------------------------------------
    --! @brief Vector(一次元) の各種パラメータを定義するレコードタイプ.
    -------------------------------------------------------------------------------
    type      CONV_VECTOR_RANGE_TYPE is record
                  LO                :  integer;  -- Vector のインデックスの最小値
                  HI                :  integer;  -- Vector のインデックスの最大値
                  SIZE              :  integer;  -- Vector の大きさ
    end record;
    -------------------------------------------------------------------------------
    --! @brief Vector の各種パラメータを設定する関数群
    -------------------------------------------------------------------------------
    function  NEW_CONV_VECTOR_RANGE(LO,HI:integer) return CONV_VECTOR_RANGE_TYPE;
    function  NEW_CONV_VECTOR_RANGE(SIZE :integer) return CONV_VECTOR_RANGE_TYPE;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の形(各辺の大きさ)を定義するレコードタイプ.
    -------------------------------------------------------------------------------
    type      CONV_PIPELINE_SHAPE_PARAM_TYPE is record
                  C                 :  CONV_VECTOR_RANGE_TYPE;  -- Input  Channel 配列の範囲
                  D                 :  CONV_VECTOR_RANGE_TYPE;  -- Output Channel 配列の範囲
                  X                 :  CONV_VECTOR_RANGE_TYPE;  -- X 方向の配列の範囲
                  Y                 :  CONV_VECTOR_RANGE_TYPE;  -- Y 方向の配列の範囲
    end record;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の形(各辺の大きさ)を設定する関数群
    -------------------------------------------------------------------------------
    function  NEW_CONV_PIPELINE_SHAPE_PARAM(C,D,X,Y:CONV_VECTOR_RANGE_TYPE) return CONV_PIPELINE_SHAPE_PARAM_TYPE;
    function  NEW_CONV_PIPELINE_SHAPE_PARAM(C,D,X,Y:integer               ) return CONV_PIPELINE_SHAPE_PARAM_TYPE;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の各種属性のフィールドを定義するレコードタイプ.
    -------------------------------------------------------------------------------
    type      CONV_PIPELINE_DATA_ATRB_FIELD_TYPE is record
                   VALID             :  CONV_VECTOR_RANGE_TYPE;
                   START_POS         :  integer;
                   LAST_POS          :  integer;
                   LO                :  integer;
                   HI                :  integer;
                   SIZE              :  integer;
    end record;
    -------------------------------------------------------------------------------
    --! @brief Convolution Data(一回の転送単位) の各種パラメータを定義するレコードタイプ.
    -------------------------------------------------------------------------------
    type      CONV_PIPELINE_DATA_PARAM_TYPE is record
                  LO                :  integer;
                  HI                :  integer;
                  SIZE              :  integer;
                  ELEM_FIELD        :  CONV_VECTOR_RANGE_TYPE;
                  INFO_FIELD        :  CONV_VECTOR_RANGE_TYPE;
                  ATRB_FIELD        :  CONV_VECTOR_RANGE_TYPE;
                  ATRB_C_FIELD      :  CONV_PIPELINE_DATA_ATRB_FIELD_TYPE;
                  ATRB_D_FIELD      :  CONV_PIPELINE_DATA_ATRB_FIELD_TYPE;
                  ATRB_X_FIELD      :  CONV_PIPELINE_DATA_ATRB_FIELD_TYPE;
                  ATRB_Y_FIELD      :  CONV_PIPELINE_DATA_ATRB_FIELD_TYPE;
    end record;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の各種パラメータを定義するレコードタイプ.
    -------------------------------------------------------------------------------
    type      CONV_PIPELINE_PARAM_TYPE is record
                  ELEM_BITS         :  integer;  -- 1要素(Element)のビット数
                  INFO_BITS         :  integer;  -- その他情報のビット数
                  SHAPE             :  CONV_PIPELINE_SHAPE_PARAM_TYPE;
                  DATA              :  CONV_PIPELINE_DATA_PARAM_TYPE;
    end record;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の各種パラメータをを設定する関数群
    -------------------------------------------------------------------------------
    function  NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS         :  integer;
                  INFO_BITS         :  integer;
                  SHAPE             :  CONV_PIPELINE_SHAPE_PARAM_TYPE)
                  return               CONV_PIPELINE_PARAM_TYPE;
    function  NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS         :  integer;
                  INFO_BITS         :  integer;
                  C                 :  CONV_VECTOR_RANGE_TYPE;
                  D                 :  CONV_VECTOR_RANGE_TYPE;
                  X                 :  CONV_VECTOR_RANGE_TYPE;
                  Y                 :  CONV_VECTOR_RANGE_TYPE)
                  return               CONV_PIPELINE_PARAM_TYPE;
    function  NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS         :  integer;
                  INFO_BITS         :  integer;
                  C                 :  integer;
                  D                 :  integer;
                  X                 :  integer;
                  Y                 :  integer)
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
    --! @brief Convolution D Channel Vector の各種パラメータを定義するレコードタイプ.
    -------------------------------------------------------------------------------
    type      CONV_D_VECTOR_PARAM_TYPE is record
                  ELEM_BITS         :  integer;  -- 1要素(Element)のビット数
                  INFO_BITS         :  integer;  -- その他情報のビット数
                  SHAPE             :  CONV_PIPELINE_SHAPE_PARAM_TYPE;
                  DATA              :  CONV_PIPELINE_DATA_PARAM_TYPE;
    end record;
    -------------------------------------------------------------------------------
    --! @brief Convolution D Channel Vector の各種パラメータをを設定する関数群
    -------------------------------------------------------------------------------
    function  NEW_CONV_D_VECTOR_PARAM(
                  ELEM_BITS         :  integer;
                  INFO_BITS         :  integer;
                  SHAPE             :  CONV_PIPELINE_SHAPE_PARAM_TYPE)
                  return               CONV_D_VECTOR_PARAM_TYPE;
    function  NEW_CONV_D_VECTOR_PARAM(
                  ELEM_BITS         :  integer;
                  INFO_BITS         :  integer;
                  D                 :  CONV_VECTOR_RANGE_TYPE)
                  return               CONV_D_VECTOR_PARAM_TYPE;
    function  NEW_CONV_D_VECTOR_PARAM(
                  ELEM_BITS         :  integer;
                  INFO_BITS         :  integer;
                  D                 :  integer)
                  return               CONV_D_VECTOR_PARAM_TYPE;
    -------------------------------------------------------------------------------
    --! @brief Convolution D Vector Data から要素を取り出す関数
    -------------------------------------------------------------------------------
    function  GET_ELEMENT_FROM_DATA(
                  PARAM             :  CONV_D_VECTOR_PARAM_TYPE;
                  D                 :  integer;
                  DATA              :  std_logic_vector)
                  return               std_logic_vector;
    -------------------------------------------------------------------------------
    --! @brief Convolution D Vector Data に要素を追加するプロシージャ
    -------------------------------------------------------------------------------
    procedure SET_ELEMENT_TO_DATA(
                  PARAM             :  in    CONV_D_VECTOR_PARAM_TYPE;
                  D                 :  in    integer;
                  ELEMENT           :  in    std_logic_vector;
        variable  DATA              :  inout std_logic_vector);
end CONV_TYPES;
-----------------------------------------------------------------------------------
--! @brief Image の各種タイプ/定数を定義しているパッケージ.
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
package body CONV_TYPES is
    -------------------------------------------------------------------------------
    --! @brief Vector の各種パラメータを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_VECTOR_RANGE(LO,HI:integer) return CONV_VECTOR_RANGE_TYPE
    is
        variable param :  CONV_VECTOR_RANGE_TYPE;
    begin
        param.LO   := LO;
        param.HI   := HI;
        param.SIZE := HI-LO+1;
        return param;
    end function;
    -------------------------------------------------------------------------------
    --! @brief Vector の各種パラメータを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_VECTOR_RANGE(SIZE:integer) return CONV_VECTOR_RANGE_TYPE
    is
        variable param :  CONV_VECTOR_RANGE_TYPE;
    begin
        return NEW_CONV_VECTOR_RANGE(0, SIZE-1);
    end function;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の形(各辺の大きさ)を設定する関数群
    -------------------------------------------------------------------------------
    function  NEW_CONV_PIPELINE_SHAPE_PARAM(C,D,X,Y:CONV_VECTOR_RANGE_TYPE) return CONV_PIPELINE_SHAPE_PARAM_TYPE
    is
        variable param :  CONV_PIPELINE_SHAPE_PARAM_TYPE;
    begin
        param.C := C;
        param.D := D;
        param.X := X;
        param.Y := Y;
        return param;
    end function;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の形(各辺の大きさ)を設定する関数群
    -------------------------------------------------------------------------------
    function  NEW_CONV_PIPELINE_SHAPE_PARAM(C,D,X,Y:integer               ) return CONV_PIPELINE_SHAPE_PARAM_TYPE
    is
    begin
        return  NEW_CONV_PIPELINE_SHAPE_PARAM(
                    C => NEW_CONV_VECTOR_RANGE(C),
                    D => NEW_CONV_VECTOR_RANGE(D),
                    X => NEW_CONV_VECTOR_RANGE(X),
                    Y => NEW_CONV_VECTOR_RANGE(Y)
                    );
    end function;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の属性フィールドパラメータを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_PIPELINE_DATA_ATRB_FIELD(
                  PREV_HI   :  integer;
                  SIZE      :  integer)
                  return       CONV_PIPELINE_DATA_ATRB_FIELD_TYPE
    is
        variable param      :  CONV_PIPELINE_DATA_ATRB_FIELD_TYPE;
    begin
        param.VALID.LO  := PREV_HI+1;
        param.VALID.HI  := param.VALID.LO  + SIZE-1;
        param.START_POS := param.VALID.HI  + 1;
        param.LAST_POS  := param.START_POS + 1;
        param.LO        := param.VALID.LO;
        param.HI        := param.LAST_POS;
        param.SIZE      := param.HI - param.LO + 1;
        return param;
    end function;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline のデータフィールドパラメータを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_PIPELINE_DATA_PARAM(
                  ELEM_BITS  :  integer;
                  INFO_BITS  :  integer;
                  SHAPE      :  CONV_PIPELINE_SHAPE_PARAM_TYPE)
                  return        CONV_PIPELINE_DATA_PARAM_TYPE
    is
        variable  param      :  CONV_PIPELINE_DATA_PARAM_TYPE;
    begin
        param.ELEM_FIELD     := NEW_CONV_VECTOR_RANGE(ELEM_BITS);
        param.ATRB_C_FIELD   := NEW_CONV_PIPELINE_DATA_ATRB_FIELD(param.ELEM_FIELD.HI  , SHAPE.C.SIZE);
        param.ATRB_D_FIELD   := NEW_CONV_PIPELINE_DATA_ATRB_FIELD(param.ATRB_C_FIELD.HI, SHAPE.D.SIZE);
        param.ATRB_X_FIELD   := NEW_CONV_PIPELINE_DATA_ATRB_FIELD(param.ATRB_D_FIELD.HI, SHAPE.X.SIZE);
        param.ATRB_Y_FIELD   := NEW_CONV_PIPELINE_DATA_ATRB_FIELD(param.ATRB_Y_FIELD.HI, SHAPE.Y.SIZE);
        param.ATRB_FIELD     := NEW_CONV_VECTOR_RANGE(param.ATRB_C_FIELD.LO,
                                                      param.ATRB_Y_FIELD.HI);
        param.LO             := param.ELEM_FIELD.LO;
        if (INFO_BITS > 0) then
            param.INFO_FIELD := NEW_CONV_VECTOR_RANGE(param.ATRB_FIELD.HI+1, param.ATRB_FIELD.HI+INFO_BITS);
            param.HI         := param.INFO_FIELD.HI;
        else
            param.INFO_FIELD := NEW_CONV_VECTOR_RANGE(0);
            param.HI         := param.ATRB_FIELD.HI;
        end if;
        param.SIZE           := param.HI - param.LO + 1;
        return param;
    end function;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の各種パラメータをを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS  :  integer;
                  INFO_BITS  :  integer;
                  SHAPE      :  CONV_PIPELINE_SHAPE_PARAM_TYPE)
                  return        CONV_PIPELINE_PARAM_TYPE
    is
        variable  param      :  CONV_PIPELINE_PARAM_TYPE;
    begin
        param.ELEM_BITS      := ELEM_BITS;
        param.INFO_BITS      := INFO_BITS;
        param.SHAPE          := SHAPE;
        param.DATA           := NEW_CONV_PIPELINE_DATA_PARAM(
                                    ELEM_BITS => param.ELEM_BITS * param.SHAPE.C.SIZE * param.SHAPE.D.SIZE * param.SHAPE.X.SIZE * param.SHAPE.Y.SIZE,
                                    INFO_BITS => param.INFO_BITS,
                                    SHAPE     => param.SHAPE
                                );
        return param;
    end function;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の各種パラメータをを設定する関数(簡易版)
    -------------------------------------------------------------------------------
    function  NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS  :  integer;
                  INFO_BITS  :  integer;
                  C          :  CONV_VECTOR_RANGE_TYPE;
                  D          :  CONV_VECTOR_RANGE_TYPE;
                  X          :  CONV_VECTOR_RANGE_TYPE;
                  Y          :  CONV_VECTOR_RANGE_TYPE)
                  return        CONV_PIPELINE_PARAM_TYPE
    is
    begin
        return NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS  => ELEM_BITS,
                  INFO_BITS  => INFO_BITS,
                  SHAPE      => NEW_CONV_PIPELINE_SHAPE_PARAM(C,D,X,Y)
               );
    end function;
    -------------------------------------------------------------------------------
    --! @brief Convolution Pipeline の各種パラメータをを設定する関数(簡易版)
    -------------------------------------------------------------------------------
    function  NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS  :  integer;
                  INFO_BITS  :  integer;
                  C          :  integer;
                  D          :  integer;
                  X          :  integer;
                  Y          :  integer)
                  return        CONV_PIPELINE_PARAM_TYPE
    is
    begin
        return NEW_CONV_PIPELINE_PARAM(
                  ELEM_BITS  => ELEM_BITS,
                  INFO_BITS  => INFO_BITS,
                  SHAPE      => NEW_CONV_PIPELINE_SHAPE_PARAM(C,D,X,Y)
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
        constant  Y_SIZE     :  integer := PARAM.SHAPE.X.SIZE*PARAM.SHAPE.D.SIZE*PARAM.SHAPE.C.SIZE*1;
        constant  X_SIZE     :  integer :=                    PARAM.SHAPE.D.SIZE*PARAM.SHAPE.C.SIZE*1;
        constant  D_SIZE     :  integer :=                                       PARAM.SHAPE.C.SIZE*1;
        constant  C_SIZE     :  integer :=                                                          1;
    begin
        elem_data := input_data(PARAM.DATA.ELEM_FIELD.HI downto PARAM.DATA.ELEM_FIELD.LO);
        element   := elem_data(((Y-PARAM.SHAPE.Y.LO)*Y_SIZE +
                                (X-PARAM.SHAPE.X.LO)*X_SIZE +
                                (D-PARAM.SHAPE.D.LO)*D_SIZE +
                                (C-PARAM.SHAPE.C.LO)*C_SIZE + 1)*PARAM.ELEM_BITS-1 downto
                               ((Y-PARAM.SHAPE.Y.LO)*Y_SIZE +
                                (X-PARAM.SHAPE.X.LO)*X_SIZE +
                                (D-PARAM.SHAPE.D.LO)*D_SIZE +
                                (C-PARAM.SHAPE.C.LO)*C_SIZE    )*PARAM.ELEM_BITS);
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
        constant  Y_SIZE     :  integer := PARAM.SHAPE.X.SIZE*PARAM.SHAPE.D.SIZE*PARAM.SHAPE.C.SIZE*1;
        constant  X_SIZE     :  integer :=                    PARAM.SHAPE.D.SIZE*PARAM.SHAPE.C.SIZE*1;
        constant  D_SIZE     :  integer :=                                       PARAM.SHAPE.C.SIZE*1;
        constant  C_SIZE     :  integer :=                                                          1;
    begin
        DATA(((Y-PARAM.SHAPE.Y.LO)*Y_SIZE +
              (X-PARAM.SHAPE.X.LO)*X_SIZE +
              (D-PARAM.SHAPE.D.LO)*D_SIZE +
              (C-PARAM.SHAPE.C.LO)*C_SIZE + 1)*PARAM.ELEM_BITS -1 + PARAM.DATA.ELEM_FIELD.LO downto
             ((Y-PARAM.SHAPE.Y.LO)*Y_SIZE +
              (X-PARAM.SHAPE.X.LO)*X_SIZE +
              (D-PARAM.SHAPE.D.LO)*D_SIZE +
              (C-PARAM.SHAPE.C.LO)*C_SIZE    )*PARAM.ELEM_BITS    + PARAM.DATA.ELEM_FIELD.LO) := ELEMENT;
    end procedure;

    -------------------------------------------------------------------------------
    --! @brief Convolution D Channel Vector の各種パラメータをを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_D_VECTOR_PARAM(
                  ELEM_BITS  :  integer;
                  INFO_BITS  :  integer;
                  SHAPE      :  CONV_PIPELINE_SHAPE_PARAM_TYPE)
                  return        CONV_D_VECTOR_PARAM_TYPE
    is
        variable  param      :  CONV_D_VECTOR_PARAM_TYPE;
    begin
        param.ELEM_BITS      := ELEM_BITS;
        param.INFO_BITS      := INFO_BITS;
        param.SHAPE          := SHAPE;
        param.DATA           := NEW_CONV_PIPELINE_DATA_PARAM(
                                    ELEM_BITS => param.ELEM_BITS * param.SHAPE.D.SIZE,
                                    INFO_BITS => param.INFO_BITS,
                                    SHAPE     => param.SHAPE
                                );
        return param;
    end function;
    -------------------------------------------------------------------------------
    --! @brief Convolution D Channel Vector の各種パラメータをを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_D_VECTOR_PARAM(
                  ELEM_BITS         :  integer;
                  INFO_BITS         :  integer;
                  D                 :  CONV_VECTOR_RANGE_TYPE)
                  return               CONV_D_VECTOR_PARAM_TYPE
    is
    begin
        return NEW_CONV_D_VECTOR_PARAM(
                  ELEM_BITS         => ELEM_BITS,
                  INFO_BITS         => INFO_BITS,
                  SHAPE             => NEW_CONV_PIPELINE_SHAPE_PARAM(
                                           C => NEW_CONV_VECTOR_RANGE(1),
                                           D => D                       ,
                                           X => NEW_CONV_VECTOR_RANGE(1),
                                           Y => NEW_CONV_VECTOR_RANGE(1)
                                       )
               );
    end function;
    -------------------------------------------------------------------------------
    --! @brief Convolution D Channel Vector の各種パラメータをを設定する関数
    -------------------------------------------------------------------------------
    function  NEW_CONV_D_VECTOR_PARAM(
                  ELEM_BITS         :  integer;
                  INFO_BITS         :  integer;
                  D                 :  integer)
                  return               CONV_D_VECTOR_PARAM_TYPE
    is
    begin
        return NEW_CONV_D_VECTOR_PARAM(
                  ELEM_BITS         => ELEM_BITS,
                  INFO_BITS         => INFO_BITS,
                  SHAPE             => NEW_CONV_PIPELINE_SHAPE_PARAM(
                                           C => NEW_CONV_VECTOR_RANGE(1),
                                           D => NEW_CONV_VECTOR_RANGE(D),
                                           X => NEW_CONV_VECTOR_RANGE(1),
                                           Y => NEW_CONV_VECTOR_RANGE(1)
                                       )
               );
    end function;

    -------------------------------------------------------------------------------
    --! @brief Convolution D Channel Vector の Data から要素を取り出す関数
    -------------------------------------------------------------------------------
    function  GET_ELEMENT_FROM_DATA(
                  PARAM             :  CONV_D_VECTOR_PARAM_TYPE;
                  D                 :  integer;
                  DATA              :  std_logic_vector)
                  return               std_logic_vector
    is
        alias     input_data        :  std_logic_vector(PARAM.DATA.SIZE           -1 downto 0) is DATA;
        variable  elem_data         :  std_logic_vector(PARAM.DATA.ELEM_FIELD.SIZE-1 downto 0);
        variable  element           :  std_logic_vector(PARAM.ELEM_BITS           -1 downto 0);
    begin
        elem_data := input_data(PARAM.DATA.ELEM_FIELD.HI downto PARAM.DATA.ELEM_FIELD.LO);
        element   := elem_data(((D-PARAM.SHAPE.D.LO) + 1)*PARAM.ELEM_BITS-1 downto
                               ((D-PARAM.SHAPE.D.LO)    )*PARAM.ELEM_BITS);
        return element;
    end function;
    -------------------------------------------------------------------------------
    --! @brief Convolution D Channel Vector の Data に要素を追加するプロシージャ
    -------------------------------------------------------------------------------
    procedure SET_ELEMENT_TO_DATA(
                  PARAM             :  in    CONV_D_VECTOR_PARAM_TYPE;
                  D                 :  in    integer;
                  ELEMENT           :  in    std_logic_vector;
        variable  DATA              :  inout std_logic_vector)
    is
    begin 
        DATA(((D-PARAM.SHAPE.D.LO) + 1)*PARAM.ELEM_BITS-1 downto
             ((D-PARAM.SHAPE.D.LO)    )*PARAM.ELEM_BITS) := ELEMENT;
    end procedure;
end package body;
