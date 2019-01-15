-----------------------------------------------------------------------------------
--!     @file    conv_int_adder_tree.vhd
--!     @brief   Convolution Integer Adder Tree Module
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
entity  CONV_INT_ADDER_TREE is
    generic (
        I_PARAM         : CONV_WINDOW_PARAM_TYPE := NEW_CONV_WINDOW_PARAM(8,0,1,1,1);
        O_PARAM         : CONV_WINDOW_PARAM_TYPE := NEW_CONV_WINDOW_PARAM(8,0,1,1,1);
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
end CONV_INT_ADDER_TREE;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library CONVOLUTION;
use     CONVOLUTION.CONV_TYPES.all;
use     CONVOLUTION.COMPONENTS.CONV_INT_ADDER_TREE;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.PIPELINE_REGISTER;
architecture RTL of CONV_INT_ADDER_TREE is
    subtype   I_ELEM_TYPE     is std_logic_vector(I_PARAM.ELEM_BITS-1 downto 0);
    type      I_ELEM_VECTOR   is array(0 to I_PARAM.SHAPE.Y.SIZE-1,
                                       0 to I_PARAM.SHAPE.X.SIZE-1,
                                       0 to I_PARAM.SHAPE.C.SIZE-1) of I_ELEM_TYPE;
    signal    i_elem          :  I_ELEM_VECTOR;
    signal    i_c_valid       :  std_logic_vector(I_PARAM.SHAPE.C.SIZE-1 downto 0);
    signal    i_c_start       :  std_logic;
    signal    i_c_last        :  std_logic;
    signal    i_d_valid       :  std_logic_vector(I_PARAM.SHAPE.D.SIZE-1 downto 0);
    signal    i_d_start       :  std_logic;
    signal    i_d_last        :  std_logic;
    signal    i_x_valid       :  std_logic_vector(I_PARAM.SHAPE.X.SIZE-1 downto 0);
    signal    i_x_start       :  std_logic;
    signal    i_x_last        :  std_logic;
    signal    i_y_valid       :  std_logic_vector(I_PARAM.SHAPE.Y.SIZE-1 downto 0);
    signal    i_y_start       :  std_logic;
    signal    i_y_last        :  std_logic;
begin
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    process (I_DATA) begin
        for y in 0 to I_PARAM.Y.SIZE-1 loop
        for x in 0 to I_PARAM.X.SIZE-1 loop
        for c in 0 to I_PARAM.C.SIZE-1 loop
            i_elem(y,x,c) <= GET_ELEMENT_FROM_CONV_WINDOW_DATA(I_PARAM, c, x, y, I_DATA);
        end loop;
        end loop;
        end loop;
        i_c_valid <= I_DATA(I_PARAM.DATA.ATRB_C_FIELD.VALID.HI downto I_PARAM.DATA.ATRB_C_FIELD.VALID.LO);
        i_c_start <= I_DATA(I_PARAM.DATA.ATRB_C_FIELD.STARRT_POS);
        i_c_last  <= I_DATA(I_PARAM.DATA.ATRB_C_FIELD.LAST_POS);
        i_d_valid <= I_DATA(I_PARAM.DATA.ATRB_D_FIELD.VALID.HI downto I_PARAM.DATA.ATRB_D_FIELD.VALID.LO);
        i_d_start <= I_DATA(I_PARAM.DATA.ATRB_D_FIELD.STARRT_POS);
        i_d_last  <= I_DATA(I_PARAM.DATA.ATRB_D_FIELD.LAST_POS);
        i_x_valid <= I_DATA(I_PARAM.DATA.ATRB_X_FIELD.VALID.HI downto I_PARAM.DATA.ATRB_X_FIELD.VALID.LO);
        i_x_start <= I_DATA(I_PARAM.DATA.ATRB_X_FIELD.STARRT_POS);
        i_x_last  <= I_DATA(I_PARAM.DATA.ATRB_X_FIELD.LAST_POS);
        i_y_valid <= I_DATA(I_PARAM.DATA.ATRB_Y_FIELD.VALID.HI downto I_PARAM.DATA.ATRB_Y_FIELD.VALID.LO);
        i_y_start <= I_DATA(I_PARAM.DATA.ATRB_Y_FIELD.STARRT_POS);
        i_y_last  <= I_DATA(I_PARAM.DATA.ATRB_Y_FIELD.LAST_POS);
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    C_SIZE_EQ_1: if (I_PARAM.SHAPE.C.SIZE = 1) generate
    begin 
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (i_elem, i_c_valid, i_c_start, i_c_last,
                         i_d_valid, i_d_start, i_d_last,
                         i_x_valid, i_x_start, i_x_last,
                         i_y_valid, i_y_start, i_y_last, I_DATA)
            variable data :  std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
            variable elem :  std_logic_vector(O_PARAM.ELEM_BITS-1 downto 0);
        begin
            for y in 0 to O_PARAM.SHAPE.Y.SIZE-1 loop
            for x in 0 to O_PARAM.SHAPE.X.SIZE-1 loop
            for c in 0 to O_PARAM.SHAPE.C.SIZE-1 loop
                if (SIGN) then
                    elem := std_logic_vector(resize(to_01(  signed(i_elem(c,x,y))), O_PARAM.ELEM_BITS));
                else
                    elem := std_logic_vector(resize(to_01(unsigned(i_elem(c,x,y))), O_PARAM.ELEM_BITS));
                end if;
                SET_ELEMENT_TO_CONV_WINDOW_DATA(O_PARAM, c, x, y, elem, data);
            end loop;        
            end loop;        
            end loop;
            data(O_PARAM.DATA.ATRB_C_FIELD.VALID.HI downto O_PARAM.DATA.ATRB_C_FIELD.VALID.LO) := i_c_valid;
            data(O_PARAM.DATA.ATRB_C_FIELD.START_POS)                                          := i_c_start;
            data(O_PARAM.DATA.ATRB_C_FIELD.LAST_POS )                                          := i_c_last;
            data(O_PARAM.DATA.ATRB_D_FIELD.VALID.HI downto O_PARAM.DATA.ATRB_D_FIELD.VALID.LO) := i_d_valid;
            data(O_PARAM.DATA.ATRB_D_FIELD.START_POS)                                          := i_d_start;
            data(O_PARAM.DATA.ATRB_D_FIELD.LAST_POS )                                          := i_d_last;
            data(O_PARAM.DATA.ATRB_X_FIELD.VALID.HI downto O_PARAM.DATA.ATRB_X_FIELD.VALID.LO) := i_x_valid;
            data(O_PARAM.DATA.ATRB_X_FIELD.START_POS)                                          := i_x_start;
            data(O_PARAM.DATA.ATRB_X_FIELD.LAST_POS )                                          := i_x_last;
            data(O_PARAM.DATA.ATRB_Y_FIELD.VALID.HI downto O_PARAM.DATA.ATRB_Y_FIELD.VALID.LO) := i_y_valid;
            data(O_PARAM.DATA.ATRB_Y_FIELD.START_POS)                                          := i_y_start;
            data(O_PARAM.DATA.ATRB_Y_FIELD.LAST_POS )                                          := i_y_last;
            if (O_PARAM.INFO_BITS > 0) then
                data(O_PARAM.DATA.INFO_FIELD.HI downto O_PARAM.DATA.INFO_FIELD.LO) := I_DATA(I_PARAM.DATA.INFO_FIELD.HI downto I_PARAM.DATA.INFO_FIELD.LO);
            end if;
            O_DATA <= data;
        end process;
        O_VALID <= I_VALID;
        I_READY <= O_READY;
    end generate;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    C_SIZE_GT_1: if (I_PARAM.SHAPE.C.SIZE > 1) generate
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        constant  T_ELEM_BITS     :  integer := I_PARAM.ELEM_BITS+1;
        constant  T_SHAPE_C_SIZE  :  integer := (I_PARAM.SHAPE.C.SIZE + 1) / 2;
        constant  T_PARAM         :  CONV_WINDOW_PARAM_TYPE
                                  := NEW_CONV_WINDOW_PARAM(
                                         ELEM_BITS => T_ELEM_BITS         ,
                                         INFO_BITS => I_PARAM.INFO_BITS   ,
                                         C         => T_SHAPE_C_SIZE      ,
                                         D         => I_PARAM.SHAPE.D.SIZE,
                                         X         => I_PARAM.SHAPE.X.SIZE,
                                         Y         => I_PARAM.SHAPE.Y.SIZE
                                     );
        subtype   T_ELEM_TYPE     is std_logic_vector(T_PARAM.ELEM_BITS-1 downto 0);
        type      T_ELEM_VECTOR   is array(0 to T_PARAM.SHAPE.Y.SIZE-1,
                                           0 to T_PARAM.SHAPE.X.SIZE-1,
                                           0 to T_PARAM.SHAPE.C.SIZE-1) of T_ELEM_TYPE;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        signal    t_elem          :  T_ELEM_VECTOR;
        signal    t_c_valid       :  std_logic_vector(T_PARAM.SHAPE.C.SIZE-1 downto 0);
        signal    t_data          :  std_logic_vector(T_PARAM.DATA.SIZE-1    downto 0);
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        signal    q_data          :  std_logic_vector(T_PARAM.DATA.SIZE-1    downto 0);
        signal    q_valid         :  std_logic;
        signal    q_ready         :  std_logic;
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process(i_elem, i_c_valid)
            variable a_valid :  std_logic;
            variable a_elem  :  std_logic_vector(T_PARAM.ELEM_BITS-1 downto 0);
            variable b_valid :  std_logic;
            variable b_elem  :  std_logic_vector(T_PARAM.ELEM_BITS-1 downto 0);
        begin
            for y in 0 to T_PARAM.SHAPE.Y.SIZE-1 loop
            for x in 0 to T_PARAM.SHAPE.X.SIZE-1 loop
            for c in 0 to T_PARAM.SHAPE.C.SIZE-1 loop
                if (c*2+0 < I_PARAM.SHAPE.C.SIZE) then
                    a_elem  := i_elem(c*2+0);
                else
                    a_elem  := (others => '0');
                end if;
                if (c*2+1 < I_PARAM.SHAPE.C.SIZE) then
                    b_elem  := i_elem(c*2+1);
                else
                    b_elem  := (others => '0');
                end if;
                if (SIGN) then
                    t_elem(y,x,c) <= std_logic_vector(resize(to_01(  signed(a_elem)), T_ELEM_BITS) +
                                                      resize(to_01(  signed(b_elem)), T_ELEM_BITS));
                else
                    t_elem(y,x,c) <= std_logic_vector(resize(to_01(unsigned(a_elem)), T_ELEM_BITS) +
                                                      resize(to_01(unsigned(b_elem)), T_ELEM_BITS));
                end if;
            end loop;        
            end loop;        
            end loop;        
            for c in 0 to T_PARAM.SHAPE.C.SIZE-1 loop
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
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        process (t_elem, t_c_valid, i_c_start, i_c_last,
                         i_d_valid, i_d_start, i_d_last,
                         i_x_valid, i_x_start, i_x_last,
                         i_y_valid, i_y_start, i_y_last, I_DATA)
            variable data :  std_logic_vector(T_PARAM.DATA.SIZE-1 downto 0);
        begin
            for y in 0 to T_PARAM.SHAPE.Y.SIZE-1 loop
            for x in 0 to T_PARAM.SHAPE.X.SIZE-1 loop
            for c in 0 to T_PARAM.SHAPE.C.SIZE-1 loop
                SET_ELEMENT_TO_CONV_WINDOW_DATA(T_PARAM, c, x, y, t_elem(c,x,y), data);
            end loop;        
            end loop;        
            end loop;
            data(T_PARAM.DATA.ATRB_C_FIELD.VALID.HI downto T_PARAM.DATA.ATRB_C_FIELD.VALID.LO) := t_c_valid;
            data(T_PARAM.DATA.ATRB_C_FIELD.START_POS)                                          := i_c_start;
            data(T_PARAM.DATA.ATRB_C_FIELD.LAST_POS )                                          := i_c_last;
            data(T_PARAM.DATA.ATRB_D_FIELD.VALID.HI downto T_PARAM.DATA.ATRB_D_FIELD.VALID.LO) := i_d_valid;
            data(T_PARAM.DATA.ATRB_D_FIELD.START_POS)                                          := i_d_start;
            data(T_PARAM.DATA.ATRB_D_FIELD.LAST_POS )                                          := i_d_last;
            data(T_PARAM.DATA.ATRB_X_FIELD.VALID.HI downto T_PARAM.DATA.ATRB_X_FIELD.VALID.LO) := i_x_valid;
            data(T_PARAM.DATA.ATRB_X_FIELD.START_POS)                                          := i_x_start;
            data(T_PARAM.DATA.ATRB_X_FIELD.LAST_POS )                                          := i_x_last;
            data(T_PARAM.DATA.ATRB_Y_FIELD.VALID.HI downto T_PARAM.DATA.ATRB_Y_FIELD.VALID.LO) := i_y_valid;
            data(T_PARAM.DATA.ATRB_Y_FIELD.START_POS)                                          := i_y_start;
            data(T_PARAM.DATA.ATRB_Y_FIELD.LAST_POS )                                          := i_y_last;
            if (T_PARAM.INFO_BITS > 0) then
                data(T_PARAM.DATA.INFO_FIELD.HI downto T_PARAM.DATA.INFO_FIELD.LO) := I_DATA(I_PARAM.DATA.INFO_FIELD.HI downto I_PARAM.DATA.INFO_FIELD.LO);
            end if;
            t_data <= data;
        end process;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        QUEUE: PIPELINE_REGISTER                   -- 
            generic map (                          -- 
                QUEUE_SIZE  => QUEUE_SIZE        , --
                WORD_BITS   => T_PARAM.DATA.SIZE   -- 
            )                                      -- 
            port map (                             -- 
                CLK         => CLK               , -- In  :
                RST         => RST               , -- In  :
                CLR         => CLR               , -- In  :
                I_WORD      => t_data            , -- In  :
                I_VAL       => I_VALID           , -- In  :
                I_RDY       => I_READY           , -- Out :
                Q_WORD      => q_data            , -- Out :
                Q_VAL       => q_valid           , -- Out :
                Q_RDY       => q_ready           , -- In  :
                BUSY        => open                -- Out :
            );                                     -- 
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        NEXT_ADDER: CONV_INT_ADDER_TREE            -- 
            generic map (                          -- 
                I_PARAM     => T_PARAM           , -- 
                O_PARAM     => O_PARAM           , -- 
                QUEUE_SIZE  => QUEUE_SIZE        , -- 
                SIGN        => SIGN                -- 
            )                                      -- 
            port map (                             -- 
                CLK         => CLK               , -- In  :
                RST         => RST               , -- In  :
                CLR         => CLR               , -- In  :
                I_DATA      => q_data            , -- In  :
                I_VALID     => q_valid           , -- In  :
                I_READY     => q_ready           , -- Out :
                O_DATA      => O_DATA            , -- Out :
                O_VALID     => O_VALID           , -- Out :
                O_READY     => O_READY             -- In  :
            );
    end generate;
end RTL;
