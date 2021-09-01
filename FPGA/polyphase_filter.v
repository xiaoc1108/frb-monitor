`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/04 16:24:06
// Design Name: 
// Module Name: polyphase_filter
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


module polyphase_filter #(
    DATA_WIDTH = 16,
    COEFF_WIDTH = 16,
    NOF_COEFFS_PER_FILTER = 4
)(
    input clk_data,
    input rst,
    input signed [DATA_WIDTH - 1: 0] data_in,
    input data_in_valid,
    input signed [COEFF_WIDTH - 1: 0] coeff_a,
    input signed [COEFF_WIDTH - 1: 0] coeff_b,
    input signed [COEFF_WIDTH - 1: 0] coeff_c,
    input signed [COEFF_WIDTH - 1: 0] coeff_d,
    output signed [DATA_WIDTH - 1: 0] data_out
    );
    
    reg signed [DATA_WIDTH - 1: 0] data_in_r;
    reg data_in_valid_r;
    reg signed [DATA_WIDTH - 1: 0] data_mem_a [0: NOF_COEFFS_PER_FILTER - 1];
    reg signed [DATA_WIDTH - 1: 0] data_mem_b [0: NOF_COEFFS_PER_FILTER - 1];
    reg flag;
    reg signed [DATA_WIDTH - 1: 0] data_to_mult [0: NOF_COEFFS_PER_FILTER - 1];
    reg signed [DATA_WIDTH * 2: 0] data_add_s0 [0: NOF_COEFFS_PER_FILTER - 1];
    reg signed [DATA_WIDTH * 2 + 1: 0] data_add_s1;
    
    wire signed [DATA_WIDTH - 1: 0] coeffs_to_mult [0: NOF_COEFFS_PER_FILTER - 1];
    wire signed [DATA_WIDTH * 2 - 1: 0] data_out_from_mult [0: NOF_COEFFS_PER_FILTER - 1];
    
    integer i;
    genvar m;
    
    // input stage
    always @(posedge clk_data) begin
        data_in_r <= data_in;
        data_in_valid_r <= data_in_valid;
    end
    
    assign coeffs_to_mult[0] = coeff_a;
    assign coeffs_to_mult[1] = coeff_b;
    assign coeffs_to_mult[2] = coeff_c;
    assign coeffs_to_mult[3] = coeff_d;
    
    // filtering
    always @(posedge clk_data) begin
        if (rst) begin
            flag <= 'd0;
            for (i = 0; i <= NOF_COEFFS_PER_FILTER - 1; i = i + 1) begin
                data_mem_a[i] <= 'd0;
                data_mem_b[i] <= 'd0;
            end
        end
        else if (data_in_valid_r) begin
            if (flag == 'd0) begin
                flag <= 'd1;
                data_mem_a[0] <= data_in_r;
                for (i = 1; i <= NOF_COEFFS_PER_FILTER - 1; i = i + 1) begin
                    data_mem_a[i] <= data_mem_a[i-1];
                end
            end
            else begin
                flag <= 'd0;
                data_mem_b[0] <= data_in_r;
                for (i = 1; i <= NOF_COEFFS_PER_FILTER - 1; i = i + 1) begin
                    data_mem_b[i] <= data_mem_b[i-1];
                end            
            end
        end
    end
    
    always @(posedge clk_data) begin
        if (rst) begin
            for (i = 0; i <= NOF_COEFFS_PER_FILTER - 1; i = i + 1) begin
                data_to_mult[i] <= 'd0;
            end            
        end
        else if (data_in_valid_r) begin
            if (flag == 'd0) begin
                for (i = 0; i <= NOF_COEFFS_PER_FILTER - 1; i = i + 1) begin
                    data_to_mult[i] <= data_mem_a[i];
                end                     
            end
            else begin
                for (i = 0; i <= NOF_COEFFS_PER_FILTER - 1; i = i + 1) begin
                    data_to_mult[i] <= data_mem_b[i];
                end                
            end
        end
    end
    
    generate
    for (m = 0; m <= NOF_COEFFS_PER_FILTER - 1; m = m + 1) begin: mult_unit
        mult_fir u_mult_fir (
            .CLK(clk_data),
            .A(data_to_mult[m]),
            .B(coeffs_to_mult[m]),
            .P(data_out_from_mult[m])
        );
    end
    endgenerate
    
    always @(posedge clk_data) begin
        if (rst) begin
            for (i = 0; i <= NOF_COEFFS_PER_FILTER - 1; i = i + 1) begin
                data_add_s0[i] <= 'd0;
            end
        end
        else if (data_in_valid_r) begin
            for (i = 0; i <= NOF_COEFFS_PER_FILTER / 2 - 1; i = i + 1) begin
                data_add_s0[i] <= data_out_from_mult[i * 2] + data_out_from_mult[i * 2 + 1];
            end
        end
    end
    
    always @(posedge clk_data) begin
        if (rst) begin
            data_add_s1 <= 'd0;
        end
        else if (data_in_valid_r) begin
            data_add_s1 <= data_add_s0[0] + data_add_s0[1];
        end
    end
    
    
    // discard the low 15 bits to eliminate the effcet of expanding the coeffes by a factor of 2^15
    assign data_out = {data_add_s1[33], data_add_s1[29: 15]};
    
    
endmodule
