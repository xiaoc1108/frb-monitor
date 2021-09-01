/* -*- coding: us-ascii-dos -*-
 *
 * Copyright Signal Processing Devices Sweden AB. All rights reserved.
 * See document "08-0175 EULA" for specific license terms regarding this file.
 *
 * Description   : User logic 2 module
 * Documentation :
 *
 */

`timescale 1 ns / 1 ps

`default_nettype none
`include "user_logic2_defines.vh"

module user_logic2 # (
   // Do not modify the parameters beyond this line
   parameter integer CH_TRIG_DATA_WIDTH =
      `UL2_SPD_ANALOG_CHANNELS * `UL2_SPD_DATAWIDTH_BITS
      * `UL2_SPD_PARALLEL_SAMPLES,
   parameter integer CH_TRIG_VECTOR_WIDTH =
      `UL2_SPD_ANALOG_CHANNELS
      * (`UL2_SPD_NUM_CH_TRIG_BITS + `UL2_SPD_NUM_TRIG_ADDBITS
         +`UL2_SPD_NUM_TRIG_DATARD_ADDFRACBITS),
   parameter integer ADDR_WIDTH = 14
) (
   input wire                             clk_reg_i,
   input wire                             rst_i,
   input wire                             wr_i,
   output wire                            wr_ack_o,
   input wire [ADDR_WIDTH-1:0]            addr_i,
   input wire [31:0]                      wr_data_i,
   input wire                             rd_i,
   output wire                            rd_ack_o,
   output wire [31:0]                     rd_data_o,

   // Ports of AXI-S Slave Bus Interface s_axis
   input wire                             s_axis_aclk,
   input wire                             s_axis_aresetn,
   input wire [`UL2_DATA_BUS_WIDTH-1 : 0] s_axis_tdata,
   input wire                             s_axis_tvalid,

   // Ports of AXI-S Master Bus Interface m_axis
   input wire                             m_axis_aclk,
   input wire                             m_axis_aresetn,
   output reg                             m_axis_tvalid,
   output reg [`UL2_DATA_BUS_WIDTH-1 : 0] m_axis_tdata,
   input wire                             m_axis_tready,

   // GPIO
   // To board
   input wire [11:0]                      gpio_in_i,
   output wire [11:0]                     gpio_out_o,
   output wire [5:0]                      gpio_dir_o,

   input wire [3:0]                       gpdi_in_i,
   output wire [2:0]                      gpdo_out_o,

   input wire                             gpio_trig_in_i,
   output wire                            gpio_trig_out_o,
   output wire                            gpio_trig_dir_o,

   input wire                             gpio_sync_in_i,
   output wire                            gpio_sync_out_o,
   output wire                            gpio_sync_dir_o,


   // From CPU
   output wire [11:0]                     gpio_in_o,
   input wire [11:0]                      gpio_out_i,
   input wire [5:0]                       gpio_dir_i,

   output wire [3:0]                      gpdi_in_o,
   input wire [2:0]                       gpdo_out_i,

   output wire                            gpio_trig_in_o,
   input wire                             gpio_trig_out_i,
   input wire                             gpio_trig_dir_i,

   output wire                            gpio_sync_in_o,
   input wire                             gpio_sync_out_i,
   input wire                             gpio_sync_dir_i,

   // DRAM ports
   input wire                             clk_mem_i,

   output wire [511:0]                    write1_data_o,
   input wire                             write1_done_i,
   output wire                            write1_empty_o,
   output wire [31:0]                     write1_first_addr_o,
   output wire [31:0]                     write1_last_addr_o,
   output wire                            write1_last_o,
   input wire                             write1_read_i,
   output wire                            write1_reset_o,
   output wire                            write1_strobe_o,

   output wire [511:0]                    write2_data_o,
   input wire                             write2_done_i,
   output wire                            write2_empty_o,
   output wire [31:0]                     write2_first_addr_o,
   output wire [31:0]                     write2_last_addr_o,
   output wire                            write2_last_o,
   input wire                             write2_read_i,
   output wire                            write2_reset_o,
   output wire                            write2_strobe_o,

   output wire                            read1_abort_o,
   output wire                            read1_afull_o,
   input wire [511:0]                     read1_data_i,
   input wire                             read1_done_i,
   output wire [31:0]                     read1_first_addr_o,
   input wire                             read1_firstdata_i,
   output wire [31:0]                     read1_high_addr_o,
   output wire [31:0]                     read1_last_addr_o,
   input wire                             read1_lastdata_i,
   output wire [31:0]                     read1_low_addr_o,
   output wire                            read1_reset_o,
   input wire                             read1_sent_i,
   output wire                            read1_strobe_o,
   input wire                             read1_wr_i,

   output wire                            read2_abort_o,
   output wire                            read2_afull_o,
   input wire [511:0]                     read2_data_i,
   input wire                             read2_done_i,
   output wire [31:0]                     read2_first_addr_o,
   input wire                             read2_firstdata_i,
   output wire [31:0]                     read2_high_addr_o,
   output wire [31:0]                     read2_last_addr_o,
   input wire                             read2_lastdata_i,
   output wire [31:0]                     read2_low_addr_o,
   output wire                            read2_reset_o,
   input wire                             read2_sent_i,
   output wire                            read2_strobe_o,
   input wire                             read2_wr_i,
   input wire [127:0]                     license_bits_i,
   input wire                             license_valid_i
);
   // The BUS_PIPELINE value must always be set equal to the latency of your
   // data processing in this module in order to synchronize unused bus signals.
   localparam BUS_PIPELINE = 2;

   // These includes are need to extract data from the AXIS bus
`include "device_param.vh"
`include "bus_splitter_rr.vh"


   // User application code
   wire [31:0] reg_0x10_in;
   wire [31:0] reg_0x11_in;
   wire [31:0] reg_0x12_in;
   wire [31:0] reg_0x13_in;
   wire [31:0] cmd_ch_dly_in [0:63];
   wire [31:0] cmd_threshold_in;
   wire [31:0] snapshot_in;
   (* mark_debug = "true" *) wire [31:0] trigger_ext_in;
   
   wire [31:0] reg_0x10_out;
   wire [31:0] reg_0x11_out;
   wire [31:0] reg_0x12_out;
   wire [31:0] reg_0x13_out;
   wire [31:0] cmd_ch_dly_out [0:63];
   wire [31:0] cmd_threshold_out;
   wire [31:0] snapshot_out;
   wire [31:0] trigger_ext_out;

   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_a_in;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_b_in;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_c_in;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_d_in;

   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_a_out;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_b_out;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_c_out;
   reg [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_d_out;

   reg data_valid_a_in;
   reg data_valid_a_out;
   reg data_valid_b_in;
   reg data_valid_b_out;
   reg data_valid_c_in;
   reg data_valid_c_out;
   reg data_valid_d_in;
   reg data_valid_d_out;
   reg data_valid_testpattern;

   reg [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] ch_trig_vector_a;
   reg [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] ch_trig_vector_b;
   reg [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] ch_trig_vector_c;
   reg [RR_CH_TRIG_VECTOR_1_WIDTH-1:0] ch_trig_vector_d;

   assign reg_0x10_in = reg_0x10_out;
   assign reg_0x11_in = reg_0x11_out;
   assign reg_0x12_in = 32'haabbccdd;
   assign reg_0x13_in = 32'h12345678;
   
   genvar m;
   
   generate
   for (m = 0; m <= 63; m = m + 1) begin
    assign cmd_ch_dly_in[m] = cmd_ch_dly_out[m];
   end
   endgenerate
   
   assign cmd_threshold_in = cmd_threshold_out;
   
   
   // Note: This register file is an example. The source code is included so
   // that it can be modified by the user.
   ul2_regfile #(
       .ADDR_WIDTH(ADDR_WIDTH)
    ) regfile_inst (
        .clk(clk_reg_i),
        .rst_i(rst_i),
        .addr_i(addr_i),
    
        .wr_i(wr_i),
        .wr_ack_o(wr_ack_o),
        .wr_data_i(wr_data_i),
    
        .rd_i(rd_i),
        .rd_ack_o(rd_ack_o),
        .rd_data_o(rd_data_o),

        .reg_0x10_i(reg_0x10_in),
        .reg_0x11_i(reg_0x11_in),
        .reg_0x12_i(reg_0x12_in),
        .reg_0x13_i(reg_0x13_in),
        .reg_0x14_i(cmd_ch_dly_in[0]),
        .reg_0x15_i(cmd_ch_dly_in[1]),
        .reg_0x16_i(cmd_ch_dly_in[2]),
        .reg_0x17_i(cmd_ch_dly_in[3]),
        .reg_0x18_i(cmd_ch_dly_in[4]),
        .reg_0x19_i(cmd_ch_dly_in[5]),
        .reg_0x1a_i(cmd_ch_dly_in[6]),
        .reg_0x1b_i(cmd_ch_dly_in[7]),
        .reg_0x1c_i(cmd_ch_dly_in[8]),
        .reg_0x1d_i(cmd_ch_dly_in[9]),
        .reg_0x1e_i(cmd_ch_dly_in[10]),
        .reg_0x1f_i(cmd_ch_dly_in[11]),
        .reg_0x20_i(cmd_ch_dly_in[12]),
        .reg_0x21_i(cmd_ch_dly_in[13]),
        .reg_0x22_i(cmd_ch_dly_in[14]),
        .reg_0x23_i(cmd_ch_dly_in[15]),
        .reg_0x24_i(cmd_ch_dly_in[16]),
        .reg_0x25_i(cmd_ch_dly_in[17]),
        .reg_0x26_i(cmd_ch_dly_in[18]),
        .reg_0x27_i(cmd_ch_dly_in[19]),
        .reg_0x28_i(cmd_ch_dly_in[20]),
        .reg_0x29_i(cmd_ch_dly_in[21]),
        .reg_0x2a_i(cmd_ch_dly_in[22]),
        .reg_0x2b_i(cmd_ch_dly_in[23]),
        .reg_0x2c_i(cmd_ch_dly_in[24]),
        .reg_0x2d_i(cmd_ch_dly_in[25]),
        .reg_0x2e_i(cmd_ch_dly_in[26]),
        .reg_0x2f_i(cmd_ch_dly_in[27]),
        .reg_0x30_i(cmd_ch_dly_in[28]),
        .reg_0x31_i(cmd_ch_dly_in[29]),
        .reg_0x32_i(cmd_ch_dly_in[30]),
        .reg_0x33_i(cmd_ch_dly_in[31]),
        .reg_0x34_i(cmd_ch_dly_in[32]),
        .reg_0x35_i(cmd_ch_dly_in[33]),
        .reg_0x36_i(cmd_ch_dly_in[34]),
        .reg_0x37_i(cmd_ch_dly_in[35]),
        .reg_0x38_i(cmd_ch_dly_in[36]),
        .reg_0x39_i(cmd_ch_dly_in[37]),
        .reg_0x3a_i(cmd_ch_dly_in[38]),
        .reg_0x3b_i(cmd_ch_dly_in[39]),
        .reg_0x3c_i(cmd_ch_dly_in[40]),
        .reg_0x3d_i(cmd_ch_dly_in[41]),
        .reg_0x3e_i(cmd_ch_dly_in[42]),
        .reg_0x3f_i(cmd_ch_dly_in[43]),
        .reg_0x40_i(cmd_ch_dly_in[44]),
        .reg_0x41_i(cmd_ch_dly_in[45]),
        .reg_0x42_i(cmd_ch_dly_in[46]),
        .reg_0x43_i(cmd_ch_dly_in[47]),
        .reg_0x44_i(cmd_ch_dly_in[48]),
        .reg_0x45_i(cmd_ch_dly_in[49]),
        .reg_0x46_i(cmd_ch_dly_in[50]),
        .reg_0x47_i(cmd_ch_dly_in[51]),
        .reg_0x48_i(cmd_ch_dly_in[52]),
        .reg_0x49_i(cmd_ch_dly_in[53]),
        .reg_0x4a_i(cmd_ch_dly_in[54]),
        .reg_0x4b_i(cmd_ch_dly_in[55]),
        .reg_0x4c_i(cmd_ch_dly_in[56]),
        .reg_0x4d_i(cmd_ch_dly_in[57]),
        .reg_0x4e_i(cmd_ch_dly_in[58]),
        .reg_0x4f_i(cmd_ch_dly_in[59]),
        .reg_0x50_i(cmd_ch_dly_in[60]),
        .reg_0x51_i(cmd_ch_dly_in[61]),
        .reg_0x52_i(cmd_ch_dly_in[62]),
        .reg_0x53_i(cmd_ch_dly_in[63]),
        .reg_0x54_i(cmd_threshold_in),
        .reg_0x55_i(snapshot_in),
        .reg_0x56_i(trigger_ext_in),

        .reg_0x10_o(reg_0x10_out),
        .reg_0x11_o(reg_0x11_out),
        .reg_0x12_o(reg_0x12_out),
        .reg_0x13_o(reg_0x13_out),
        .reg_0x14_o(cmd_ch_dly_out[0]),
        .reg_0x15_o(cmd_ch_dly_out[1]),
        .reg_0x16_o(cmd_ch_dly_out[2]),
        .reg_0x17_o(cmd_ch_dly_out[3]),
        .reg_0x18_o(cmd_ch_dly_out[4]),
        .reg_0x19_o(cmd_ch_dly_out[5]),
        .reg_0x1a_o(cmd_ch_dly_out[6]),
        .reg_0x1b_o(cmd_ch_dly_out[7]),
        .reg_0x1c_o(cmd_ch_dly_out[8]),
        .reg_0x1d_o(cmd_ch_dly_out[9]),
        .reg_0x1e_o(cmd_ch_dly_out[10]),
        .reg_0x1f_o(cmd_ch_dly_out[11]),
        .reg_0x20_o(cmd_ch_dly_out[12]),
        .reg_0x21_o(cmd_ch_dly_out[13]),
        .reg_0x22_o(cmd_ch_dly_out[14]),
        .reg_0x23_o(cmd_ch_dly_out[15]),
        .reg_0x24_o(cmd_ch_dly_out[16]),
        .reg_0x25_o(cmd_ch_dly_out[17]),
        .reg_0x26_o(cmd_ch_dly_out[18]),
        .reg_0x27_o(cmd_ch_dly_out[19]),
        .reg_0x28_o(cmd_ch_dly_out[20]),
        .reg_0x29_o(cmd_ch_dly_out[21]),
        .reg_0x2a_o(cmd_ch_dly_out[22]),
        .reg_0x2b_o(cmd_ch_dly_out[23]),
        .reg_0x2c_o(cmd_ch_dly_out[24]),
        .reg_0x2d_o(cmd_ch_dly_out[25]),
        .reg_0x2e_o(cmd_ch_dly_out[26]),
        .reg_0x2f_o(cmd_ch_dly_out[27]),
        .reg_0x30_o(cmd_ch_dly_out[28]),
        .reg_0x31_o(cmd_ch_dly_out[29]),
        .reg_0x32_o(cmd_ch_dly_out[30]),
        .reg_0x33_o(cmd_ch_dly_out[31]),
        .reg_0x34_o(cmd_ch_dly_out[32]),
        .reg_0x35_o(cmd_ch_dly_out[33]),
        .reg_0x36_o(cmd_ch_dly_out[34]),
        .reg_0x37_o(cmd_ch_dly_out[35]),
        .reg_0x38_o(cmd_ch_dly_out[36]),
        .reg_0x39_o(cmd_ch_dly_out[37]),
        .reg_0x3a_o(cmd_ch_dly_out[38]),
        .reg_0x3b_o(cmd_ch_dly_out[39]),
        .reg_0x3c_o(cmd_ch_dly_out[40]),
        .reg_0x3d_o(cmd_ch_dly_out[41]),
        .reg_0x3e_o(cmd_ch_dly_out[42]),
        .reg_0x3f_o(cmd_ch_dly_out[43]),
        .reg_0x40_o(cmd_ch_dly_out[44]),
        .reg_0x41_o(cmd_ch_dly_out[45]),
        .reg_0x42_o(cmd_ch_dly_out[46]),
        .reg_0x43_o(cmd_ch_dly_out[47]),
        .reg_0x44_o(cmd_ch_dly_out[48]),
        .reg_0x45_o(cmd_ch_dly_out[49]),
        .reg_0x46_o(cmd_ch_dly_out[50]),
        .reg_0x47_o(cmd_ch_dly_out[51]),
        .reg_0x48_o(cmd_ch_dly_out[52]),
        .reg_0x49_o(cmd_ch_dly_out[53]),
        .reg_0x4a_o(cmd_ch_dly_out[54]),
        .reg_0x4b_o(cmd_ch_dly_out[55]),
        .reg_0x4c_o(cmd_ch_dly_out[56]),
        .reg_0x4d_o(cmd_ch_dly_out[57]),
        .reg_0x4e_o(cmd_ch_dly_out[58]),
        .reg_0x4f_o(cmd_ch_dly_out[59]),
        .reg_0x50_o(cmd_ch_dly_out[60]),
        .reg_0x51_o(cmd_ch_dly_out[61]),
        .reg_0x52_o(cmd_ch_dly_out[62]),
        .reg_0x53_o(cmd_ch_dly_out[63]),
        .reg_0x54_o(cmd_threshold_out),
        .reg_0x55_o(snapshot_out),
        .reg_0x56_o(trigger_ext_out)
   );
    
    
   // pfb
   
   wire [1023: 0] pfb_out;
   wire pfb_out_valid;

   wire [1023: 0] ave_out;
   wire ave_out_valid;

   wire [1023: 0] dedispersion_out;
   wire dedispersion_out_valid;
   wire [2047: 0] cmd_ch_dly;
   
   (* mark_debug = "true" *) wire [21: 0] integrate_out;
   wire integrate_out_valid;
   
   
   (* mark_debug = "true" *) wire trigger;
   (* mark_debug = "true" *) wire trigger_ext;
   
   
   (* mark_debug = "true" *) wire debug_valid;
   (* mark_debug = "true" *) wire signed [15:0] debug [0: 63];
   
   
   os_pfb_channelizer u_os_pfb_channelizer (
       .clk_data(s_axis_aclk),
       .rst('b0),
       .data_in(data_a_in),
       .data_in_valid(data_valid_a_in),
       .data_out(pfb_out),
       .data_out_valid(pfb_out_valid)
   );
   
   
   ave_filterbank u_ave_filterbank (
       .clk_data(s_axis_aclk),
       .rst('b0),
       .data_in(pfb_out),
       .data_in_valid(pfb_out_valid),
       .data_out(ave_out),
       .data_out_valid(ave_out_valid)
   );
   
   
   generate
   for (m = 0; m <= 63; m = m + 1) begin
       assign cmd_ch_dly[m * 32 +: 32] = cmd_ch_dly_out[m];
   end
   endgenerate
   
   de_dispersion u_de_diserpsion (
       .clk_data(s_axis_aclk),
       .clk_reg(clk_reg_i),
       .rst(wr_ack_o),
       .data_in(ave_out),
       .data_in_valid(ave_out_valid),
       .cmd_ch_dly(cmd_ch_dly),
       .data_out(dedispersion_out),
       .data_out_valid(dedispersion_out_valid)
    );
   
   channel_integration u_channel_integration (
       .clk_data(s_axis_aclk),
       .rst('b0),
       .data_in(dedispersion_out),
       .data_in_valid(dedispersion_out_valid),
       .data_out(integrate_out),
       .data_out_valid(integrate_out_valid)
   );
   
   trigger u_trigger (
        .clk_data(s_axis_aclk),
        .clk_reg(clk_reg_i),
        .rst('b0),
        .data_in(integrate_out),
        .data_in_valid(integrate_out_valid),
        .cmd_threshold(cmd_threshold_out),
        .trigger(trigger)
   );


   reg  r_rd_i;
   reg  r1_rd_i;
   reg  r2_rd_i;
      
   (* mark_debug = "true" *) wire rd_fifo_en;
   always @(posedge clk_reg_i) begin
        if (addr_i == 14'h55) begin
            r_rd_i <= rd_i;
            r1_rd_i <= r_rd_i;
            r2_rd_i <= r1_rd_i;
        end
   end
   
   assign rd_fifo_en = r1_rd_i & (~r2_rd_i);
   
   snapshot u_snapshot (
       .clk_data(s_axis_aclk),
       .clk_reg(clk_reg_i),
       .rst('b0),
       .trigger(trigger),
       .data_in(dedispersion_out),
       .data_in_valid(dedispersion_out_valid),
       .rd_fifo_en(rd_fifo_en),
       .data_out(snapshot_in)
   );
   
   sync_pulse u_sync_pulse (
       .clka(s_axis_aclk),
       .clkb(clk_reg_i),
       .rst('b0),
       .pulse_ina(trigger),
       .pulse_outb(trigger_ext)
   );
   
   assign trigger_ext_in = {{31{1'b0}},trigger_ext};
   
   generate
   for (m = 0; m <= 63; m = m + 1) begin
       assign debug[m] = dedispersion_out[m * 16 +: 16];
   end
   endgenerate
    
   assign debug_valid = dedispersion_out_valid;
    
   //NOTE: Vivado requires two registers with ASYNC_REG="TRUE" constraint for
   //clock domain crossing.
   (* ASYNC_REG="TRUE" *) reg [1:0] clear_cnt;
   (* ASYNC_REG="TRUE" *) reg [1:0] mode;
   (* ASYNC_REG="TRUE" *) reg [1:0] enable_data_valid;
   always @ (posedge s_axis_aclk)
     begin
        clear_cnt         <= {clear_cnt[0],         reg_0x10_out[0]};
        mode              <= {mode[0],              reg_0x10_out[1]};
        enable_data_valid <= {enable_data_valid[0], reg_0x11_out[0]};
     end

   // Test pattern example code
   reg  [15:0]                                        cnt;
   wire [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_a_x;
   wire [SPD_PARALLEL_SAMPLES*SPD_DATAWIDTH_BITS-1:0] data_b_x;

   always @ (posedge s_axis_aclk)
      begin
        if(clear_cnt[1])
          cnt <= 0;
        if(data_valid_testpattern)
          cnt = cnt + SPD_PARALLEL_SAMPLES;
      end

   if (SPD_PARALLEL_SAMPLES  == 8)
      begin
        //Sample order:     Last                                                                          First
        assign  data_a_x = {cnt+16'd7, cnt+16'd6, cnt+16'd5, cnt+16'd4,  cnt+16'd3, cnt+16'd2, cnt+16'd1, cnt  };
        assign  data_b_x = {16'hf,     16'he,     16'hd,     16'hc,      16'hb,     16'ha,     16'h9,     16'h8};
      end
   else
      begin // 4
        //Sample order:     Last                             First
        assign  data_a_x = {cnt+16'd3, cnt+16'd2, cnt+16'd1, cnt  };
        assign  data_b_x = {16'hd,     16'hc,     16'hb,     16'ha};
      end

   // Data valid gating for testpattern
   always @ (posedge s_axis_aclk)
      begin
        if(enable_data_valid[1])
          begin
             // NOTE: "data_valid_testpattern" will most likely be a user
             // generated signal in an real use-case. Using "data_valid_a_in"
             // is just a convenient way of generating pulses in this example.
             data_valid_testpattern <= data_valid_a_in;
          end
      end

   // Mux to select data or testpattern
   // BUS_PIPELINE = 2
   always @ (posedge s_axis_aclk)
     begin
        if(mode[1])
          begin // Test pattern
             data_a_out <= data_a_x;
             data_b_out <= data_b_x;

             //NOTE: Data valid must be asserted in all channes simultaneously
             //when running raw streaming (e.g. without headers) It is
             //possible to set a channel mask via the ADQAPI to read out
             //a subset of the channels, so even if data valid is asserted
             //data can still be discarded.
             data_valid_a_out <= data_valid_testpattern;
             data_valid_b_out <= data_valid_testpattern;
             data_valid_c_out <= data_valid_testpattern;
             data_valid_d_out <= data_valid_testpattern;
          end
        else
          begin // Normal
             data_a_out <= data_a_in;
             data_b_out <= data_b_in;
             data_c_out <= data_c_in;
             data_d_out <= data_d_in;

             data_valid_a_out <= data_valid_a_in;
             data_valid_b_out <= data_valid_b_in;
             data_valid_c_out <= data_valid_c_in;
             data_valid_d_out <= data_valid_d_in;
          end
     end

   //BUS_PIPELINE = 1
   always @ (posedge s_axis_aclk) begin
        // Extract all parallel samples for each channel
        data_a_in <= extract_ch_all(CH_A);
        if (`UL2_SPD_PROCESSING_CHANNELS_FULL > 1)
          data_b_in <= extract_ch_all(CH_B);
        if (`UL2_SPD_PROCESSING_CHANNELS_FULL > 2)
          data_c_in <= extract_ch_all(CH_C);
        if (`UL2_SPD_PROCESSING_CHANNELS_FULL > 3)
          data_d_in <= extract_ch_all(CH_D);

        data_valid_a_in <= extract_data_valid(CH_A);
        if (`UL2_SPD_PROCESSING_CHANNELS_FULL > 1)
          data_valid_b_in <= extract_data_valid(CH_B);
        if (`UL2_SPD_PROCESSING_CHANNELS_FULL > 2)
          data_valid_c_in <= extract_data_valid(CH_C);
        if (`UL2_SPD_PROCESSING_CHANNELS_FULL > 3)
          data_valid_d_in <= extract_data_valid(CH_D);
    end

   // User inserting into bus output
   // BUS_PIPELINE = 2
   always@(*)
     begin
        init_bus_output();
        // Note: Non-inserted signals will automatically be addded by a macro.
        //       They will be delayed by the value defined by BUS_PIPELINE.

        insert_ch_all(data_a_out, CH_A);
        if (`UL2_SPD_PROCESSING_CHANNELS_FULL > 1)
          insert_ch_all(data_b_out, CH_B);
       if (`UL2_SPD_PROCESSING_CHANNELS_FULL > 2)
          insert_ch_all(data_c_out, CH_C);
       if (`UL2_SPD_PROCESSING_CHANNELS_FULL > 3)
          insert_ch_all(data_d_out, CH_D);

        insert_data_valid(data_valid_a_out, CH_A);
        if (`UL2_SPD_PROCESSING_CHANNELS_FULL > 1)
          insert_data_valid(data_valid_b_out, CH_B);
        if (`UL2_SPD_PROCESSING_CHANNELS_FULL > 2)
          insert_data_valid(data_valid_c_out, CH_C);
        if (`UL2_SPD_PROCESSING_CHANNELS_FULL > 3)
          insert_data_valid(data_valid_d_out, CH_D);

        finish_bus_output();
     end

   // GPIO
   assign gpio_in_o   = gpio_in_i;
   assign gpio_out_o  = gpio_out_i;
   assign gpio_dir_o  = gpio_dir_i;

   assign gpdi_in_o  = gpdi_in_i;
   assign gpdo_out_o = gpdo_out_i;

   assign gpio_trig_in_o = gpio_trig_in_i;
   assign gpio_trig_out_o = gpio_trig_out_i;
   assign gpio_trig_dir_o = gpio_trig_dir_i;

   assign gpio_sync_in_o = gpio_sync_in_i;
   assign gpio_sync_out_o = gpio_sync_out_i;
   assign gpio_sync_dir_o = gpio_sync_dir_i;


   // DRAM port outputs must be set to zero if unused
   assign write1_data_o = 0;
   assign write1_empty_o = 0;
   assign write1_first_addr_o = 0;
   assign write1_last_addr_o = 0;
   assign write1_last_o = 0;
   assign write1_reset_o = 0;
   assign write1_strobe_o = 0;

   assign write2_data_o = 0;
   assign write2_empty_o = 0;
   assign write2_first_addr_o = 0;
   assign write2_last_addr_o = 0;
   assign write2_last_o = 0;
   assign write2_reset_o = 0;
   assign write2_strobe_o = 0;

   assign read1_abort_o = 0;
   assign read1_afull_o = 0;
   assign read1_first_addr_o = 0;
   assign read1_high_addr_o = 0;
   assign read1_last_addr_o = 0;
   assign read1_low_addr_o = 0;
   assign read1_reset_o = 0;
   assign read1_strobe_o = 0;

   assign read2_abort_o = 0;
   assign read2_afull_o = 0;
   assign read2_first_addr_o = 0;
   assign read2_high_addr_o = 0;
   assign read2_last_addr_o = 0;
   assign read2_low_addr_o = 0;
   assign read2_reset_o = 0;
   assign read2_strobe_o = 0;

endmodule

`default_nettype wire