-------------------------------------------------------------------------------
-- Title      : Moving average filter
-- Project    : General Cores library
-------------------------------------------------------------------------------
-- File       : gc_moving_average.vhd
-- Author     : Tomasz Wlostowski
-- Company    : CERN
-- Created    : 2009-09-01
-- Last update: 2016-01-27
-- Platform   : FPGA-generic
-- Standard   : VHDL '93
-------------------------------------------------------------------------------
-- Description:
-- Simple averaging filter.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2009-2011 CERN
--
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any   
-- later version.                                               
--
-- This source is distributed in the hope that it will be       
-- useful, but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not, download it   
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2009-09-01  0.9      twlostow        Created
-- 2011-04-18  1.0      twlostow        Added comments & header
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.NUMERIC_STD.all;

library work;
use work.gencores_pkg.all;
use work.genram_pkg.all;


entity gc_moving_average is
  
  generic (
    -- input/output data width
    g_data_width : natural := 24;
    g_mem_size   : integer := 1024
    );
  port (
    rst_n_i : in std_logic;
    clk_i   : in std_logic;

    window_i : in std_logic_vector(f_log2_size(g_mem_size) -1 downto 0);

    d_i       : in  std_logic_vector(g_data_width-1 downto 0);
    d_valid_i : in  std_logic;
    q_o       : out std_logic_vector(g_data_width-1 downto 0);
    q_valid_o : out std_logic
    );

end gc_moving_average;

architecture rtl of gc_moving_average is

  constant c_counter_width : integer := f_log2_size(g_mem_size);
  
  signal read_cntr, write_cntr          : unsigned(c_counter_width-1 downto 0);
  signal mem_dout                       : std_logic_vector(g_data_width-1 downto 0);
  signal ready                          : std_logic;
  signal acc                            : signed(g_data_width+c_counter_width downto 0);
  signal stb_d0, stb_d1, stb_d2, stb_d3 : std_logic;
  signal s_dummy                        : std_logic_vector(g_data_width-1 downto 0);
begin  -- rtl


  

    U_delay: generic_dpram
      generic map (
        g_data_width               => g_data_width,
        g_size                     => g_mem_size,
        g_dual_clock               => false)
      port map (
        rst_n_i => rst_n_i,
        clka_i  => clk_i,
        wea_i   => d_valid_i,
        aa_i    => std_logic_vector(write_cntr),
        da_i    => d_i,
        clkb_i  => clk_i,
        ab_i    => std_logic_vector(read_cntr),
        qb_o    => mem_dout);


  avg : process (clk_i, rst_n_i)
  begin  -- process avg


    if clk_i'event and clk_i = '1' then  -- rising clock edge
      if(rst_n_i = '0') then
        read_cntr  <= to_unsigned(1, read_cntr'length);
        write_cntr <= to_unsigned(avg_steps, write_cntr'length);
        ready      <= '0';
        stb_d0     <= '0';
        stb_d1     <= '0';
        stb_d2     <= '0';
        stb_d3     <= '0';
        acc        <= (others => '0');
      else
        

        if(read_cntr = to_unsigned(avg_steps, read_cntr'length)) then
          ready <= '1';
        end if;


        if(din_stb_i = '1') then
          acc        <= acc + signed(din_i);
          write_cntr <= write_cntr + 1;

          if stb_d3 = '1' then
            read_cntr <= read_cntr + 1;
            if(ready = '1') then
              acc    <= acc - signed(mem_dout);
              dout_o <= std_logic_vector(acc (g_avg_log2 + g_data_width - 1 downto g_avg_log2));
            end if;
          end if;
          
        end if;

        dout_stb_o <= stb_d3 and ready;
        stb_d0     <= din_stb_i;
        stb_d1     <= stb_d0;
        stb_d2     <= stb_d1;
        stb_d3     <= stb_d2;
        
      end if;
    end if;
  end process avg;
  

  
  
end rtl;

