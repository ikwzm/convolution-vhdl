-----------------------------------------------------------------------------------
--!     @file    conv_int_adder.vhd
--!     @brief   Convolution Integer Adder Module
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
library CONVOLUTION;
use     CONVOLUTION.CONV_TYPES.all;
-----------------------------------------------------------------------------------
--! @brief Convolution Integer Adder Tree
-----------------------------------------------------------------------------------
entity  CONV_INT_ADDER is
    generic (
        I_PARAM         : CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,2,1,1,1);
        O_PARAM         : CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,1,1,1,1);
        QUEUE_SIZE      : integer := 2;
        SIGN            : boolean := TRUE
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
        I_DATA          : --! @brief INPUT CONVOLUTION WINDOW DATA :
                          --! ウィンドウデータ入力.
                          in  std_logic_vector(I_PARAM.DATA.SIZE-1 downto 0);
        I_VALID         : --! @brief INPUT CONVOLUTION WINDOW DATA VALID :
                          --! 入力ウィンドウデータ有効信号.
                          --! * I_DATAが有効であることを示す.
                          --! * I_VALID='1'and I_READY='1'でウィンドウデータがキュー
                          --!   に取り込まれる.
                          in  std_logic;
        I_READY         : --! @brief INPUT CONVOLUTION WINDOW DATA READY :
                          --! 入力ウィンドウデータレディ信号.
                          --! * キューが次のウィンドウデータを入力出来ることを示す.
                          --! * I_VALID='1'and I_READY='1'でウィンドウデータがキュー
                          --!   に取り込まれる.
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA          : --! @brief OUTPUT CONVOLUTION WINDOW DATA :
                          --! ウィンドウデータ出力.
                          out std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
        O_VALID         : --! @brief OUTPUT CONVOLUTION WINDOW DATA VALID :
                          --! 出力ウィンドウデータ有効信号.
                          --! * O_DATA が有効であることを示す.
                          --! * O_VALID='1'and O_READY='1'でウィンドウデータがキュー
                          --!   から取り除かれる.
                          out std_logic;
        O_READY         : --! @brief OUTPUT CONVOLUTION WINDOW DATA READY :
                          --! 出力ウィンドウデータレディ信号.
                          --! * キューから次のウィンドウデータを取り除く準備が出来て
                          --!   いることを示す.
                          --! * O_VALID='1'and O_READY='1'でウィンドウデータがキュー
                          --!   から取り除かれる.
                          in  std_logic
    );
end CONV_INT_ADDER;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library CONVOLUTION;
use     CONVOLUTION.CONV_TYPES.all;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.PIPELINE_REGISTER;
architecture RTL of CONV_INT_ADDER is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   I_ELEM_TYPE     is std_logic_vector(I_PARAM.ELEM_BITS-1 downto 0);
    type      I_ELEM_VECTOR   is array(0 to I_PARAM.SHAPE.Y.SIZE-1,
                                       0 to I_PARAM.SHAPE.X.SIZE-1,
                                       0 to I_PARAM.SHAPE.D.SIZE-1,
                                       0 to I_PARAM.SHAPE.C.SIZE-1) of I_ELEM_TYPE;
    signal    i_elem          :  I_ELEM_VECTOR;
    signal    i_c_valid       :  std_logic_vector(I_PARAM.SHAPE.C.SIZE-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   O_ELEM_TYPE     is std_logic_vector(O_PARAM.ELEM_BITS-1 downto 0);
    type      O_ELEM_VECTOR   is array(0 to O_PARAM.SHAPE.Y.SIZE-1,
                                       0 to O_PARAM.SHAPE.X.SIZE-1,
                                       0 to O_PARAM.SHAPE.D.SIZE-1,
                                       0 to O_PARAM.SHAPE.C.SIZE-1) of O_ELEM_TYPE;
    signal    t_elem          :  O_ELEM_VECTOR;
    signal    t_c_valid       :  std_logic_vector(O_PARAM.SHAPE.C.SIZE-1 downto 0);
    signal    t_data          :  std_logic_vector(O_PARAM.DATA.SIZE-1    downto 0);
begin
    -------------------------------------------------------------------------------
    -- i_elem    :
    -- i_c_valid :
    -------------------------------------------------------------------------------
    process (I_DATA) begin
        for y in 0 to I_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to I_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to I_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to I_PARAM.SHAPE.C.SIZE-1 loop
            i_elem(y,x,d,c) <= GET_ELEMENT_FROM_DATA(I_PARAM, c, d, x, y, I_DATA);
        end loop;
        end loop;
        end loop;
        end loop;
        i_c_valid <= I_DATA(I_PARAM.DATA.ATRB_C_FIELD.VALID.HI downto I_PARAM.DATA.ATRB_C_FIELD.VALID.LO);
    end process;
    -------------------------------------------------------------------------------
    -- t_elem    :
    -- t_c_valid :
    -------------------------------------------------------------------------------
    process(i_elem, i_c_valid)
        variable a_valid :  std_logic;
        variable a_elem  :  std_logic_vector(I_PARAM.ELEM_BITS-1 downto 0);
        variable b_valid :  std_logic;
        variable b_elem  :  std_logic_vector(I_PARAM.ELEM_BITS-1 downto 0);
    begin
        for y in 0 to O_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to O_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to O_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to O_PARAM.SHAPE.C.SIZE-1 loop
            if (c*2+0 < I_PARAM.SHAPE.C.SIZE) then
                a_elem  := i_elem(y,x,d,c*2+0);
            else
                a_elem  := (others => '0');
            end if;
            if (c*2+1 < I_PARAM.SHAPE.C.SIZE) then
                b_elem  := i_elem(y,x,d,c*2+1);
            else
                b_elem  := (others => '0');
            end if;
            if (SIGN) then
                t_elem(y,x,d,c) <= std_logic_vector(resize(to_01(  signed(a_elem)), O_PARAM.ELEM_BITS) +
                                                    resize(to_01(  signed(b_elem)), O_PARAM.ELEM_BITS));
            else
                t_elem(y,x,d,c) <= std_logic_vector(resize(to_01(unsigned(a_elem)), O_PARAM.ELEM_BITS) +
                                                    resize(to_01(unsigned(b_elem)), O_PARAM.ELEM_BITS));
            end if;
        end loop;
        end loop;
        end loop;
        end loop;
        for c in 0 to O_PARAM.SHAPE.C.SIZE-1 loop
            if (c*2+0 < I_PARAM.SHAPE.C.SIZE) then
                a_valid := i_c_valid(c*2+0);
            else
                a_valid := '0';
            end if;
            if (c*2+1 < I_PARAM.SHAPE.C.SIZE) then
                b_valid := i_c_valid(c*2+1);
            else
                b_valid := '0';
            end if;
            t_c_valid(c) <= a_valid or b_valid;
        end loop;
    end process;
    -------------------------------------------------------------------------------
    -- t_data    :
    -------------------------------------------------------------------------------
    process (t_elem, t_c_valid, I_DATA)
        variable data :  std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
    begin
        for y in 0 to O_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to O_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to O_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to O_PARAM.SHAPE.C.SIZE-1 loop
            SET_ELEMENT_TO_DATA(O_PARAM, c, d, x, y, t_elem(y,x,d,c), data);
        end loop;        
        end loop;        
        end loop;        
        end loop;
        data(O_PARAM.DATA.ATRB_C_FIELD.VALID.HI downto O_PARAM.DATA.ATRB_C_FIELD.VALID.LO) := t_c_valid;
        data(O_PARAM.DATA.ATRB_C_FIELD.START_POS)                                          := I_DATA(I_PARAM.DATA.ATRB_C_FIELD.START_POS);
        data(O_PARAM.DATA.ATRB_C_FIELD.LAST_POS )                                          := I_DATA(I_PARAM.DATA.ATRB_C_FIELD.LAST_POS );
        data(O_PARAM.DATA.ATRB_D_FIELD.HI downto O_PARAM.DATA.ATRB_D_FIELD.LO) := I_DATA(I_PARAM.DATA.ATRB_D_FIELD.HI downto I_PARAM.DATA.ATRB_D_FIELD.LO);
        data(O_PARAM.DATA.ATRB_X_FIELD.HI downto O_PARAM.DATA.ATRB_X_FIELD.LO) := I_DATA(I_PARAM.DATA.ATRB_X_FIELD.HI downto I_PARAM.DATA.ATRB_X_FIELD.LO);
        data(O_PARAM.DATA.ATRB_Y_FIELD.HI downto O_PARAM.DATA.ATRB_Y_FIELD.LO) := I_DATA(I_PARAM.DATA.ATRB_Y_FIELD.HI downto I_PARAM.DATA.ATRB_Y_FIELD.LO);
        if (O_PARAM.INFO_BITS > 0) then
            data(O_PARAM.DATA.INFO_FIELD.HI downto O_PARAM.DATA.INFO_FIELD.LO) := I_DATA(I_PARAM.DATA.INFO_FIELD.HI   downto I_PARAM.DATA.INFO_FIELD.LO  );
        end if;
        t_data <= data;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    QUEUE: PIPELINE_REGISTER                   -- 
        generic map (                          -- 
            QUEUE_SIZE  => QUEUE_SIZE        , --
            WORD_BITS   => O_PARAM.DATA.SIZE   -- 
        )                                      -- 
        port map (                             -- 
            CLK         => CLK               , -- In  :
            RST         => RST               , -- In  :
            CLR         => CLR               , -- In  :
            I_WORD      => t_data            , -- In  :
            I_VAL       => I_VALID           , -- In  :
            I_RDY       => I_READY           , -- Out :
            Q_WORD      => O_DATA            , -- Out :
            Q_VAL       => O_VALID           , -- Out :
            Q_RDY       => O_READY           , -- In  :
            BUSY        => open                -- Out :
        );                                     -- 
end RTL;
