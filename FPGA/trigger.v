`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/21 15:26:54
// Design Name: 
// Module Name: simple_trigger
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


module trigger #(
    DATA_WIDTH = 22,
    CMD_WIDTH = 32    
)(
    input clk_data,
    input clk_reg,
    input rst,
    input [DATA_WIDTH - 1: 0] data_in,
    input data_in_valid,
    input [CMD_WIDTH - 1: 0] cmd_threshold,
    output trigger
    );
    
    reg [DATA_WIDTH - 1: 0] r_cmd_threshold;
    reg [DATA_WIDTH - 1: 0] r1_cmd_threshold;
    reg [DATA_WIDTH - 1: 0] r2_cmd_threshold;
    (* mark_debug = "true" *) reg [DATA_WIDTH - 1: 0] threshold;
    reg trigger_flag1;
    reg trigger_flag2;
    
    always @(posedge clk_reg) begin
        if (rst) begin
            r_cmd_threshold <= 'd0;
        end
        else begin
            r_cmd_threshold <= cmd_threshold;
        end
    end
    
    
    always @(posedge clk_data) begin
        if (rst) begin
            r1_cmd_threshold <= 'd0;
            r2_cmd_threshold <= 'd0;
            threshold <= 'd0;
        end
        else begin
            r1_cmd_threshold <= r_cmd_threshold;
            r2_cmd_threshold <= r1_cmd_threshold;
            threshold <= r2_cmd_threshold;
        end    
    
    end
    
    // generate the trigger
    
    always @(posedge clk_data) begin
        if (rst) begin
            trigger_flag1 <= 'd0;
        end  
        else if (data_in_valid) begin
            trigger_flag1 <= (data_in >= threshold);
        end
    end
    
    always @(posedge clk_data) begin
        if (rst) begin
            trigger_flag2 <= 'd0;
        end
        else if (data_in_valid) begin
            trigger_flag2 <= trigger_flag1;
        end
    end
    
    assign trigger = trigger_flag1 &~ trigger_flag2;    
    
endmodule
