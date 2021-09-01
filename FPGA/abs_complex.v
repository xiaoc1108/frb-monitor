`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/20 10:34:22
// Design Name: 
// Module Name: sqrt_approx
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


module abs_complex #(
    DATA_WIDTH = 16
)(
    input clk_data,
    input rst,
    input data_in_valid,
    input [DATA_WIDTH - 1: 0] data_in_real,
    input [DATA_WIDTH - 1: 0] data_in_imag,
    output [DATA_WIDTH - 1: 0] data_out,
    output data_out_valid
    );
    
    reg [DATA_WIDTH - 1: 0] abs_data_in_real;
    reg [DATA_WIDTH - 1: 0] abs_data_in_imag;
    
    reg [DATA_WIDTH - 1: 0] max_abs_real_imag;
    reg [DATA_WIDTH - 1: 0] min_abs_real_imag;
    
    reg [DATA_WIDTH - 1: 0] result;
    
    reg [3: 0] data_in_valid_dly;
    
    // abs
    always @(posedge clk_data) begin
        if (rst) begin
            abs_data_in_real <= 'd0;
        end
        else if (data_in_valid) begin
            if (data_in_real[DATA_WIDTH - 1]) begin
                abs_data_in_real <= ~data_in_real + 1;
            end
            else begin
                abs_data_in_real <= data_in_real;
            end
        end
    end
    
    always @(posedge clk_data) begin
        if (rst) begin
            abs_data_in_imag <= 'd0;
        end
        else if (data_in_valid) begin
            if (data_in_imag[DATA_WIDTH - 1]) begin
                abs_data_in_imag <= ~data_in_imag + 1;
            end
            else begin
                abs_data_in_imag <= data_in_imag;
            end
        end
    end    
    
    // max(abs_data_in_real, abs_data_in_imag) and min(abs_data_in_real, abs_data_in_imag)
    always @(posedge clk_data) begin
        if (rst) begin
            max_abs_real_imag <= 'd0;
            min_abs_real_imag <= 'd0;
        end
        else begin
            if (data_in_valid) begin
                if (abs_data_in_real >= abs_data_in_imag) begin
                    max_abs_real_imag <= abs_data_in_real;
                    min_abs_real_imag <= abs_data_in_imag;
                end
                else begin
                    max_abs_real_imag <= abs_data_in_imag;
                    min_abs_real_imag <= abs_data_in_real;
                end
            end
        end
    end
    
    // get result
    always @(posedge clk_data) begin
        if (rst) begin
            result <= 'd0;
        end
        else if (data_in_valid) begin
            result <= max_abs_real_imag[DATA_WIDTH - 2: 0] + (min_abs_real_imag[DATA_WIDTH - 2: 0] >> 1);
        end
    end
    
    assign data_out = result;
    
    always @(posedge clk_data) begin
        if (rst) begin
            data_in_valid_dly <= 'd0;
        end
        else begin
            data_in_valid_dly <= {data_in_valid_dly[2: 0], data_in_valid};
        end
    end
    
    assign data_out_valid = data_in_valid_dly[3];
    
endmodule