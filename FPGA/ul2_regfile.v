/* -*- coding: us-ascii-dos -*-
 *
 * Copyright Signal Processing Devices Sweden AB. All rights reserved.
 * See document "08-0175 EULA" for specific license terms regarding this file.
 *
 * Description   : User register file
 * Documentation :
 *
 */

module ul2_regfile
  #(
    parameter ADDR_WIDTH = 0
   )
   (
    input wire                  clk,
    input wire                  rst_i,
    input wire [ADDR_WIDTH-1:0] addr_i,
    input wire                  wr_i,
    output reg                  wr_ack_o,
    input wire [31:0]           wr_data_i,
    input wire                  rd_i,
    output reg                  rd_ack_o,
    output reg [31:0]           rd_data_o,

    input wire [31:0] reg_0x10_i,
    input wire [31:0] reg_0x11_i,
    input wire [31:0] reg_0x12_i,
    input wire [31:0] reg_0x13_i,
    input wire [31:0] reg_0x14_i,
    input wire [31:0] reg_0x15_i,
    input wire [31:0] reg_0x16_i,
    input wire [31:0] reg_0x17_i,
    input wire [31:0] reg_0x18_i,
    input wire [31:0] reg_0x19_i,
    input wire [31:0] reg_0x1a_i,
    input wire [31:0] reg_0x1b_i,
    input wire [31:0] reg_0x1c_i,
    input wire [31:0] reg_0x1d_i,
    input wire [31:0] reg_0x1e_i,
    input wire [31:0] reg_0x1f_i,
    input wire [31:0] reg_0x20_i,
    input wire [31:0] reg_0x21_i,
    input wire [31:0] reg_0x22_i,
    input wire [31:0] reg_0x23_i,
    input wire [31:0] reg_0x24_i,
    input wire [31:0] reg_0x25_i,
    input wire [31:0] reg_0x26_i,
    input wire [31:0] reg_0x27_i,
    input wire [31:0] reg_0x28_i,
    input wire [31:0] reg_0x29_i,
    input wire [31:0] reg_0x2a_i,
    input wire [31:0] reg_0x2b_i,
    input wire [31:0] reg_0x2c_i,
    input wire [31:0] reg_0x2d_i,
    input wire [31:0] reg_0x2e_i,
    input wire [31:0] reg_0x2f_i,
    input wire [31:0] reg_0x30_i,
    input wire [31:0] reg_0x31_i,
    input wire [31:0] reg_0x32_i,
    input wire [31:0] reg_0x33_i,
    input wire [31:0] reg_0x34_i,
    input wire [31:0] reg_0x35_i,
    input wire [31:0] reg_0x36_i,
    input wire [31:0] reg_0x37_i,
    input wire [31:0] reg_0x38_i,
    input wire [31:0] reg_0x39_i,
    input wire [31:0] reg_0x3a_i,
    input wire [31:0] reg_0x3b_i,
    input wire [31:0] reg_0x3c_i,
    input wire [31:0] reg_0x3d_i,
    input wire [31:0] reg_0x3e_i,
    input wire [31:0] reg_0x3f_i,
    input wire [31:0] reg_0x40_i,
    input wire [31:0] reg_0x41_i,
    input wire [31:0] reg_0x42_i,
    input wire [31:0] reg_0x43_i,
    input wire [31:0] reg_0x44_i,
    input wire [31:0] reg_0x45_i,
    input wire [31:0] reg_0x46_i,
    input wire [31:0] reg_0x47_i,
    input wire [31:0] reg_0x48_i,
    input wire [31:0] reg_0x49_i,
    input wire [31:0] reg_0x4a_i,
    input wire [31:0] reg_0x4b_i,
    input wire [31:0] reg_0x4c_i,
    input wire [31:0] reg_0x4d_i,
    input wire [31:0] reg_0x4e_i,
    input wire [31:0] reg_0x4f_i,
    input wire [31:0] reg_0x50_i,
    input wire [31:0] reg_0x51_i,
    input wire [31:0] reg_0x52_i,
    input wire [31:0] reg_0x53_i,
    input wire [31:0] reg_0x54_i,
    input wire [31:0] reg_0x55_i,
    input wire [31:0] reg_0x56_i,
    
    output wire [31:0] reg_0x10_o,
    output wire [31:0] reg_0x11_o,
    output wire [31:0] reg_0x12_o,
    output wire [31:0] reg_0x13_o,
    output wire [31:0] reg_0x14_o,
    output wire [31:0] reg_0x15_o,
    output wire [31:0] reg_0x16_o,
    output wire [31:0] reg_0x17_o,
    output wire [31:0] reg_0x18_o,
    output wire [31:0] reg_0x19_o,
    output wire [31:0] reg_0x1a_o,
    output wire [31:0] reg_0x1b_o,
    output wire [31:0] reg_0x1c_o,
    output wire [31:0] reg_0x1d_o,
    output wire [31:0] reg_0x1e_o,
    output wire [31:0] reg_0x1f_o,
    output wire [31:0] reg_0x20_o,
    output wire [31:0] reg_0x21_o,
    output wire [31:0] reg_0x22_o,
    output wire [31:0] reg_0x23_o,
    output wire [31:0] reg_0x24_o,
    output wire [31:0] reg_0x25_o,
    output wire [31:0] reg_0x26_o,
    output wire [31:0] reg_0x27_o,
    output wire [31:0] reg_0x28_o,
    output wire [31:0] reg_0x29_o,
    output wire [31:0] reg_0x2a_o,
    output wire [31:0] reg_0x2b_o,
    output wire [31:0] reg_0x2c_o,
    output wire [31:0] reg_0x2d_o,
    output wire [31:0] reg_0x2e_o,
    output wire [31:0] reg_0x2f_o,
    output wire [31:0] reg_0x30_o,
    output wire [31:0] reg_0x31_o,
    output wire [31:0] reg_0x32_o,
    output wire [31:0] reg_0x33_o,
    output wire [31:0] reg_0x34_o,
    output wire [31:0] reg_0x35_o,
    output wire [31:0] reg_0x36_o,
    output wire [31:0] reg_0x37_o,
    output wire [31:0] reg_0x38_o,
    output wire [31:0] reg_0x39_o,
    output wire [31:0] reg_0x3a_o,
    output wire [31:0] reg_0x3b_o,
    output wire [31:0] reg_0x3c_o,
    output wire [31:0] reg_0x3d_o,
    output wire [31:0] reg_0x3e_o,
    output wire [31:0] reg_0x3f_o,
    output wire [31:0] reg_0x40_o,
    output wire [31:0] reg_0x41_o,
    output wire [31:0] reg_0x42_o,
    output wire [31:0] reg_0x43_o,
    output wire [31:0] reg_0x44_o,
    output wire [31:0] reg_0x45_o,
    output wire [31:0] reg_0x46_o,
    output wire [31:0] reg_0x47_o,
    output wire [31:0] reg_0x48_o,
    output wire [31:0] reg_0x49_o,
    output wire [31:0] reg_0x4a_o,
    output wire [31:0] reg_0x4b_o,
    output wire [31:0] reg_0x4c_o,
    output wire [31:0] reg_0x4d_o,
    output wire [31:0] reg_0x4e_o,
    output wire [31:0] reg_0x4f_o,
    output wire [31:0] reg_0x50_o,
    output wire [31:0] reg_0x51_o,
    output wire [31:0] reg_0x52_o,
    output wire [31:0] reg_0x53_o,
    output wire [31:0] reg_0x54_o,
    output wire [31:0] reg_0x55_o,
    output wire [31:0] reg_0x56_o
    );

   reg [31:0]         regfile_out [0:70];
   wire [31:0]        regfile_in [0:70];

   assign reg_0x10_o = regfile_out[0];
   assign reg_0x11_o = regfile_out[1];
   assign reg_0x12_o = regfile_out[2];
   assign reg_0x13_o = regfile_out[3];
   assign reg_0x14_o = regfile_out[4];
   assign reg_0x15_o = regfile_out[5];
   assign reg_0x16_o = regfile_out[6];
   assign reg_0x17_o = regfile_out[7];
   assign reg_0x18_o = regfile_out[8];
   assign reg_0x19_o = regfile_out[9];
   assign reg_0x1a_o = regfile_out[10];
   assign reg_0x1b_o = regfile_out[11];
   assign reg_0x1c_o = regfile_out[12];
   assign reg_0x1d_o = regfile_out[13];
   assign reg_0x1e_o = regfile_out[14];
   assign reg_0x1f_o = regfile_out[15];
   assign reg_0x20_o = regfile_out[16];
   assign reg_0x21_o = regfile_out[17];
   assign reg_0x22_o = regfile_out[18];
   assign reg_0x23_o = regfile_out[19];
   assign reg_0x24_o = regfile_out[20];
   assign reg_0x25_o = regfile_out[21];
   assign reg_0x26_o = regfile_out[22];
   assign reg_0x27_o = regfile_out[23];
   assign reg_0x28_o = regfile_out[24];
   assign reg_0x29_o = regfile_out[25];
   assign reg_0x2a_o = regfile_out[26];
   assign reg_0x2b_o = regfile_out[27];
   assign reg_0x2c_o = regfile_out[28];
   assign reg_0x2d_o = regfile_out[29];
   assign reg_0x2e_o = regfile_out[30];
   assign reg_0x2f_o = regfile_out[31];
   assign reg_0x30_o = regfile_out[32];
   assign reg_0x31_o = regfile_out[33];
   assign reg_0x32_o = regfile_out[34];
   assign reg_0x33_o = regfile_out[35];
   assign reg_0x34_o = regfile_out[36];
   assign reg_0x35_o = regfile_out[37];
   assign reg_0x36_o = regfile_out[38];
   assign reg_0x37_o = regfile_out[39];
   assign reg_0x38_o = regfile_out[40];
   assign reg_0x39_o = regfile_out[41];
   assign reg_0x3a_o = regfile_out[42];
   assign reg_0x3b_o = regfile_out[43];
   assign reg_0x3c_o = regfile_out[44];
   assign reg_0x3d_o = regfile_out[45];
   assign reg_0x3e_o = regfile_out[46];
   assign reg_0x3f_o = regfile_out[47];
   assign reg_0x40_o = regfile_out[48];
   assign reg_0x41_o = regfile_out[49];
   assign reg_0x42_o = regfile_out[50];
   assign reg_0x43_o = regfile_out[51];
   assign reg_0x44_o = regfile_out[52];
   assign reg_0x45_o = regfile_out[53];
   assign reg_0x46_o = regfile_out[54];
   assign reg_0x47_o = regfile_out[55];
   assign reg_0x48_o = regfile_out[56];
   assign reg_0x49_o = regfile_out[57];
   assign reg_0x4a_o = regfile_out[58];
   assign reg_0x4b_o = regfile_out[59];
   assign reg_0x4c_o = regfile_out[60];
   assign reg_0x4d_o = regfile_out[61];
   assign reg_0x4e_o = regfile_out[62];
   assign reg_0x4f_o = regfile_out[63];
   assign reg_0x50_o = regfile_out[64];
   assign reg_0x51_o = regfile_out[65];
   assign reg_0x52_o = regfile_out[66];
   assign reg_0x53_o = regfile_out[67];
   assign reg_0x54_o = regfile_out[68];
   assign reg_0x55_o = regfile_out[69];
   assign reg_0x56_o = regfile_out[70];

   assign regfile_in[0] = reg_0x10_i;
   assign regfile_in[1] = reg_0x11_i;
   assign regfile_in[2] = reg_0x12_i;
   assign regfile_in[3] = reg_0x13_i;
   assign regfile_in[4] = reg_0x14_i;
   assign regfile_in[5] = reg_0x15_i;
   assign regfile_in[6] = reg_0x16_i;
   assign regfile_in[7] = reg_0x17_i;
   assign regfile_in[8] = reg_0x18_i;
   assign regfile_in[9] = reg_0x19_i;
   assign regfile_in[10] = reg_0x1a_i;
   assign regfile_in[11] = reg_0x1b_i;
   assign regfile_in[12] = reg_0x1c_i;
   assign regfile_in[13] = reg_0x1d_i;
   assign regfile_in[14] = reg_0x1e_i;
   assign regfile_in[15] = reg_0x1f_i;
   assign regfile_in[16] = reg_0x20_i;
   assign regfile_in[17] = reg_0x21_i;
   assign regfile_in[18] = reg_0x22_i;
   assign regfile_in[19] = reg_0x23_i;
   assign regfile_in[20] = reg_0x24_i;
   assign regfile_in[21] = reg_0x25_i;
   assign regfile_in[22] = reg_0x26_i;
   assign regfile_in[23] = reg_0x27_i;
   assign regfile_in[24] = reg_0x28_i;
   assign regfile_in[25] = reg_0x29_i;
   assign regfile_in[26] = reg_0x2a_i;
   assign regfile_in[27] = reg_0x2b_i;
   assign regfile_in[28] = reg_0x2c_i;
   assign regfile_in[29] = reg_0x2d_i;
   assign regfile_in[30] = reg_0x2e_i;
   assign regfile_in[31] = reg_0x2f_i;
   assign regfile_in[32] = reg_0x30_i;
   assign regfile_in[33] = reg_0x31_i;
   assign regfile_in[34] = reg_0x32_i;
   assign regfile_in[35] = reg_0x33_i;
   assign regfile_in[36] = reg_0x34_i;
   assign regfile_in[37] = reg_0x35_i;
   assign regfile_in[38] = reg_0x36_i;
   assign regfile_in[39] = reg_0x37_i;
   assign regfile_in[40] = reg_0x38_i;
   assign regfile_in[41] = reg_0x39_i;
   assign regfile_in[42] = reg_0x3a_i;
   assign regfile_in[43] = reg_0x3b_i;
   assign regfile_in[44] = reg_0x3c_i;
   assign regfile_in[45] = reg_0x3d_i;
   assign regfile_in[46] = reg_0x3e_i;
   assign regfile_in[47] = reg_0x3f_i;
   assign regfile_in[48] = reg_0x40_i;
   assign regfile_in[49] = reg_0x41_i;
   assign regfile_in[50] = reg_0x42_i;
   assign regfile_in[51] = reg_0x43_i;
   assign regfile_in[52] = reg_0x44_i;
   assign regfile_in[53] = reg_0x45_i;
   assign regfile_in[54] = reg_0x46_i;
   assign regfile_in[55] = reg_0x47_i;
   assign regfile_in[56] = reg_0x48_i;
   assign regfile_in[57] = reg_0x49_i;
   assign regfile_in[58] = reg_0x4a_i;
   assign regfile_in[59] = reg_0x4b_i;
   assign regfile_in[60] = reg_0x4c_i;
   assign regfile_in[61] = reg_0x4d_i;
   assign regfile_in[62] = reg_0x4e_i;
   assign regfile_in[63] = reg_0x4f_i;
   assign regfile_in[64] = reg_0x50_i;
   assign regfile_in[65] = reg_0x51_i;
   assign regfile_in[66] = reg_0x52_i;
   assign regfile_in[67] = reg_0x53_i;
   assign regfile_in[68] = reg_0x54_i;
   assign regfile_in[69] = reg_0x55_i;
   assign regfile_in[70] = reg_0x56_i;

   always @(posedge clk) begin
      wr_ack_o <= wr_i;
   end
   
   reg rd_i_dly0;
   reg rd_i_dly1;
   
   always @(posedge clk) begin
        rd_i_dly0 <= rd_i;
        rd_i_dly1 <= rd_i_dly0;
        rd_ack_o <= rd_i_dly1;
   end
   
   always @(posedge clk) begin
      if (rd_i) begin
         case (addr_i)
           14'h10: rd_data_o <= regfile_in[0];
           14'h11: rd_data_o <= regfile_in[1];
           14'h12: rd_data_o <= regfile_in[2];
           14'h13: rd_data_o <= regfile_in[3];
           14'h14: rd_data_o <= regfile_in[4];
           14'h15: rd_data_o <= regfile_in[5];
           14'h16: rd_data_o <= regfile_in[6];
           14'h17: rd_data_o <= regfile_in[7];
           14'h18: rd_data_o <= regfile_in[8];
           14'h19: rd_data_o <= regfile_in[9];
           14'h1a: rd_data_o <= regfile_in[10];
           14'h1b: rd_data_o <= regfile_in[11];
           14'h1c: rd_data_o <= regfile_in[12];
           14'h1d: rd_data_o <= regfile_in[13];
           14'h1e: rd_data_o <= regfile_in[14];
           14'h1f: rd_data_o <= regfile_in[15];
           14'h20: rd_data_o <= regfile_in[16];
           14'h21: rd_data_o <= regfile_in[17];
           14'h22: rd_data_o <= regfile_in[18];
           14'h23: rd_data_o <= regfile_in[19];
           14'h24: rd_data_o <= regfile_in[20];
           14'h25: rd_data_o <= regfile_in[21];
           14'h26: rd_data_o <= regfile_in[22];
           14'h27: rd_data_o <= regfile_in[23];
           14'h28: rd_data_o <= regfile_in[24];
           14'h29: rd_data_o <= regfile_in[25];
           14'h2a: rd_data_o <= regfile_in[26];
           14'h2b: rd_data_o <= regfile_in[27];
           14'h2c: rd_data_o <= regfile_in[28];
           14'h2d: rd_data_o <= regfile_in[29];
           14'h2e: rd_data_o <= regfile_in[30];
           14'h2f: rd_data_o <= regfile_in[31];
           14'h30: rd_data_o <= regfile_in[32];
           14'h31: rd_data_o <= regfile_in[33];
           14'h32: rd_data_o <= regfile_in[34];
           14'h33: rd_data_o <= regfile_in[35];
           14'h34: rd_data_o <= regfile_in[36];
           14'h35: rd_data_o <= regfile_in[37];
           14'h36: rd_data_o <= regfile_in[38];
           14'h37: rd_data_o <= regfile_in[39];
           14'h38: rd_data_o <= regfile_in[40];
           14'h39: rd_data_o <= regfile_in[41];
           14'h3a: rd_data_o <= regfile_in[42];
           14'h3b: rd_data_o <= regfile_in[43];
           14'h3c: rd_data_o <= regfile_in[44];
           14'h3d: rd_data_o <= regfile_in[45];
           14'h3e: rd_data_o <= regfile_in[46];
           14'h3f: rd_data_o <= regfile_in[47];
           14'h40: rd_data_o <= regfile_in[48];
           14'h41: rd_data_o <= regfile_in[49];
           14'h42: rd_data_o <= regfile_in[50];
           14'h43: rd_data_o <= regfile_in[51];
           14'h44: rd_data_o <= regfile_in[52];
           14'h45: rd_data_o <= regfile_in[53];
           14'h46: rd_data_o <= regfile_in[54];
           14'h47: rd_data_o <= regfile_in[55];
           14'h48: rd_data_o <= regfile_in[56];
           14'h49: rd_data_o <= regfile_in[57];
           14'h4a: rd_data_o <= regfile_in[58];
           14'h4b: rd_data_o <= regfile_in[59];
           14'h4c: rd_data_o <= regfile_in[60];
           14'h4d: rd_data_o <= regfile_in[61];
           14'h4e: rd_data_o <= regfile_in[62];
           14'h4f: rd_data_o <= regfile_in[63];
           14'h50: rd_data_o <= regfile_in[64];
           14'h51: rd_data_o <= regfile_in[65];
           14'h52: rd_data_o <= regfile_in[66];
           14'h53: rd_data_o <= regfile_in[67];
           14'h54: rd_data_o <= regfile_in[68];
           14'h55: rd_data_o <= regfile_in[69];
           14'h56: rd_data_o <= regfile_in[70];
         endcase 
      end
   end

   integer           i;
   always @(posedge clk) begin
      if (rst_i)
        begin
           for (i = 0; i < 71; i = i + 1) begin
              regfile_out[i] <= 0;
           end
        end
      else
        begin
           if (wr_i)
             case (addr_i)
               14'h10: regfile_out[0] <= wr_data_i;
               14'h11: regfile_out[1] <= wr_data_i;
               14'h12: regfile_out[2] <= wr_data_i;
               14'h13: regfile_out[3] <= wr_data_i;
               14'h14: regfile_out[4] <= wr_data_i;
               14'h15: regfile_out[5] <= wr_data_i;
               14'h16: regfile_out[6] <= wr_data_i;
               14'h17: regfile_out[7] <= wr_data_i;
               14'h18: regfile_out[8] <= wr_data_i;
               14'h19: regfile_out[9] <= wr_data_i;
               14'h1a: regfile_out[10] <= wr_data_i;
               14'h1b: regfile_out[11] <= wr_data_i;
               14'h1c: regfile_out[12] <= wr_data_i;
               14'h1d: regfile_out[13] <= wr_data_i;
               14'h1e: regfile_out[14] <= wr_data_i;
               14'h1f: regfile_out[15] <= wr_data_i;
               14'h20: regfile_out[16] <= wr_data_i;
               14'h21: regfile_out[17] <= wr_data_i;
               14'h22: regfile_out[18] <= wr_data_i;
               14'h23: regfile_out[19] <= wr_data_i;
               14'h24: regfile_out[20] <= wr_data_i;
               14'h25: regfile_out[21] <= wr_data_i;
               14'h26: regfile_out[22] <= wr_data_i;
               14'h27: regfile_out[23] <= wr_data_i;
               14'h28: regfile_out[24] <= wr_data_i;
               14'h29: regfile_out[25] <= wr_data_i;
               14'h2a: regfile_out[26] <= wr_data_i;
               14'h2b: regfile_out[27] <= wr_data_i;
               14'h2c: regfile_out[28] <= wr_data_i;
               14'h2d: regfile_out[29] <= wr_data_i;
               14'h2e: regfile_out[30] <= wr_data_i;
               14'h2f: regfile_out[31] <= wr_data_i;
               14'h30: regfile_out[32] <= wr_data_i;
               14'h31: regfile_out[33] <= wr_data_i;
               14'h32: regfile_out[34] <= wr_data_i;
               14'h33: regfile_out[35] <= wr_data_i;
               14'h34: regfile_out[36] <= wr_data_i;
               14'h35: regfile_out[37] <= wr_data_i;
               14'h36: regfile_out[38] <= wr_data_i;
               14'h37: regfile_out[39] <= wr_data_i;
               14'h38: regfile_out[40] <= wr_data_i;
               14'h39: regfile_out[41] <= wr_data_i;
               14'h3a: regfile_out[42] <= wr_data_i;
               14'h3b: regfile_out[43] <= wr_data_i;
               14'h3c: regfile_out[44] <= wr_data_i;
               14'h3d: regfile_out[45] <= wr_data_i;
               14'h3e: regfile_out[46] <= wr_data_i;
               14'h3f: regfile_out[47] <= wr_data_i;
               14'h40: regfile_out[48] <= wr_data_i;
               14'h41: regfile_out[49] <= wr_data_i;
               14'h42: regfile_out[50] <= wr_data_i;
               14'h43: regfile_out[51] <= wr_data_i;
               14'h44: regfile_out[52] <= wr_data_i;
               14'h45: regfile_out[53] <= wr_data_i;
               14'h46: regfile_out[54] <= wr_data_i;
               14'h47: regfile_out[55] <= wr_data_i;
               14'h48: regfile_out[56] <= wr_data_i;
               14'h49: regfile_out[57] <= wr_data_i;
               14'h4a: regfile_out[58] <= wr_data_i;
               14'h4b: regfile_out[59] <= wr_data_i;
               14'h4c: regfile_out[60] <= wr_data_i;
               14'h4d: regfile_out[61] <= wr_data_i;
               14'h4e: regfile_out[62] <= wr_data_i;
               14'h4f: regfile_out[63] <= wr_data_i;
               14'h50: regfile_out[64] <= wr_data_i;
               14'h51: regfile_out[65] <= wr_data_i;
               14'h52: regfile_out[66] <= wr_data_i;
               14'h53: regfile_out[67] <= wr_data_i;
               14'h54: regfile_out[68] <= wr_data_i;
               14'h55: regfile_out[69] <= wr_data_i;
               14'h56: regfile_out[70] <= wr_data_i;
             endcase
        end
   end
endmodule