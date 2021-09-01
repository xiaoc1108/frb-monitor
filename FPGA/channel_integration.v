`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/21 14:36:10
// Design Name: 
// Module Name: channel_integration
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


module channel_integration # (
    DATA_WIDTH = 16,
    NOF_CHANNEL = 128    
)
(
    input clk_data,
    input rst,
    input [DATA_WIDTH * NOF_CHANNEL / 2 - 1: 0] data_in,
    input data_in_valid,
    
    output [DATA_WIDTH + 5: 0] data_out,
    output data_out_valid
    );
    
    integer i;
    
    reg data_in_valid_r;
    reg [DATA_WIDTH - 1: 0] data_in_r [0: NOF_CHANNEL / 2 - 1];
    reg [DATA_WIDTH: 0] add_s0 [0: NOF_CHANNEL / 4 - 1];
    reg [DATA_WIDTH + 1: 0] add_s1 [0: NOF_CHANNEL / 8 - 1];
    reg [DATA_WIDTH + 2: 0] add_s2 [0: NOF_CHANNEL / 16 - 1];
    reg [DATA_WIDTH + 3: 0] add_s3 [0: NOF_CHANNEL / 32 - 1];
    reg [DATA_WIDTH + 4: 0] add_s4 [0: NOF_CHANNEL / 64 - 1];
    reg [DATA_WIDTH + 5: 0] add_s5;
    
    always @(posedge clk_data) begin
        if (rst) begin
            data_in_valid_r <= 'd0;
        end
        else begin
            data_in_valid_r <= data_in_valid;
        end
    end
    
    always @(posedge clk_data) begin
        if (rst) begin
            for (i = 0; i <= NOF_CHANNEL / 2 - 1; i = i + 1) begin
                data_in_r[i] <= 'd0;
            end
        end
        else if (data_in_valid) begin
            for (i = 0; i <= NOF_CHANNEL / 2 - 1; i = i + 1) begin
                data_in_r[i] <= data_in[i * DATA_WIDTH +: DATA_WIDTH];
            end
        end
    end
    
    // stage0
    always @(posedge clk_data) begin
        if (rst) begin
            for (i = 0; i <= NOF_CHANNEL / 4 - 1; i = i + 1) begin
                add_s0[i] <= 'd0;
            end            
        end
        else if (data_in_valid_r) begin
            for (i = 0; i <= NOF_CHANNEL / 4 - 1; i = i + 1) begin
                add_s0[i] <= data_in_r[2 * i] + data_in_r[2 * i + 1];
            end           
        end
    end    
    
    // stage1
    always @(posedge clk_data) begin
        if (rst) begin
            for (i = 0; i <= NOF_CHANNEL / 8 - 1; i = i + 1) begin
                add_s1[i] <= 'd0;
            end
        end
        else if (data_in_valid_r) begin
            for (i = 0; i <= NOF_CHANNEL / 8 - 1; i = i + 1) begin
                add_s1[i] <= add_s0[2 * i] + add_s0[2 * i + 1];
            end     
        end    
    end    
    
    // stage2
    always @(posedge clk_data) begin
        if (rst) begin
            for (i = 0; i <= NOF_CHANNEL / 16 - 1; i = i + 1) begin
                add_s2[i] <= 'd0;
            end
        end
        else if (data_in_valid_r) begin
            for (i = 0; i <= NOF_CHANNEL / 16 - 1; i = i + 1) begin
                add_s2[i] <= add_s1[2 * i] + add_s1[2 * i + 1];
            end
        end
    end
    
    // stage3
    always @(posedge clk_data) begin
        if (rst) begin
            for (i = 0; i <= NOF_CHANNEL / 32 - 1; i = i + 1) begin
                add_s3[i] <= 'd0;
            end
        end
        else if (data_in_valid_r) begin
            for (i = 0; i <= NOF_CHANNEL / 32 - 1; i = i + 1) begin
                add_s3[i] <= add_s2[2 * i] + add_s2[2 * i + 1];
            end
        end
    end
    
    // stage4
    always @(posedge clk_data) begin
        if (rst) begin
            for (i = 0; i <= NOF_CHANNEL / 64 - 1; i = i + 1) begin
                add_s4[i] <= 'd0;
            end
        end
        else if (data_in_valid_r) begin
            for (i = 0; i <= NOF_CHANNEL / 64 - 1; i = i + 1) begin
                add_s4[i] <= add_s3[2 * i] + add_s3[2 * i + 1];
            end
        end
    end    
    // stage5
    always @(posedge clk_data) begin
        if (rst) begin
            add_s5 <= 'd0;
        end
        else if (data_in_valid_r) begin
            add_s5 <= add_s4[0] + add_s4[1];
        end
    end        
    
    assign data_out = add_s5;
    assign data_out_valid = data_in_valid_r;
    
endmodule