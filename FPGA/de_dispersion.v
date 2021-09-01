`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/20 13:56:04
// Design Name: 
// Module Name: Dedispersion
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module de_dispersion #(
    DATA_WIDTH = 16,
    CMD_WIDTH = 32,
    NOF_CHANNEL = 128
)
(
    input clk_data,
    input clk_reg,
    input rst,
    input [DATA_WIDTH * NOF_CHANNEL / 2 - 1: 0] data_in,
    input data_in_valid,
    input [CMD_WIDTH * NOF_CHANNEL / 2 - 1: 0] cmd_ch_dly,

    output [DATA_WIDTH * NOF_CHANNEL / 2 - 1: 0] data_out,
    output data_out_valid
    );
    

    /* functions */
    // log2, it would be better to wirte in a separate file
    function integer clog2;
        input integer value;
              integer temp;
        begin
            temp = value - 1;
            for (clog2 = 0; temp > 0; clog2 = clog2 + 1) begin
                temp = temp >> 1;
            end
        end
    endfunction
    
    reg [CMD_WIDTH * NOF_CHANNEL / 2 - 1: 0] cmd_ch_dly_r;
    reg [CMD_WIDTH * NOF_CHANNEL / 2 - 1: 0] cmd_ch_dly_r1;
    reg [CMD_WIDTH * NOF_CHANNEL / 2 - 1: 0] cmd_ch_dly_r2;
    
    wire [CMD_WIDTH - 1: 0] nof_delay [0: NOF_CHANNEL/2 - 1];
    wire [DATA_WIDTH - 1: 0] data_in_s [0: NOF_CHANNEL/2 - 1];
    wire [DATA_WIDTH - 1: 0] data_out_s [0: NOF_CHANNEL/2 - 1];
    
    integer i;
    genvar m;
    
    // since the cmd does not change every clock,we can use two filp flops to sync the cmd from clk_reg to clk_data
    // two flip flops method always used in single bit cross time domain, so here a better illusration would be
    // delay the cmd signal for several cycles to make sure the cmd is stable
    
    // buffer the cmd to local
    always @(posedge clk_reg) begin
        if (rst) begin
            cmd_ch_dly_r <= 'd0;
        end
        else begin
            cmd_ch_dly_r <= cmd_ch_dly;
        end
    end
    
    // sync to clk_data
    always @(posedge clk_data) begin
        if (rst) begin
            cmd_ch_dly_r1 <= 'd0;
            cmd_ch_dly_r2 <= 'd0;
        end
        else begin
            cmd_ch_dly_r1 <= cmd_ch_dly_r;
            cmd_ch_dly_r2 <= cmd_ch_dly_r1;
        end
    end
    
    // split the data for easier handling
    generate
    for (m = 0; m <= NOF_CHANNEL/2 - 1; m = m + 1) begin
        assign nof_delay[m] = cmd_ch_dly_r2[m * CMD_WIDTH +: CMD_WIDTH];
        assign data_in_s[m] = data_in[m * DATA_WIDTH +: DATA_WIDTH];
    end
    endgenerate
    
    //
    generate
    for (m = 0; m <= NOF_CHANNEL/2 - 1; m = m + 1) begin: channel_delay
        channel_delay u_channel_delay (
            .clk_data(clk_data),
            .rst(rst),
            .nof_delay(nof_delay[m]),
            .data_in(data_in_s[m]),
            .data_in_valid(data_in_valid),
            .data_out(data_out_s[m])
        );
    end
    endgenerate
    
    generate
    for (m = 0; m <= NOF_CHANNEL/2 - 1; m = m + 1) begin
        assign data_out[m * DATA_WIDTH +: DATA_WIDTH] = data_out_s[m];
    end
    endgenerate
    
    assign data_out_valid = data_in_valid;
    
endmodule
