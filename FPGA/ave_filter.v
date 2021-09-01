`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/26 09:41:14
// Design Name: 
// Module Name: ave_filter
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


module ave_filter #(
    DATA_WIDTH = 16
)(
    input clk_data,
    input rst,
    input [DATA_WIDTH - 1: 0] data_in,
    input data_in_valid,
    output [DATA_WIDTH - 1: 0] data_out,
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

    // parameters
    localparam AVE_LEN = 256;
    localparam LOG2_AVE_LEN = clog2(AVE_LEN);
    
    // internal signals
    reg [15 + LOG2_AVE_LEN: 0] sum;
    reg [LOG2_AVE_LEN - 1: 0] cnt;
    reg [15: 0] ave;
    reg ave_valid;
    
    always @(posedge clk_data) begin
        if (rst) begin
            sum <= 'd0;
        end
        else if (data_in_valid) begin
            if (cnt == AVE_LEN - 1) begin
                sum <= 'd0;
            end
            else begin
                sum <= sum + data_in;
            end
        end        
    end
    
    always @(posedge clk_data) begin
        if (rst) begin
            cnt <= 'd0;
        end
        else if (data_in_valid) begin
            if (cnt == AVE_LEN - 1) begin
                cnt <= 'd0;
            end
            else begin
                cnt <= cnt + 1;
            end
        end
    end
    
    always @(posedge clk_data) begin
        if (rst) begin
            ave <= 'd0;
        end
        else if (data_in_valid) begin
            if (cnt == AVE_LEN - 1) begin
                ave <= sum >>> LOG2_AVE_LEN;
            end
        end
    end
    
    assign data_out = ave;
    assign data_out_valid = (cnt == AVE_LEN - 1)? data_in_valid: 1'b0;

endmodule
