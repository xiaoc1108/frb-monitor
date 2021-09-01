`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/05 17:29:43
// Design Name: 
// Module Name: butterfly
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


module butterfly #(
    DATA_WIDTH = 16
)(
    input clk_data,
    input rst,
    input en,
    input signed [DATA_WIDTH - 1: 0] xp_real,
    input signed [DATA_WIDTH - 1: 0] xp_imag,
    input signed [DATA_WIDTH - 1: 0] xq_real,
    input signed [DATA_WIDTH - 1: 0] xq_imag,
    input signed [DATA_WIDTH - 1: 0] factor_real,
    input signed [DATA_WIDTH - 1: 0] factor_imag,
    output valid,
    output signed [DATA_WIDTH - 1: 0] yp_real,
    output signed [DATA_WIDTH - 1: 0] yp_imag,
    output signed [DATA_WIDTH - 1: 0] yq_real,
    output signed [DATA_WIDTH - 1: 0] yq_imag
    );
    
    localparam DELAY = 8;
    
    reg [11:0] en_r;
    reg signed [DATA_WIDTH - 1: 0] xp_real_r;
    reg signed [DATA_WIDTH - 1: 0] xp_imag_r;
    reg signed [DATA_WIDTH - 1: 0] xq_real_r;
    reg signed [DATA_WIDTH - 1: 0] xq_imag_r;
    reg signed [DATA_WIDTH - 1: 0] fifo_xp_real [0: DELAY - 1];
    reg signed [DATA_WIDTH - 1: 0] fifo_xp_imag [0: DELAY - 1];
    reg signed [DATA_WIDTH * 2: 0] xp_real_d1;
    reg signed [DATA_WIDTH * 2: 0] xp_imag_d1;
    reg signed [DATA_WIDTH * 2: 0] xq_wnr_real;
    reg signed [DATA_WIDTH * 2: 0] xq_wnr_imag;
    reg signed [DATA_WIDTH * 2 + 1: 0] yp_real_r;
    reg signed [DATA_WIDTH * 2 + 1: 0] yp_imag_r;
    reg signed [DATA_WIDTH * 2 + 1: 0] yq_real_r;
    reg signed [DATA_WIDTH * 2 + 1: 0] yq_imag_r;
    
    wire signed [DATA_WIDTH * 2 - 1: 0] xq_wnr_real0;
    wire signed [DATA_WIDTH * 2 - 1: 0] xq_wnr_real1;
    wire signed [DATA_WIDTH * 2 - 1: 0] xq_wnr_imag0;
    wire signed [DATA_WIDTH * 2 - 1: 0] xq_wnr_imag1;
    wire signed [DATA_WIDTH * 2: 0] xp_real_d;
    wire signed [DATA_WIDTH * 2: 0] xp_imag_d;
    
    integer i;
    
    /* main code */
    // input stage
    always @(posedge clk_data) begin
        if (rst) begin
            en_r <= 'd0;
        end
        else begin
            en_r <= {en_r[10:0], en};
        end
    end    
    
    always @(posedge clk_data) begin
        if (rst) begin
            xp_real_r <= 'd0;
            xp_imag_r <= 'd0;
            xq_real_r <= 'd0;
            xq_imag_r <= 'd0;
        end
        else begin
            xp_real_r <= xp_real;
            xp_imag_r <= xp_imag;
            xq_real_r <= xq_real;
            xq_imag_r <= xq_imag;            
        end
    end
    
    // Xm(q) multiply
    // pipeline stage = 8
    mult_butterfly u_mult_butterfly_real0 (
        .CLK(clk_data),
        .A(xq_real_r),
        .B(factor_real),
        .P(xq_wnr_real0)
    );
    
    mult_butterfly u_mult_butterfly_real1 (
        .CLK(clk_data),
        .A(xq_imag_r),
        .B(factor_imag),
        .P(xq_wnr_real1)
    );

    mult_butterfly u_mult_butterfly_imag0 (
        .CLK(clk_data),
        .A(xq_real_r),
        .B(factor_imag),
        .P(xq_wnr_imag0)
    );
    
    mult_butterfly u_mult_butterfly_imag1 (
        .CLK(clk_data),
        .A(xq_imag_r),
        .B(factor_real),
        .P(xq_wnr_imag1)
    );
    
    // Xm(p) delay
    // # delay = multiplier pipeline stage = 8
    always @(posedge clk_data) begin
        if (rst) begin
            for (i = 0; i <= DELAY - 1; i = i + 1) begin
                fifo_xp_real[i] <= 'd0;
                fifo_xp_imag[i] <= 'd0;
            end
        end
        else begin
            fifo_xp_real[0] <= xp_real_r;
            fifo_xp_imag[0] <= xp_imag_r;
            for (i = 1; i <= DELAY - 1; i = i + 1) begin
                fifo_xp_real[i] <= fifo_xp_real[i-1];
                fifo_xp_imag[i] <= fifo_xp_imag[i-1];
            end
        end
    end 
    
    // expand 8192 times as Wnr
    assign xp_real_d = {{5{fifo_xp_real[DELAY - 1][15]}}, fifo_xp_real[DELAY - 1][14:0], 13'b0};
    assign xp_imag_d = {{5{fifo_xp_imag[DELAY - 1][15]}}, fifo_xp_imag[DELAY - 1][14:0], 13'b0};
    
    // get Xm(q) mutiplied results and Xm(p) delay again
    always @(posedge clk_data) begin
        if (rst) begin
            xp_real_d1 <= 'd0;
            xp_imag_d1 <= 'd0;
            xq_wnr_real <= 'd0;
            xq_wnr_imag <= 'd0;
        end
        else if (en_r[9]) begin
            xp_real_d1 <= xp_real_d;
            xp_imag_d1 <= xp_imag_d;
            xq_wnr_real <= xq_wnr_real0 - xq_wnr_real1;
            xq_wnr_imag <= xq_wnr_imag0 + xq_wnr_imag1;
        end
    end
    
    // butterfly results
    always @(posedge clk_data) begin
        if (rst) begin
            yp_real_r <= 'd0;
            yp_imag_r <= 'd0;
            yq_real_r <= 'd0;
            yq_imag_r <= 'd0;
        end
        else if (en_r[10]) begin
            yp_real_r <= xp_real_d1 + xq_wnr_real;
            yp_imag_r <= xp_imag_d1 + xq_wnr_imag;
            yq_real_r <= xp_real_d1 - xq_wnr_real;
            yq_imag_r <= xp_imag_d1 - xq_wnr_imag;
        end
    end
    
    // discard the low 13 bits
    assign yp_real = {yp_real_r[33], yp_real_r[13 +: 15]};
    assign yp_imag = {yp_imag_r[33], yp_imag_r[13 +: 15]};
    assign yq_real = {yq_real_r[33], yq_real_r[13 +: 15]};
    assign yq_imag = {yq_imag_r[33], yq_imag_r[13 +: 15]};
    assign valid = en_r[11];
    
endmodule
