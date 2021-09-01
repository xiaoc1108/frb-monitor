`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/26 09:36:53
// Design Name: 
// Module Name: ave_filterbank
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


module ave_filterbank #(
    DATA_WIDTH = 16,
    NOF_CHANNEL = 128
)(
    input clk_data,
    input rst,
    input [DATA_WIDTH * NOF_CHANNEL / 2 - 1: 0] data_in,
    input data_in_valid,
    output [DATA_WIDTH * NOF_CHANNEL / 2 - 1: 0] data_out,
    output data_out_valid
    );
    
    wire [DATA_WIDTH - 1: 0] data_in_s [0: NOF_CHANNEL / 2 - 1];
    wire [DATA_WIDTH - 1: 0] data_out_s [0: NOF_CHANNEL / 2 - 1];
    wire data_out_valid_w [0: NOF_CHANNEL / 2 - 1];
    genvar m;
    
    
    generate
    for (m = 0; m <= NOF_CHANNEL / 2 - 1; m = m + 1) begin
        assign data_in_s[m] = data_in[m * DATA_WIDTH +: DATA_WIDTH];
    end
    endgenerate
    
    generate
    for (m = 0; m <= NOF_CHANNEL / 2 - 1; m = m + 1) begin: ave_filter_unit
        ave_filter u_ave_filter (
            .clk_data(clk_data),
            .rst(rst),
            .data_in(data_in_s[m]),
            .data_in_valid(data_in_valid),
            .data_out(data_out_s[m]),
            .data_out_valid(data_out_valid_w[m])
        );
    end
    endgenerate
    
    generate
    for (m = 0; m <= NOF_CHANNEL / 2 - 1; m = m + 1) begin
        assign data_out[m * DATA_WIDTH +: DATA_WIDTH] = data_out_s[m];
    end
    endgenerate    
    
    assign data_out_valid = data_out_valid_w[0];
    
endmodule