-----------------------------------------------------------------------------------
--!     @file    conv_parameter_buffer.vhd
--!     @brief   Convolution Parameter Buffer Module
--!     @version 0.2.0
--!     @date    2019/3/21
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
-----------------------------------------------------------------------------------
--! @brief Convolution Parameter Buffer Module
-----------------------------------------------------------------------------------
entity  CONV_PARAMETER_BUFFER is
    generic (
        PARAM           : --! @brief OUTPUT STREAM PARAMETER :
                          --! 出力側のストリームのパラメータを指定する.
                          IMAGE_STREAM_PARAM_TYPE := NEW_IMAGE_STREAM_PARAM(8,1,1,1);
        SHAPE           : --! @brief PARAMETER SHAPE :
                          --! ウェイトデータの形(SHAPE)を指定する.
                          IMAGE_SHAPE_TYPE := NEW_IMAGE_SHAPE_CONSTANT(8,1,1,1,1);
        ELEMENT_SIZE    : --! @brief PARAMETER ELEMENT SIZE :
                          integer := 1024;
        ID              : --! @brief SDPRAM IDENTIFIER :
                          --! どのモジュールで使われているかを示す識別番号.
                          integer := 0 
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
    -- 制御 I/F
    -------------------------------------------------------------------------------
        REQ_VALID       : --! @brief REQUEST VALID :
                          in  std_logic;
        REQ_READY       : --! @brief REQUEST READY :
                          out std_logic;
        C_SIZE          : --! @brief SHAPE C SIZE :
                          in  integer range 0 to SHAPE.C.MAX_SIZE := SHAPE.C.SIZE;
        D_SIZE          : --! @brief SHAPE D SIZE :
                          in  integer range 0 to SHAPE.D.MAX_SIZE := SHAPE.D.SIZE;
        X_SIZE          : --! @brief SHAPE X SIZE :
                          in  integer range 0 to SHAPE.X.MAX_SIZE := SHAPE.X.SIZE;
        Y_SIZE          : --! @brief SHAPE Y SIZE :
                          in  integer range 0 to SHAPE.Y.MAX_SIZE := SHAPE.Y.SIZE;
        RES_VALID       : --! @brief RESPONSE VALID : 
                          out std_logic;
        RES_READY       : --! @brief RESPONSE READY : 
                          in  std_logic := '1';
        BUSY            : --! @brief BUSY
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 入力 I/F
    -------------------------------------------------------------------------------
        I_DATA          : --! @brief INPUT PARAMETER DATA :
                          in  std_logic_vector(PARAM.ELEM_BITS-1 downto 0);
        I_VALID         : --! @brief INPUT PARAMETER DATA VALID :
                          in  std_logic;
        I_READY         : --! @brief INPUT PARAMETER DATA READY :
                          out std_logic;
    -------------------------------------------------------------------------------
    -- 出力側 I/F
    -------------------------------------------------------------------------------
        O_DATA          : --! @brief OUTPUT PARAMETER DATA :
                          --! ストリームデータ出力.
                          out std_logic_vector(PARAM.DATA.SIZE-1 downto 0);
        O_VALID         : --! @brief OUTPUT PARAMETER DATA VALID :
                          --! 出力ストリームデータ有効信号.
                          --! * O_DATAが有効であることを示す.
                          out std_logic;
        O_READY         : --! @brief OUTPUT PARAMETER DATA READY :
                          --! 出力ストリームデータレディ信号.
                          in  std_logic
    );
end CONV_PARAMETER_BUFFER;
-----------------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
library PIPEWORK;
use     PIPEWORK.COMPONENTS.SDPRAM;
use     PIPEWORK.COMPONENTS.QUEUE_REGISTER;
use     PIPEWORK.IMAGE_TYPES.all;
library CONVOLUTION;
use     CONVOLUTION.CONV_COMPONENTS.CONV_PARAMETER_BUFFER_WRITER;
use     CONVOLUTION.CONV_COMPONENTS.CONV_PARAMETER_BUFFER_READER;
architecture RTL of CONV_PARAMETER_BUFFER is
    -------------------------------------------------------------------------------
    -- BANK_SIZE : バンクの数
    -------------------------------------------------------------------------------
    constant  BANK_SIZE             :  integer := PARAM.SHAPE.D.SIZE *
                                                  PARAM.SHAPE.Y.SIZE *
                                                  PARAM.SHAPE.X.SIZE *
                                                  PARAM.SHAPE.C.SIZE ;
    -------------------------------------------------------------------------------
    -- BUF_WIDTH : メモリのビット幅を２のべき乗値で示す
    -------------------------------------------------------------------------------
    function  CALC_BUF_WIDTH(BITS: integer) return integer is
        variable width              :  integer;
    begin
        width := 0;
        while (2**width < BITS) loop
            width := width + 1;
        end loop;
        return width;
    end function;
    constant  BUF_WIDTH             :  integer := CALC_BUF_WIDTH(PARAM.ELEM_BITS);
    -------------------------------------------------------------------------------
    -- BUF_DEPTH: メモリバンク１つあたりの深さ(ビット単位)を２のべき乗値で示す
    -------------------------------------------------------------------------------
    function  CALC_BUF_DEPTH    return integer is
        variable size               :  integer;
        variable depth              :  integer;
    begin
        size  := ELEMENT_SIZE*(2**BUF_WIDTH);
        size  := (size + BANK_SIZE - 1)/BANK_SIZE;
        depth := 0;
        while (2**depth < size) loop
            depth := depth + 1;
        end loop;
        return depth;
    end function;
    constant  BUF_DEPTH             :  integer := CALC_BUF_DEPTH;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  BUF_DATA_BITS         :  integer := 2**BUF_WIDTH;
    constant  BUF_ADDR_BITS         :  integer := BUF_DEPTH - BUF_WIDTH;
    constant  BUF_WENA_BITS         :  integer := 1;
    constant  BUF_SIZE_BITS         :  integer := BUF_ADDR_BITS + 1;
    signal    buf_wdata             :  std_logic_vector(BANK_SIZE*BUF_DATA_BITS-1 downto 0);
    signal    buf_waddr             :  std_logic_vector(BANK_SIZE*BUF_ADDR_BITS-1 downto 0);
    signal    buf_we                :  std_logic_vector(BANK_SIZE*BUF_WENA_BITS-1 downto 0);
    signal    buf_rdata             :  std_logic_vector(BANK_SIZE*BUF_DATA_BITS-1 downto 0);
    signal    buf_raddr             :  std_logic_vector(BANK_SIZE*BUF_ADDR_BITS-1 downto 0);
    signal    buf_push              :  std_logic;
    constant  buf_wready            :  std_logic := '1';
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    constant  QUEUE_SIZE            :  integer := 1;
    constant  QUEUE_DATA_ADDR_LO    :  integer := 0;
    constant  QUEUE_DATA_ADDR_HI    :  integer := QUEUE_DATA_ADDR_LO + BUF_ADDR_BITS - 1;
    constant  QUEUE_DATA_SIZE_LO    :  integer := QUEUE_DATA_ADDR_HI + 1;
    constant  QUEUE_DATA_SIZE_HI    :  integer := QUEUE_DATA_SIZE_LO + BUF_SIZE_BITS - 1;
    constant  QUEUE_DATA_BITS       :  integer := QUEUE_DATA_SIZE_HI + 1;
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    wr_req_valid          :  std_logic;
    signal    wr_req_ready          :  std_logic;
    signal    wr_res_valid          :  std_logic;
    signal    wr_res_ready          :  std_logic;
    signal    wr_busy               :  std_logic;
    signal    wr_res_addr           :  std_logic_vector(BUF_ADDR_BITS  -1 downto 0);
    signal    wr_res_size           :  std_logic_vector(BUF_SIZE_BITS  -1 downto 0);
    signal    wr_res_data           :  std_logic_vector(QUEUE_DATA_BITS-1 downto 0);
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    signal    rd_req_data           :  std_logic_vector(QUEUE_DATA_BITS-1 downto 0);
    signal    rd_req_addr           :  std_logic_vector(BUF_ADDR_BITS  -1 downto 0);
    signal    rd_req_size           :  std_logic_vector(BUF_SIZE_BITS  -1 downto 0);
    signal    rd_req_valid          :  std_logic_vector(QUEUE_SIZE        downto 0);
    signal    rd_req_ready          :  std_logic;
    signal    rd_res_valid          :  std_logic;
    signal    rd_res_ready          :  std_logic;
    signal    rd_res_size           :  std_logic_vector(BUF_SIZE_BITS  -1 downto 0);
    signal    rd_busy               :  std_logic;
begin
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    wr_req_valid <= REQ_VALID;
    REQ_READY    <= wr_req_ready;
    RES_VALID    <= rd_res_valid;
    rd_res_ready <= RES_READY;
    BUSY         <= '1' when (wr_busy = '1' or rd_busy = '1') else '0';
    -------------------------------------------------------------------------------
    -- WRITER
    -------------------------------------------------------------------------------
    WR: CONV_PARAMETER_BUFFER_WRITER                 -- 
        generic map (                                -- 
            PARAM           => PARAM               , --
            SHAPE           => SHAPE               , --
            BANK_SIZE       => BANK_SIZE           , --
            BUF_ADDR_BITS   => BUF_ADDR_BITS       , --
            BUF_DATA_BITS   => BUF_DATA_BITS         --
        )                                            -- 
        port map (                                   -- 
        -------------------------------------------------------------------------------
        -- クロック&リセット信号
        -------------------------------------------------------------------------------
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
        -------------------------------------------------------------------------------
        -- 制御 I/F
        -------------------------------------------------------------------------------
            REQ_VALID       => wr_req_valid        , -- In  :
            REQ_READY       => wr_req_ready        , -- out :
            C_SIZE          => C_SIZE              , -- In  :
            D_SIZE          => D_SIZE              , -- In  :
            RES_VALID       => wr_res_valid        , -- Out :
            RES_READY       => wr_res_ready        , -- In  :
            RES_ADDR        => wr_res_addr         , -- Out :
            RES_SIZE        => wr_res_size         , -- Out :
            BUSY            => wr_busy             , -- Out :
        -------------------------------------------------------------------------------
        -- 入力 I/F
        -------------------------------------------------------------------------------
            I_DATA          => I_DATA              , -- In  :
            I_VALID         => I_VALID             , -- In  :
            I_READY         => I_READY             , -- Out :
        -------------------------------------------------------------------------------
        -- バッファメモリ I/F
        -------------------------------------------------------------------------------
            BUF_DATA        => buf_wdata           , -- Out :
            BUF_ADDR        => buf_waddr           , -- Out :
            BUF_WE          => buf_we              , -- Out :
            BUF_PUSH        => buf_push            , -- Out :
            BUF_READY       => buf_wready            -- In  :
        );                                           --  
    -------------------------------------------------------------------------------
    -- QUEUE
    -------------------------------------------------------------------------------
    QUEUE: QUEUE_REGISTER                            -- 
        generic map (                                -- 
            QUEUE_SIZE      => QUEUE_SIZE          , --
            DATA_BITS       => QUEUE_DATA_BITS       --
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- クロック&リセット信号
        ---------------------------------------------------------------------------
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
        ---------------------------------------------------------------------------
        -- 入力側
        ---------------------------------------------------------------------------
            I_DATA          => wr_res_data         , -- In  :
            I_VAL           => wr_res_valid        , -- In  :
            I_RDY           => wr_res_ready        , -- Out :
        ---------------------------------------------------------------------------
        -- 出力側
        ---------------------------------------------------------------------------
            Q_DATA          => rd_req_data         , -- Out :
            Q_VAL           => rd_req_valid        , -- Out :
            Q_RDY           => rd_req_ready          -- In  :
        );
    wr_res_data(QUEUE_DATA_ADDR_HI downto QUEUE_DATA_ADDR_LO) <= wr_res_addr;
    wr_res_data(QUEUE_DATA_SIZE_HI downto QUEUE_DATA_SIZE_LO) <= wr_res_size;
    rd_req_addr <= rd_req_data(QUEUE_DATA_ADDR_HI downto QUEUE_DATA_ADDR_LO);
    rd_req_size <= rd_req_data(QUEUE_DATA_SIZE_HI downto QUEUE_DATA_SIZE_LO);
    -------------------------------------------------------------------------------
    -- 
    -------------------------------------------------------------------------------
    process (CLK, RST) begin
        if (RST = '1') then
                rd_res_size <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (CLR = '1') then
                rd_res_size <= (others => '0');
            elsif (rd_req_valid(0) = '1' and rd_req_ready = '1') then
                rd_res_size <= rd_req_size;
            end if;
        end if;
    end process;
    -------------------------------------------------------------------------------
    -- READER
    -------------------------------------------------------------------------------
    RD: CONV_PARAMETER_BUFFER_READER                 -- 
        generic map (                                -- 
            PARAM           => PARAM               , -- 
            SHAPE           => SHAPE               , --
            BANK_SIZE       => BANK_SIZE           , -- 
            BUF_ADDR_BITS   => BUF_ADDR_BITS       , --
            BUF_DATA_BITS   => BUF_DATA_BITS         --
        )                                            -- 
        port map (                                   -- 
        ---------------------------------------------------------------------------
        -- クロック&リセット信号
        ---------------------------------------------------------------------------
            CLK             => CLK                 , -- In  :
            RST             => RST                 , -- In  :
            CLR             => CLR                 , -- In  :
        ---------------------------------------------------------------------------
        -- 制御 I/F
        ---------------------------------------------------------------------------
            REQ_VALID       => rd_req_valid(0)     , -- In  :
            REQ_READY       => rd_req_ready        , -- out :
            REQ_ADDR        => rd_req_addr         , -- In  :
            C_SIZE          => C_SIZE              , -- In  :
            D_SIZE          => D_SIZE              , -- In  :
            X_SIZE          => X_SIZE              , -- In  :
            Y_SIZE          => Y_SIZE              , -- In  :
            RES_VALID       => rd_res_valid        , -- Out :
            RES_READY       => rd_res_ready        , -- In  :
            BUSY            => rd_busy             , -- Out :
        ---------------------------------------------------------------------------
        -- 出力側 I/F
        ---------------------------------------------------------------------------
            O_DATA          => O_DATA              , -- Out :
            O_VALID         => O_VALID             , -- Out :
            O_READY         => O_READY             , -- In  :
        ---------------------------------------------------------------------------
        -- バッファメモリ I/F
        ---------------------------------------------------------------------------
            BUF_DATA        => buf_rdata           , -- In  :
            BUF_ADDR        => buf_raddr             -- Out :
        );                                           -- 
    -------------------------------------------------------------------------------
    --
    -------------------------------------------------------------------------------
    BUF: for bank in 0 to BANK_SIZE-1 generate
        constant  RAM_ID :  integer := ID + bank;
        signal    wdata  :  std_logic_vector(BUF_DATA_BITS-1 downto 0);
        signal    waddr  :  std_logic_vector(BUF_ADDR_BITS-1 downto 0);
        signal    we     :  std_logic_vector(BUF_WENA_BITS-1 downto 0);
        signal    rdata  :  std_logic_vector(BUF_DATA_BITS-1 downto 0);
        signal    raddr  :  std_logic_vector(BUF_ADDR_BITS-1 downto 0);
    begin
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        wdata <= buf_wdata((bank+1)*BUF_DATA_BITS-1 downto (bank)*BUF_DATA_BITS);
        waddr <= buf_waddr((bank+1)*BUF_ADDR_BITS-1 downto (bank)*BUF_ADDR_BITS);
        we    <= buf_we   ((bank+1)*BUF_WENA_BITS-1 downto (bank)*BUF_WENA_BITS);
        raddr <= buf_raddr((bank+1)*BUF_ADDR_BITS-1 downto (bank)*BUF_ADDR_BITS);
        buf_rdata((bank+1)*BUF_DATA_BITS-1 downto (bank)*BUF_DATA_BITS) <= rdata;
        ---------------------------------------------------------------------------
        --
        ---------------------------------------------------------------------------
        RAM: SDPRAM                   -- 
            generic map (             -- 
                DEPTH   => BUF_DEPTH, -- メモリの深さ(ビット単位)を2のべき乗値で指定する.
                RWIDTH  => BUF_WIDTH, -- リードデータ(RDATA)の幅(ビット数)を2のべき乗値で指定する.
                WWIDTH  => BUF_WIDTH, -- ライトデータ(WDATA)の幅(ビット数)を2のべき乗値で指定する.
                WEBIT   => 0        , -- ライトイネーブル信号(WE)の幅(ビット数)を2のべき乗値で指定する.
                ID      => RAM_ID     -- どのモジュールで使われているかを示す識別番号.
            )                         -- 
            port map (                -- 
                WCLK    => CLK      , -- In  :
                WE      => we       , -- In  : 
                WADDR   => waddr    , -- In  : 
                WDATA   => wdata    , -- In  : 
                RCLK    => CLK      , -- In  :
                RADDR   => raddr    , -- In  :
                RDATA   => rdata      -- Out :
            );                        -- 
    end generate;
end RTL;
