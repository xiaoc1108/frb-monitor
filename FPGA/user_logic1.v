`timescale 1 ns / 1 ps

`default_nettype none

`include "user_logic1_defines.vh"
//`define DISABLE_UL1_FILTER 

module user_logic1 #(
   // Users to add parameters here

   // User parameters ends

   // Do not modify the parameters beyond this line
   parameter integer ADDR_WIDTH = 14
)(
   // License inputs
   input wire [63:0] license_bitfield_i,
   input wire license_valid_i,

   input wire clk,
   input wire rst_i,

   input wire [ADDR_WIDTH-1:0] addr_i,

   input wire [31:0] wr_data_i,
   input wire wr_i,
   output wire wr_ack_o,

   output wire [31:0] rd_data_o,
   input wire rd_i,
   output wire rd_ack_o,

   // Ports of AXI-S Slave Bus Interface s_axis
   input wire [`UL1_DATA_BUS_WIDTH-1:0] s_axis_tdata,
   input wire s_axis_aclk,
   input wire s_axis_aresetn,
   input wire s_axis_tvalid,

   // Ports of AXI-S Master Bus Interface m_axis
   output reg [`UL1_DATA_BUS_WIDTH-1:0] m_axis_tdata,
   input wire m_axis_aclk,
   input wire m_axis_aresetn,
   output reg m_axis_tvalid,

   // MTCA-specific signals (non-connected in PXIe/PCIe/USB)
   input wire [3:0] mlvds_rx_o_from_datatrig_i,
   input wire [3:0] mlvds_tx_o_from_datatrig_i,

   input wire [3:0] mlvds_rx_i,
   input wire [3:0] mlvds_tx_i,
   output wire [3:0] mlvds_rx_o,
   output wire [3:0] mlvds_tx_o
);


`ifdef DISABLE_UL1_FILTER
   localparam ORDER            = 0;
   localparam COEFF_WIDTH      = 0;
   localparam COEFF_FRAC_WIDTH = 0;
   localparam NOF_COEFFS       = 0;

   localparam FILTER_EXISTS = 0;

   // Modify BUS_PIPELINE as necessary.
   localparam BUS_PIPELINE = 1;
`else

   localparam ORDER            = 64;
   localparam COEFF_WIDTH      = 16;
   localparam COEFF_FRAC_WIDTH = 14;
   localparam NOF_COEFFS       = ORDER / 2 + 1;
   localparam SETUP_FIR =
      /* Barrel shifter setup */
      2 + ORDER / (2 * `UL1_SPD_PARALLEL_SAMPLES);
   localparam PIPELINE_FIR =
      /* DSP propagation delay */
      7 + ORDER / 2
      /* Input stage propagation delay */
      + 1;

   localparam FILTER_EXISTS = 1;

   // Modify BUS_PIPELINE as necessary.
   localparam BUS_PIPELINE = SETUP_FIR + PIPELINE_FIR;
`endif

   genvar ch;
   genvar k;

   // User localparam ends

   // These includes are needed to insert/extract data to/from the AXI-S buses
`include "device_param.vh"
`include "bus_splitter_rt.vh"

   // User application code
   wire [31:0] reg_0x10_in;
   wire [31:0] reg_0x11_in;
   wire [31:0] reg_0x12_in;
   wire [31:0] reg_0x13_in;
   wire [31:0] reg_filter_ctrl_in;
   wire [31:0] reg_filter_coeff_in;
   wire [31:0] reg_filter_config_in;

   wire [31:0] reg_0x10_out;
   wire [31:0] reg_0x11_out;
   wire [31:0] reg_0x12_out;
   wire [31:0] reg_0x13_out;
   wire [31:0] reg_filter_ctrl_out;
   wire [31:0] reg_filter_coeff_out;
   wire [31:0] reg_filter_config_out;

   // Registers with loop back
   assign reg_filter_ctrl_in   = reg_filter_ctrl_out;
   assign reg_filter_coeff_in  = reg_filter_coeff_out;
   assign reg_0x10_in          = reg_0x10_out;
   assign reg_0x11_in          = reg_0x11_out;
   // Registers without loop back
   assign reg_0x12_in          = 32'haabbccdd;
   assign reg_0x13_in          = 32'h12345678;

   wire filter_enable;
   wire filter_rst;
   wire filter_stb;
   wire coeff_wren;
   wire coeff_update;
   wire filter_index;
   wire [6:0] coeff_index;

   wire [15:0] coeff;

   (* max_fanout = 128 *) wire filter_enable_sync;
   wire filter_rst_sync;
   wire filter_stb_sync;
   wire coeff_update_sync;
   wire coeff_wren_sync;
   wire filter_index_sync;
   wire [1:0] filter_index_onehot;
   (* mark_debug = "true" *) wire [6:0] coeff_index_sync;

   (* mark_debug = "true" *)  wire [15:0] coeff_sync;
   reg coeff_wren_sync_d;
   wire coeff_wren_sync_posedge;
   wire coeff_wren_sync_posedge_d;

   reg filter_stb_sync_d;
   wire filter_stb_sync_posedge;

   reg [`UL1_SPD_PARALLEL_SAMPLES*`UL1_SPD_DATAWIDTH_BITS-1:0]
      data_in [`UL1_SPD_ANALOG_CHANNELS-1:0];
   wire [`UL1_SPD_PARALLEL_SAMPLES*`UL1_SPD_DATAWIDTH_BITS-1:0]
      data_d [`UL1_SPD_ANALOG_CHANNELS-1:0];

   reg [`UL1_SPD_TIMESTAMP_WIDTH_BITS-1:0] timestamp_in;
   reg [`UL1_SPD_NUM_CH_TRIG_BITS+`UL1_SPD_NUM_TRIG_ADDBITS-1:0]
      ch_trig_in [`UL1_SPD_ANALOG_CHANNELS-1:0];

   wire [`UL1_SPD_TIMESTAMP_WIDTH_BITS-1:0]
      timestamp_out [`UL1_SPD_ANALOG_CHANNELS-1:0];
   wire [`UL1_SPD_NUM_CH_TRIG_BITS+`UL1_SPD_NUM_TRIG_ADDBITS-1:0]
      ch_trig_out [`UL1_SPD_ANALOG_CHANNELS-1:0];

   ul1_regfile #(
      .ADDR_WIDTH(ADDR_WIDTH)
   ) regfile_inst (
      .clk(clk),
      .rst_i(rst_i),
      .addr_i(addr_i),

      .wr_i(wr_i),
      .wr_ack_o(wr_ack_o),
      .wr_data_i(wr_data_i),

      .rd_i(rd_i),
      .rd_ack_o(rd_ack_o),
      .rd_data_o(rd_data_o),

      .reg_0x04_i(reg_filter_ctrl_in),
      .reg_0x05_i(reg_filter_coeff_in),
      .reg_0x06_i(reg_filter_config_in),
      .reg_0x10_i(reg_0x10_in),
      .reg_0x11_i(reg_0x11_in),
      .reg_0x12_i(reg_0x12_in),
      .reg_0x13_i(reg_0x13_in),

      .reg_0x04_o(reg_filter_ctrl_out),
      .reg_0x05_o(reg_filter_coeff_out),
      .reg_0x06_o(reg_filter_config_out),
      .reg_0x10_o(reg_0x10_out),
      .reg_0x11_o(reg_0x11_out),
      .reg_0x12_o(reg_0x12_out),
      .reg_0x13_o(reg_0x13_out)
   );


   always @(posedge s_axis_aclk) begin
      // Extract all parallel samples for each channel
      data_in[0]    <= extract_ch_all(CH_A);
      ch_trig_in[0] <= extract_ch_trig(CH_A);

      timestamp_in  <= extract_timestamp(DONT_CARE);

      if (`UL1_SPD_ANALOG_CHANNELS > 1) begin
         data_in[1]    <= extract_ch_all(CH_B);
         ch_trig_in[1] <= extract_ch_trig(CH_B);
      end
   end

   // User inserting into bus output
   always @(*) begin
      init_bus_output();

      insert_ch_all(data_out[0], CH_A);
      insert_ch_trig_vector(ch_trig_out[0], CH_A);

      insert_timestamp(timestamp_out[0]);

      if (`UL1_SPD_ANALOG_CHANNELS > 1) begin
         insert_ch_all(data_out[1], CH_B);
         insert_ch_trig_vector(ch_trig_out[1], CH_B);
         insert_timestamp(timestamp_out[1]);
      end

      finish_bus_output();
   end

   // Default is to take mlvds outputs from trigger module
   assign mlvds_rx_o = mlvds_rx_o_from_datatrig_i;
   assign mlvds_tx_o = mlvds_tx_o_from_datatrig_i;

   // Register decoding
   // Register 0x04
   assign filter_enable = reg_filter_ctrl_out[0];
   assign filter_rst    = reg_filter_ctrl_out[1];
   assign filter_stb    = reg_filter_ctrl_out[2];
   assign coeff_wren    = reg_filter_ctrl_out[3];
   assign coeff_update  = reg_filter_ctrl_out[4];
   assign filter_index  = reg_filter_ctrl_out[5];
   assign coeff_index   = reg_filter_ctrl_out[14:8];

   // Register 0x05
   assign coeff = reg_filter_coeff_out[15:0];

   // Register 0x06
   assign reg_filter_config_in = ((FILTER_EXISTS & 8'hFF) << 24)
                                 | ((COEFF_WIDTH & 8'hFF) << 16)
                                 | ((COEFF_FRAC_WIDTH & 8'hFF) << 8)
                                 | (NOF_COEFFS & 8'hFF);

   // CDC synchronization
   ul_cdc_sync ul_cdc_sync_filter_enable_inst (
      .clk_i  (s_axis_aclk),
      .data_i (filter_enable),
      .sync_o (filter_enable_sync)
   );
   ul_cdc_sync ul_cdc_sync_filter_rst_inst (
      .clk_i  (s_axis_aclk),
      .data_i (filter_rst),
      .sync_o (filter_rst_sync)
   );
   ul_cdc_sync ul_cdc_sync_filter_stb_inst (
      .clk_i  (s_axis_aclk),
      .data_i (filter_stb),
      .sync_o (filter_stb_sync)
   );
   ul_cdc_sync ul_cdc_sync_coeff_wren_inst (
      .clk_i  (s_axis_aclk),
      .data_i (coeff_wren),
      .sync_o (coeff_wren_sync)
   );
   ul_cdc_sync ul_cdc_sync_coeff_update_inst (
      .clk_i  (s_axis_aclk),
      .data_i (coeff_update),
      .sync_o (coeff_update_sync)
   );
   ul_cdc_sync ul_cdc_sync_filter_index_inst (
      .clk_i  (s_axis_aclk),
      .data_i (filter_index),
      .sync_o (filter_index_sync)
   );

   // Edge detection for bus synchronization etc.
   always @(posedge s_axis_aclk) begin
      coeff_wren_sync_d <= coeff_wren_sync;
      filter_stb_sync_d <= filter_stb_sync;
   end
   assign coeff_wren_sync_posedge = coeff_wren_sync & ~coeff_wren_sync_d;
   assign filter_stb_sync_posedge = filter_stb_sync & ~filter_stb_sync_d;

   // Bus synchronization for filter coefficients
   ul_cdc_sync_bus_ce #(
      .WIDTH (7 + 16)
   ) ul_cdc_sync_bus_ce_filter_inst (
      .clk_i  (s_axis_aclk),
      .ce_i   (coeff_wren_sync_posedge),
      .data_i ({coeff_index,
                coeff}),
      .sync_o ({coeff_index_sync,
                coeff_sync}),
      .ce_o   (coeff_wren_sync_posedge_d)
   );

   // One-hot encoding of the filter index.
   assign filter_index_onehot = {filter_index_sync, ~filter_index_sync};

   wire [`UL1_SPD_PARALLEL_SAMPLES*`UL1_SPD_DATAWIDTH_BITS-1:0]
      data_from_filter [`UL1_SPD_ANALOG_CHANNELS-1:0];
   wire [`UL1_SPD_PARALLEL_SAMPLES*`UL1_SPD_DATAWIDTH_BITS-1:0]
      data_out [`UL1_SPD_ANALOG_CHANNELS-1:0];

`ifdef DISABLE_UL1_FILTER
   generate
      for (ch = 0; ch < `UL1_SPD_ANALOG_CHANNELS; ch = ch + 1) begin
         assign data_out[ch] = data_in[ch];
         assign ch_trig_out[ch] = ch_trig_in[ch];
         assign timestamp_out[ch] = timestamp_in;
      end
   endgenerate
`else
   generate
   for (ch = 0; ch < `UL1_SPD_ANALOG_CHANNELS; ch = ch + 1) begin
      // Local wire and register declarations
      wire [COEFF_WIDTH*NOF_COEFFS-1:0] coeffs;
      wire [COEFF_WIDTH-1:0] my_coeff_mem [NOF_COEFFS-1:0];
      wire [COEFF_WIDTH*NOF_COEFFS-1:0] my_coeffs;
      
      (* max_fanout = 128 *) reg [1:0] rst_internal = 2'b00;
      reg rst    = 1'b0;
      reg enable = 1'b0;
      
            
      assign my_coeff_mem[0] = 'b0000011101010101; 
      assign my_coeff_mem[1] = 'b0000000011010011; 
      assign my_coeff_mem[2] = 'b1111110110100001; 
      assign my_coeff_mem[3] = 'b0000011000111010; 
      assign my_coeff_mem[4] = 'b0000000101010011; 
      assign my_coeff_mem[5] = 'b0000001011000100; 
      assign my_coeff_mem[6] = 'b1111110010111100; 
      assign my_coeff_mem[7] = 'b1111111000000000; 
      assign my_coeff_mem[8] = 'b1111110011100100; 
      assign my_coeff_mem[9] = 'b0000000100001110; 
      assign my_coeff_mem[10] = 'b0000000111010110; 
      assign my_coeff_mem[11] = 'b0000001101010000; 
      assign my_coeff_mem[12] = 'b0000000010110111; 
      assign my_coeff_mem[13] = 'b1111111011101111; 
      assign my_coeff_mem[14] = 'b1111110011001010; 
      assign my_coeff_mem[15] = 'b1111110111011111; 
      assign my_coeff_mem[16] = 'b1111111111010010; 
      assign my_coeff_mem[17] = 'b0000001010010001; 
      assign my_coeff_mem[18] = 'b0000001100000010; 
      assign my_coeff_mem[19] = 'b0000000110100000; 
      assign my_coeff_mem[20] = 'b1111111010101000; 
      assign my_coeff_mem[21] = 'b1111110011011001; 
      assign my_coeff_mem[22] = 'b1111110100011011; 
      assign my_coeff_mem[23] = 'b1111111110110100; 
      assign my_coeff_mem[24] = 'b0000001001110011; 
      assign my_coeff_mem[25] = 'b0000001110010010; 
      assign my_coeff_mem[26] = 'b0000000111111010; 
      assign my_coeff_mem[27] = 'b1111111011110110; 
      assign my_coeff_mem[28] = 'b1111110010011000; 
      assign my_coeff_mem[29] = 'b1111110011000011; 
      assign my_coeff_mem[30] = 'b1111111101000011; 
      assign my_coeff_mem[31] = 'b0000001001011110; 
      assign my_coeff_mem[32] = 'b0000001110110010;
      
     for (k = 0; k < NOF_COEFFS; k = k + 1) begin
            assign my_coeffs[k*COEFF_WIDTH +: COEFF_WIDTH] = my_coeff_mem[k];
     end

      // Sample reset and enable bits on the strobe posedge. Duplicate reset
      // net to ease routing.
      always @(posedge s_axis_aclk) begin
         if (filter_index_onehot[ch] & filter_stb_sync_posedge) begin
            enable <= filter_enable_sync;
            rst    <= filter_rst_sync;
         end
         rst_internal <= {2{~s_axis_aresetn | rst}};
      end

      // Coefficient memory management
      ul_coeff_mem #(
         .COEFF_WIDTH      (COEFF_WIDTH),
         .COEFF_FRAC_WIDTH (COEFF_FRAC_WIDTH),
         .NOF_COEFFS       (NOF_COEFFS)
      ) ul_coeff_mem_inst (
         .clk_i          (s_axis_aclk),
         .rst_i          (rst_internal[0]),

         .coeff_i        (coeff_sync),
         .coeff_index_i  (coeff_index_sync),
         .coeff_update_i (coeff_update_sync & filter_index_onehot[ch]),
         .coeff_wren_i   (coeff_wren_sync_posedge_d & filter_index_onehot[ch]),
         .coeffs_o       (coeffs)
      );

      // Linear phase FIR filter
      ul_linphase_fir #(
         .DATAWIDTH_BITS   (`UL1_SPD_DATAWIDTH_BITS),
         .PARALLEL_SAMPLES (`UL1_SPD_PARALLEL_SAMPLES),
         .COEFF_WIDTH      (COEFF_WIDTH),
         .ORDER            (ORDER),
         .COEFF_FRAC_WIDTH (COEFF_FRAC_WIDTH),
         .SETUP_CHECKER    (SETUP_FIR),
         .PIPELINE_CHECKER (PIPELINE_FIR)
      ) ul_linphase_filter_inst (
         .clk_i        (s_axis_aclk),
         .rst_i        (rst_internal[1]),

         .data_i       (data_in[ch]),
         .data_valid_i (1'b1),
         .coeffs_i     (my_coeffs),

         .data_o       (data_from_filter[ch]),
         .data_valid_o ()
      );

      // Delay line for bus signals, no CE module is required since data is
      // always valid in UL1.
      ul_pipeline #(
         .CLOCK_CYCLES   (BUS_PIPELINE-1),
         .DATAWIDTH_BITS (`UL1_SPD_PARALLEL_SAMPLES*`UL1_SPD_DATAWIDTH_BITS),
         .SHREG          ("NO")
      ) ul_pipeline_data_inst (
         .clk_i (s_axis_aclk),
         .x     ({data_in[ch]}),
         .y     ({data_d[ch]})
      );

      ul_pipeline #(
         .CLOCK_CYCLES   (BUS_PIPELINE-1),
         .DATAWIDTH_BITS (`UL1_SPD_TIMESTAMP_WIDTH_BITS
            +`UL1_SPD_NUM_CH_TRIG_BITS
         +`UL1_SPD_NUM_TRIG_ADDBITS),
         .SHREG          ("NO")
      ) ul_pipeline_bus_signals_inst (
         .clk_i (s_axis_aclk),
         .x     ({timestamp_in, ch_trig_in[ch]}),
         .y     ({timestamp_out[ch], ch_trig_out[ch]})
      );

      assign data_out[ch] = enable ? data_from_filter[ch] : data_d[ch];
   end
   endgenerate
`endif

   // User logic ends

endmodule

`default_nettype wire