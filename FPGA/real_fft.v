`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/16 21:25:10
// Design Name: 
// Module Name: real_fft
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


module real_fft #(
    DATA_WIDTH = 16,
    NOF_FFT_POINT = 64
)(
    input clk_data,
    input rst,
    input [DATA_WIDTH * NOF_FFT_POINT * 2 - 1: 0] data_in,
    input data_in_valid,
    output [DATA_WIDTH * NOF_FFT_POINT - 1: 0] data_out_real,
    output [DATA_WIDTH * NOF_FFT_POINT - 1: 0] data_out_imag,
    output data_out_valid
    );
    
    localparam DELAY = 15;
    
    wire signed [DATA_WIDTH - 1: 0] data_in_s [0: NOF_FFT_POINT * 2 - 1];
    wire [DATA_WIDTH * NOF_FFT_POINT - 1: 0] data_odd;
    wire [DATA_WIDTH * NOF_FFT_POINT - 1: 0] data_even;
    
    wire [DATA_WIDTH * NOF_FFT_POINT - 1: 0] fft_out_real;
    wire [DATA_WIDTH * NOF_FFT_POINT - 1: 0] fft_out_imag;
    wire fft_out_valid;
    
    wire signed [DATA_WIDTH - 1: 0] fft_out_real_s [0: NOF_FFT_POINT - 1];
    wire signed [DATA_WIDTH - 1: 0] fft_out_imag_s [0: NOF_FFT_POINT - 1];
    
    wire signed [32: 0] G_A_real [0: NOF_FFT_POINT - 1];
    wire signed [32: 0] G_A_imag [0: NOF_FFT_POINT - 1];
    wire signed [32: 0] G_B_real [0: NOF_FFT_POINT - 1];
    wire signed [32: 0] G_B_imag [0: NOF_FFT_POINT - 1];
    wire signed [33: 0] G_real [0: NOF_FFT_POINT - 1];
    wire signed [33: 0] G_imag [0: NOF_FFT_POINT - 1];       
    
    wire [DATA_WIDTH * 2 - 1: 0] data_to_complex_mult_A [0: NOF_FFT_POINT - 1];
    wire [DATA_WIDTH * 2 - 1: 0] data_to_complex_mult_B [0: NOF_FFT_POINT - 1];
    
    wire [79: 0] complex_mult_out_A [0: NOF_FFT_POINT - 1];
    wire [79: 0] complex_mult_out_B [0: NOF_FFT_POINT - 1];
    
    wire signed [DATA_WIDTH - 1: 0] data_out_real_s [0: NOF_FFT_POINT - 1];
    wire signed [DATA_WIDTH - 1: 0] data_out_imag_s [0: NOF_FFT_POINT - 1];
    
    reg [79: 0] complex_mult_out_A_clked [0: NOF_FFT_POINT - 1];
    reg [79: 0] complex_mult_out_B_clked [0: NOF_FFT_POINT - 1];
    reg data_out_valid_dly [0: DELAY - 1];
    
    integer i;
    genvar m;
    
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
    
    
    function signed [DATA_WIDTH - 1: 0] conj;
        input signed [DATA_WIDTH - 1: 0] value;
        conj = ~value + 1;
    endfunction
    
    function signed [DATA_WIDTH - 1: 0] get_A_real;
        input [clog2(NOF_FFT_POINT) - 1: 0] index;
        case (index)
            0: get_A_real = 'd4096;
            1: get_A_real = 'd3895;
            2: get_A_real = 'd3695;
            3: get_A_real = 'd3495;
            4: get_A_real = 'd3297;
            5: get_A_real = 'd3101;
            6: get_A_real = 'd2907;
            7: get_A_real = 'd2716;
            8: get_A_real = 'd2529;
            9: get_A_real = 'd2345;
            10: get_A_real = 'd2165;
            11: get_A_real = 'd1990;
            12: get_A_real = 'd1820;
            13: get_A_real = 'd1656;
            14: get_A_real = 'd1498;
            15: get_A_real = 'd1345;
            16: get_A_real = 'd1200;
            17: get_A_real = 'd1061;
            18: get_A_real = 'd930;
            19: get_A_real = 'd806;
            20: get_A_real = 'd690;
            21: get_A_real = 'd583;
            22: get_A_real = 'd484;
            23: get_A_real = 'd393;
            24: get_A_real = 'd312;
            25: get_A_real = 'd239;
            26: get_A_real = 'd176;
            27: get_A_real = 'd123;
            28: get_A_real = 'd79;
            29: get_A_real = 'd44;
            30: get_A_real = 'd20;
            31: get_A_real = 'd5;
            32: get_A_real = 'd0;
            33: get_A_real = 'd5;
            34: get_A_real = 'd20;
            35: get_A_real = 'd44;
            36: get_A_real = 'd79;
            37: get_A_real = 'd123;
            38: get_A_real = 'd176;
            39: get_A_real = 'd239;
            40: get_A_real = 'd312;
            41: get_A_real = 'd393;
            42: get_A_real = 'd484;
            43: get_A_real = 'd583;
            44: get_A_real = 'd690;
            45: get_A_real = 'd806;
            46: get_A_real = 'd930;
            47: get_A_real = 'd1061;
            48: get_A_real = 'd1200;
            49: get_A_real = 'd1345;
            50: get_A_real = 'd1498;
            51: get_A_real = 'd1656;
            52: get_A_real = 'd1820;
            53: get_A_real = 'd1990;
            54: get_A_real = 'd2165;
            55: get_A_real = 'd2345;
            56: get_A_real = 'd2529;
            57: get_A_real = 'd2716;
            58: get_A_real = 'd2907;
            59: get_A_real = 'd3101;
            60: get_A_real = 'd3297;
            61: get_A_real = 'd3495;
            62: get_A_real = 'd3695;
            63: get_A_real = 'd3895;
            default: get_A_real = 'd0;
        endcase
    endfunction
    
    function signed [DATA_WIDTH - 1: 0] get_A_imag;
        input [clog2(NOF_FFT_POINT) - 1: 0] index;
        case (index)
            0: get_A_imag = -'d4096;
            1: get_A_imag = -'d4091;
            2: get_A_imag = -'d4076;
            3: get_A_imag = -'d4052;
            4: get_A_imag = -'d4017;
            5: get_A_imag = -'d3973;
            6: get_A_imag = -'d3920;
            7: get_A_imag = -'d3857;
            8: get_A_imag = -'d3784;
            9: get_A_imag = -'d3703;
            10: get_A_imag = -'d3612;
            11: get_A_imag = -'d3513;
            12: get_A_imag = -'d3406;
            13: get_A_imag = -'d3290;
            14: get_A_imag = -'d3166;
            15: get_A_imag = -'d3035;
            16: get_A_imag = -'d2896;
            17: get_A_imag = -'d2751;
            18: get_A_imag = -'d2598;
            19: get_A_imag = -'d2440;
            20: get_A_imag = -'d2276;
            21: get_A_imag = -'d2106;
            22: get_A_imag = -'d1931;
            23: get_A_imag = -'d1751;
            24: get_A_imag = -'d1567;
            25: get_A_imag = -'d1380;
            26: get_A_imag = -'d1189;
            27: get_A_imag = -'d995;
            28: get_A_imag = -'d799;
            29: get_A_imag = -'d601;
            30: get_A_imag = -'d401;
            31: get_A_imag = -'d201;
            32: get_A_imag = 'd0;
            33: get_A_imag = 'd201;
            34: get_A_imag = 'd401;
            35: get_A_imag = 'd601;
            36: get_A_imag = 'd799;
            37: get_A_imag = 'd995;
            38: get_A_imag = 'd1189;
            39: get_A_imag = 'd1380;
            40: get_A_imag = 'd1567;
            41: get_A_imag = 'd1751;
            42: get_A_imag = 'd1931;
            43: get_A_imag = 'd2106;
            44: get_A_imag = 'd2276;
            45: get_A_imag = 'd2440;
            46: get_A_imag = 'd2598;
            47: get_A_imag = 'd2751;
            48: get_A_imag = 'd2896;
            49: get_A_imag = 'd3035;
            50: get_A_imag = 'd3166;
            51: get_A_imag = 'd3290;
            52: get_A_imag = 'd3406;
            53: get_A_imag = 'd3513;
            54: get_A_imag = 'd3612;
            55: get_A_imag = 'd3703;
            56: get_A_imag = 'd3784;
            57: get_A_imag = 'd3857;
            58: get_A_imag = 'd3920;
            59: get_A_imag = 'd3973;
            60: get_A_imag = 'd4017;
            61: get_A_imag = 'd4052;
            62: get_A_imag = 'd4076;
            63: get_A_imag = 'd4091;
            default: get_A_imag = 'd0;
        endcase
    endfunction   
    
    function signed [DATA_WIDTH - 1: 0] get_B_real;
        input [clog2(NOF_FFT_POINT) - 1: 0] index;
        case (index)
            0: get_B_real = 'd4096;
            1: get_B_real = 'd4297;
            2: get_B_real = 'd4497;
            3: get_B_real = 'd4697;
            4: get_B_real = 'd4895;
            5: get_B_real = 'd5091;
            6: get_B_real = 'd5285;
            7: get_B_real = 'd5476;
            8: get_B_real = 'd5663;
            9: get_B_real = 'd5847;
            10: get_B_real = 'd6027;
            11: get_B_real = 'd6202;
            12: get_B_real = 'd6372;
            13: get_B_real = 'd6536;
            14: get_B_real = 'd6694;
            15: get_B_real = 'd6847;
            16: get_B_real = 'd6992;
            17: get_B_real = 'd7131;
            18: get_B_real = 'd7262;
            19: get_B_real = 'd7386;
            20: get_B_real = 'd7502;
            21: get_B_real = 'd7609;
            22: get_B_real = 'd7708;
            23: get_B_real = 'd7799;
            24: get_B_real = 'd7880;
            25: get_B_real = 'd7953;
            26: get_B_real = 'd8016;
            27: get_B_real = 'd8069;
            28: get_B_real = 'd8113;
            29: get_B_real = 'd8148;
            30: get_B_real = 'd8172;
            31: get_B_real = 'd8187;
            32: get_B_real = 'd8192;
            33: get_B_real = 'd8187;
            34: get_B_real = 'd8172;
            35: get_B_real = 'd8148;
            36: get_B_real = 'd8113;
            37: get_B_real = 'd8069;
            38: get_B_real = 'd8016;
            39: get_B_real = 'd7953;
            40: get_B_real = 'd7880;
            41: get_B_real = 'd7799;
            42: get_B_real = 'd7708;
            43: get_B_real = 'd7609;
            44: get_B_real = 'd7502;
            45: get_B_real = 'd7386;
            46: get_B_real = 'd7262;
            47: get_B_real = 'd7131;
            48: get_B_real = 'd6992;
            49: get_B_real = 'd6847;
            50: get_B_real = 'd6694;
            51: get_B_real = 'd6536;
            52: get_B_real = 'd6372;
            53: get_B_real = 'd6202;
            54: get_B_real = 'd6027;
            55: get_B_real = 'd5847;
            56: get_B_real = 'd5663;
            57: get_B_real = 'd5476;
            58: get_B_real = 'd5285;
            59: get_B_real = 'd5091;
            60: get_B_real = 'd4895;
            61: get_B_real = 'd4697;
            62: get_B_real = 'd4497;
            63: get_B_real = 'd4297;
            default: get_B_real = 'd0;
        endcase
    endfunction       
   
   
    function signed [DATA_WIDTH - 1: 0] get_B_imag;
        input [clog2(NOF_FFT_POINT) - 1: 0] index;
        case (index)
            0: get_B_imag = 'd4096;
            1: get_B_imag = 'd4091;
            2: get_B_imag = 'd4076;
            3: get_B_imag = 'd4052;
            4: get_B_imag = 'd4017;
            5: get_B_imag = 'd3973;
            6: get_B_imag = 'd3920;
            7: get_B_imag = 'd3857;
            8: get_B_imag = 'd3784;
            9: get_B_imag = 'd3703;
            10: get_B_imag = 'd3612;
            11: get_B_imag = 'd3513;
            12: get_B_imag = 'd3406;
            13: get_B_imag = 'd3290;
            14: get_B_imag = 'd3166;
            15: get_B_imag = 'd3035;
            16: get_B_imag = 'd2896;
            17: get_B_imag = 'd2751;
            18: get_B_imag = 'd2598;
            19: get_B_imag = 'd2440;
            20: get_B_imag = 'd2276;
            21: get_B_imag = 'd2106;
            22: get_B_imag = 'd1931;
            23: get_B_imag = 'd1751;
            24: get_B_imag = 'd1567;
            25: get_B_imag = 'd1380;
            26: get_B_imag = 'd1189;
            27: get_B_imag = 'd995;
            28: get_B_imag = 'd799;
            29: get_B_imag = 'd601;
            30: get_B_imag = 'd401;
            31: get_B_imag = 'd201;
            32: get_B_imag = 'd0;
            33: get_B_imag = -'d201;
            34: get_B_imag = -'d401;
            35: get_B_imag = -'d601;
            36: get_B_imag = -'d799;
            37: get_B_imag = -'d995;
            38: get_B_imag = -'d1189;
            39: get_B_imag = -'d1380;
            40: get_B_imag = -'d1567;
            41: get_B_imag = -'d1751;
            42: get_B_imag = -'d1931;
            43: get_B_imag = -'d2106;
            44: get_B_imag = -'d2276;
            45: get_B_imag = -'d2440;
            46: get_B_imag = -'d2598;
            47: get_B_imag = -'d2751;
            48: get_B_imag = -'d2896;
            49: get_B_imag = -'d3035;
            50: get_B_imag = -'d3166;
            51: get_B_imag = -'d3290;
            52: get_B_imag = -'d3406;
            53: get_B_imag = -'d3513;
            54: get_B_imag = -'d3612;
            55: get_B_imag = -'d3703;
            56: get_B_imag = -'d3784;
            57: get_B_imag = -'d3857;
            58: get_B_imag = -'d3920;
            59: get_B_imag = -'d3973;
            60: get_B_imag = -'d4017;
            61: get_B_imag = -'d4052;
            62: get_B_imag = -'d4076;
            63: get_B_imag = -'d4091;
            default: get_B_imag = 'd0;
        endcase
    endfunction   
    
    generate
    for (m = 0; m <= NOF_FFT_POINT * 2 -1; m = m + 1) begin
        assign data_in_s[m] = data_in[m * DATA_WIDTH +: DATA_WIDTH];
    end
    
    for (m = 0; m <= NOF_FFT_POINT - 1; m = m + 1) begin
        assign data_even[m * DATA_WIDTH +: DATA_WIDTH] = data_in_s[2 * m];
        assign data_odd[m * DATA_WIDTH +: DATA_WIDTH] = data_in_s[2 * m + 1];
    end
    endgenerate
    
    fft u_fft (
        .clk_data(clk_data),
        .rst(rst),
        .data_in_real(data_even),
        .data_in_imag(data_odd),
        .data_in_valid(data_in_valid),
        .data_out_real(fft_out_real),
        .data_out_imag(fft_out_imag),
        .data_out_valid(fft_out_valid)
    );
   
    generate
    for (m = 0; m <= NOF_FFT_POINT - 1; m = m + 1) begin
        assign fft_out_real_s[m] = fft_out_real[m * DATA_WIDTH +: DATA_WIDTH];
        assign fft_out_imag_s[m] = fft_out_imag[m * DATA_WIDTH +: DATA_WIDTH];
    end
    endgenerate
    

    // complex mult
    generate
    for (m = 0; m <= NOF_FFT_POINT - 1; m = m + 1) begin
        assign data_to_complex_mult_A[m] = {fft_out_imag_s[m], fft_out_real_s[m]};
    end
    
    assign data_to_complex_mult_B[0] = {conj(fft_out_imag_s[0]), fft_out_real_s[0]};
    
    for (m = 1; m <= NOF_FFT_POINT - 1; m = m + 1) begin
        assign data_to_complex_mult_B[m] = {conj(fft_out_imag_s[NOF_FFT_POINT - m]), fft_out_real_s[NOF_FFT_POINT - m]};
    end
    endgenerate
    
    
    generate
    for (m = 0; m <= NOF_FFT_POINT - 1; m = m + 1) begin
    complex_mult u_complex_mult_A (
        .aclk(clk_data),                              // input wire aclk
        .s_axis_a_tvalid(fft_out_valid),        // input wire s_axis_a_tvalid
        .s_axis_a_tdata(data_to_complex_mult_A[m]),          // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(fft_out_valid),        // input wire s_axis_b_tvalid
        .s_axis_b_tdata({get_A_imag(m), get_A_real(m)}),          // input wire [31 : 0] s_axis_b_tdata
        .m_axis_dout_tvalid(),  // output wire m_axis_dout_tvalid
        .m_axis_dout_tdata(complex_mult_out_A[m])    // output wire [79 : 0] m_axis_dout_tdata
    );
    
    
    complex_mult u_complex_mult_B (
        .aclk(clk_data),                              // input wire aclk
        .s_axis_a_tvalid(fft_out_valid),        // input wire s_axis_a_tvalid
        .s_axis_a_tdata(data_to_complex_mult_B[m]),          // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(fft_out_valid),        // input wire s_axis_b_tvalid
        .s_axis_b_tdata({get_B_imag(m), get_B_real(m)}),          // input wire [31 : 0] s_axis_b_tdata
        .m_axis_dout_tvalid(),  // output wire m_axis_dout_tvalid
        .m_axis_dout_tdata(complex_mult_out_B[m])    // output wire [79 : 0] m_axis_dout_tdata
    );
    end
    endgenerate
    
    // clock the output of complex mult (not sure why the output of complex mult doesn't have a clock domain, so we clock it mannually here)
    always @(posedge clk_data) begin
        for (i = 0; i <= NOF_FFT_POINT - 1; i = i + 1) begin
            complex_mult_out_A_clked[i] <= complex_mult_out_A[i];
            complex_mult_out_B_clked[i] <= complex_mult_out_B[i];
        end 
    end
    
    generate
    for (m = 0; m <= NOF_FFT_POINT - 1; m = m + 1) begin
        assign G_A_real[m] = complex_mult_out_A_clked[m][32:0];
        assign G_A_imag[m] = complex_mult_out_A_clked[m][72:40];
        assign G_B_real[m] = complex_mult_out_B_clked[m][32:0];
        assign G_B_imag[m] = complex_mult_out_B_clked[m][72:40];
    end
    endgenerate
    
    generate
    for (m = 0; m <= NOF_FFT_POINT - 1; m = m + 1) begin
        assign G_real[m] = G_A_real[m] + G_B_real[m];
        assign G_imag[m] = G_A_imag[m] + G_B_imag[m];
    end
    endgenerate
    
    generate
    for (m = 0; m <= NOF_FFT_POINT - 1; m = m + 1) begin
        assign data_out_real_s[m] = {G_real[m][33], G_real[m][13 +: 15]};
        assign data_out_imag_s[m] = {G_imag[m][33], G_imag[m][13 +: 15]};
    end
    endgenerate
    
    generate
    for (m = 0; m <= NOF_FFT_POINT - 1; m = m + 1) begin
        assign data_out_real[m * DATA_WIDTH +: DATA_WIDTH] = data_out_real_s[m];
        assign data_out_imag[m * DATA_WIDTH +: DATA_WIDTH] = data_out_imag_s[m];
    end
    endgenerate
    
    always @(posedge clk_data) begin
        data_out_valid_dly[0] <= data_in_valid;
        for (i = 1; i <= DELAY - 1; i = i + 1) begin
            data_out_valid_dly[i] <= data_out_valid_dly[i-1];
        end
    end
    
    assign data_out_valid = data_out_valid_dly[DELAY - 1];
    
endmodule
