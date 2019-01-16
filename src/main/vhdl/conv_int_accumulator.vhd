-----------------------------------------------------------------------------------
--!     @file    conv_int_accumulator.vhd
--!     @brief   Convolution Integer Accumulator Module
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
--! @brief Convolution Integer Accumulator Tree
-----------------------------------------------------------------------------------
entity  CONV_INT_ACCUMULATOR is
    generic (
        I_PARAM         : CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,2,1,1,1);
        O_PARAM         : CONV_PIPELINE_PARAM_TYPE := NEW_CONV_PIPELINE_PARAM(8,0,1,1,1,1);
        B_PARAM         : CONV_D_VECTOR_PARAM_TYPE := NEW_CONV_D_VECTOR_PARAM(8,0,1);
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
        B_DATA          : --! @brief INPUT CONVOLUTION BIAS DATA :
                          --! ウィンドウデータ入力.
                          in  std_logic_vector(I_PARAM.DATA.SIZE-1 downto 0);
        B_VALID         : --! @brief INPUT CONVOLUTION BIAS DATA VALID :
                          --! 入力ウィンドウデータ有効信号.
                          --! * B_DATAが有効であることを示す.
                          --! * B_VALID='1'and B_READY='1'でウィンドウデータがキュー
                          --!   に取り込まれる.
                          in  std_logic;
        B_READY         : --! @brief INPUT CONVOLUTION BIAS DATA READY :
                          --! 入力ウィンドウデータレディ信号.
                          --! * キューが次のウィンドウデータを入力出来ることを示す.
                          --! * B_VALID='1'and B_READY='1'でウィンドウデータがキュー
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
end CONV_INT_ACCUMULATOR;
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
architecture RTL of CONV_INT_ACCUMULATOR is
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   I_ELEM_TYPE     is std_logic_vector(I_PARAM.ELEM_BITS-1 downto 0);
    type      I_ELEM_VECTOR   is array(0 to I_PARAM.SHAPE.Y.SIZE-1,
                                       0 to I_PARAM.SHAPE.X.SIZE-1,
                                       0 to I_PARAM.SHAPE.D.SIZE-1,
                                       0 to I_PARAM.SHAPE.C.SIZE-1) of I_ELEM_TYPE;
    signal    i_elem          :  I_ELEM_VECTOR;
    signal    i_c_start       :  std_logic;
    signal    i_c_last        :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   B_ELEM_TYPE     is std_logic_vector(B_PARAM.ELEM_BITS-1 downto 0);
    type      B_ELEM_VECTOR   is array(0 to B_PARAM.SHAPE.D.SIZE-1) of B_ELEM_TYPE;
    signal    b_elem          :  B_ELEM_VECTOR;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    subtype   O_ELEM_TYPE     is std_logic_vector(O_PARAM.ELEM_BITS-1 downto 0);
    type      O_ELEM_VECTOR   is array(0 to O_PARAM.SHAPE.Y.SIZE-1,
                                       0 to O_PARAM.SHAPE.X.SIZE-1,
                                       0 to O_PARAM.SHAPE.D.SIZE-1,
                                       0 to O_PARAM.SHAPE.C.SIZE-1) of O_ELEM_TYPE;
    function  O_ELEM_NULL     return O_ELEM_VECTOR is
        variable elem         :  O_ELEM_VECTOR;
    begin
        for y in 0 to O_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to O_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to O_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to O_PARAM.SHAPE.C.SIZE-1 loop
            elem(y,x,d,c) := (others => '0');
        end loop;
        end loop;
        end loop;
        end loop;
        return elem;
    end function;
    signal    q_elem          :  O_ELEM_VECTOR;
    signal    d_elem          :  O_ELEM_VECTOR;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    d_valid         :  std_logic;
    signal    d_ready         :  std_logic;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    q_data          :  std_logic_vector(O_PARAM.DATA.SIZE-1 downto 0);
    signal    q_valid         :  std_logic;
    signal    q_ready         :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- i_elem    :
    -- i_c_start :
    -- i_c_last  :
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
        i_c_start <= I_DATA(I_PARAM.DATA.ATRB_C_FIELD.START_POS);
        i_c_last  <= I_DATA(I_PARAM.DATA.ATRB_C_FIELD.LAST_POS);
    end process;
    -------------------------------------------------------------------------------
    -- b_elem    :
    -------------------------------------------------------------------------------
    process (B_DATA) begin
        for d in 0 to B_PARAM.SHAPE.D.SIZE-1 loop
            b_elem(d) <= GET_ELEMENT_FROM_DATA(B_PARAM, d, I_DATA);
        end loop;
    end process;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    d_valid  <= '1' when (i_c_start = '1' and I_VALID = '1' and B_VALID = '1') or
                         (i_c_start = '0' and I_VALID = '1'                  ) else '0';
    d_ready  <= '1' when (i_c_last  = '1' and q_ready = '1') or
                         (i_c_last  = '0'                  ) else '0';
    q_valid  <= '1' when (i_c_last  = '1' and d_valid = '1') else '0';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    I_READY    <= '1' when (d_valid = '1' and d_ready = '1') else '0';
    B_READY    <= '1' when (d_valid = '1' and d_ready = '1' and i_c_start = '1') else '0';
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (i_elem, b_elem, q_elem, i_c_start)
        variable t_elem :  std_logic_vector(O_PARAM.ELEM_BITS-1 downto 0);
    begin
        for y in 0 to O_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to O_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to O_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to O_PARAM.SHAPE.C.SIZE-1 loop
            if (SIGN) then
                if (i_c_start = '1') then
                    t_elem := std_logic_vector(resize(to_01(  signed(b_elem(d      ))), O_PARAM.ELEM_BITS));
                else
                    t_elem := std_logic_vector(resize(to_01(  signed(q_elem(y,x,d,c))), O_PARAM.ELEM_BITS));
                end if;
                d_elem(y,x,d,c) <= std_logic_vector(resize(to_01(  signed(i_elem(y,x,d,c))), O_PARAM.ELEM_BITS) +   signed(t_elem));
            else
                if (i_c_start = '1') then
                    t_elem := std_logic_vector(resize(to_01(unsigned(b_elem(d      ))), O_PARAM.ELEM_BITS));
                else
                    t_elem := std_logic_vector(resize(to_01(unsigned(q_elem(y,x,d,c))), O_PARAM.ELEM_BITS));
                end if;
                d_elem(y,x,d,c) <= std_logic_vector(resize(to_01(unsigned(i_elem(y,x,d,c))), O_PARAM.ELEM_BITS) + unsigned(t_elem));
            end if;
        end loop;
        end loop;
        end loop;
        end loop;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                q_elem <= O_ELEM_NULL;
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                q_elem <= O_ELEM_NULL;
            elsif (d_valid = '1' and d_ready = '1') then
                q_elem <= d_elem;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process(d_elem, I_DATA)
        variable data     :  std_logic_vector(O_PARAM.DATA.SIZE   -1 downto 0);
        constant c_valid  :  std_logic_vector(O_PARAM.SHAPE.C.SIZE-1 downto 0) := (others => '1');
        constant c_start  :  std_logic := '1';
        constant c_last   :  std_logic := '1';
    begin
        for y in 0 to O_PARAM.SHAPE.Y.SIZE-1 loop
        for x in 0 to O_PARAM.SHAPE.X.SIZE-1 loop
        for d in 0 to O_PARAM.SHAPE.D.SIZE-1 loop
        for c in 0 to O_PARAM.SHAPE.C.SIZE-1 loop
            SET_ELEMENT_TO_DATA(O_PARAM, c, d, x, y, d_elem(y,x,d,c), data);
        end loop;        
        end loop;        
        end loop;        
        end loop;
        data(O_PARAM.DATA.ATRB_C_FIELD.VALID.HI downto O_PARAM.DATA.ATRB_C_FIELD.VALID.LO) := c_valid;
        data(O_PARAM.DATA.ATRB_C_FIELD.START_POS)                                          := c_start;
        data(O_PARAM.DATA.ATRB_C_FIELD.LAST_POS )                                          := c_last;
        data(O_PARAM.DATA.ATRB_D_FIELD.HI downto O_PARAM.DATA.ATRB_D_FIELD.LO) := I_DATA(I_PARAM.DATA.ATRB_D_FIELD.HI downto I_PARAM.DATA.ATRB_D_FIELD.LO);
        data(O_PARAM.DATA.ATRB_X_FIELD.HI downto O_PARAM.DATA.ATRB_X_FIELD.LO) := I_DATA(I_PARAM.DATA.ATRB_X_FIELD.HI downto I_PARAM.DATA.ATRB_X_FIELD.LO);
        data(O_PARAM.DATA.ATRB_Y_FIELD.HI downto O_PARAM.DATA.ATRB_Y_FIELD.LO) := I_DATA(I_PARAM.DATA.ATRB_Y_FIELD.HI downto I_PARAM.DATA.ATRB_Y_FIELD.LO);
        if (O_PARAM.INFO_BITS > 0) then
            data(O_PARAM.DATA.INFO_FIELD.HI downto O_PARAM.DATA.INFO_FIELD.LO) := I_DATA(I_PARAM.DATA.INFO_FIELD.HI   downto I_PARAM.DATA.INFO_FIELD.LO  );
        end if;
        q_data <= data;
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
            I_WORD      => q_data            , -- In  :
            I_VAL       => q_valid           , -- In  :
            I_RDY       => q_ready           , -- Out :
            Q_WORD      => O_DATA            , -- Out :
            Q_VAL       => O_VALID           , -- Out :
            Q_RDY       => O_READY           , -- In  :
            BUSY        => open                -- Out :
        );                                     -- 
end RTL;
