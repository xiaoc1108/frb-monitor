`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/05 15:48:41
// Design Name: 
// Module Name: fft
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


module fft #(
    DATA_WIDTH = 16,
    NOF_FFT_POINT = 64,
    DATA_BUS_WIDTH = DATA_WIDTH * NOF_FFT_POINT
)(
    input clk_data,
    input rst,
    input [DATA_BUS_WIDTH - 1: 0] data_in_real,
    input [DATA_BUS_WIDTH - 1: 0] data_in_imag,
    input data_in_valid,
    output [DATA_BUS_WIDTH - 1: 0] data_out_real,
    output [DATA_BUS_WIDTH - 1: 0] data_out_imag,
    output data_out_valid
    );
    
    wire en_connect [0: (clog2(NOF_FFT_POINT) + 1) * NOF_FFT_POINT / 2 - 1];
    wire signed [DATA_WIDTH - 1: 0] xm_real [clog2(NOF_FFT_POINT): 0] [NOF_FFT_POINT - 1: 0];
    wire signed [DATA_WIDTH - 1: 0] xm_imag [clog2(NOF_FFT_POINT): 0] [NOF_FFT_POINT - 1: 0];
    wire signed [DATA_WIDTH - 1: 0] factor_real [clog2(NOF_FFT_POINT) - 1: 0] [NOF_FFT_POINT / 2 - 1: 0];
    wire signed [DATA_WIDTH - 1: 0] factor_imag [clog2(NOF_FFT_POINT) - 1: 0] [NOF_FFT_POINT / 2 - 1: 0];
    
    genvar m;
    genvar n;

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
    
    function signed [DATA_WIDTH - 1: 0] get_wnr_real;
        input [clog2(NOF_FFT_POINT / 2) - 1: 0] index;
        case (index)
            0: get_wnr_real = 'd8192;
            1: get_wnr_real = 'd8153;
            2: get_wnr_real = 'd8035;
            3: get_wnr_real = 'd7839;
            4: get_wnr_real = 'd7568;
            5: get_wnr_real = 'd7225;
            6: get_wnr_real = 'd6811;
            7: get_wnr_real = 'd6333;
            8: get_wnr_real = 'd5793;
            9: get_wnr_real = 'd5197;
            10: get_wnr_real = 'd4551;
            11: get_wnr_real = 'd3862;
            12: get_wnr_real = 'd3135;
            13: get_wnr_real = 'd2378;
            14: get_wnr_real = 'd1598;
            15: get_wnr_real = 'd803;
            16: get_wnr_real = 'd0;
            17: get_wnr_real = -'d803;
            18: get_wnr_real = -'d1598;
            19: get_wnr_real = -'d2378;
            20: get_wnr_real = -'d3135;
            21: get_wnr_real = -'d3862;
            22: get_wnr_real = -'d4551;
            23: get_wnr_real = -'d5197;
            24: get_wnr_real = -'d5793;
            25: get_wnr_real = -'d6333;
            26: get_wnr_real = -'d6811;
            27: get_wnr_real = -'d7225;
            28: get_wnr_real = -'d7568;
            29: get_wnr_real = -'d7839;
            30: get_wnr_real = -'d8035;
            31: get_wnr_real = -'d8153;
            default: get_wnr_real = 'd0;
        endcase
    endfunction
    
    
    function signed [DATA_WIDTH - 1: 0] get_wnr_imag;
        input [clog2(NOF_FFT_POINT / 2) - 1: 0] index;
        case (index)
            0: get_wnr_imag = 'd0;
            1: get_wnr_imag = -'d803;
            2: get_wnr_imag = -'d1598;
            3: get_wnr_imag = -'d2378;
            4: get_wnr_imag = -'d3135;
            5: get_wnr_imag = -'d3862;
            6: get_wnr_imag = -'d4551;
            7: get_wnr_imag = -'d5197;
            8: get_wnr_imag = -'d5793;
            9: get_wnr_imag = -'d6333;
            10: get_wnr_imag = -'d6811;
            11: get_wnr_imag = -'d7225;
            12: get_wnr_imag = -'d7568;
            13: get_wnr_imag = -'d7839;
            14: get_wnr_imag = -'d8035;
            15: get_wnr_imag = -'d8153;
            16: get_wnr_imag = -'d8192;
            17: get_wnr_imag = -'d8153;
            18: get_wnr_imag = -'d8035;
            19: get_wnr_imag = -'d7839;
            20: get_wnr_imag = -'d7568;
            21: get_wnr_imag = -'d7225;
            22: get_wnr_imag = -'d6811;
            23: get_wnr_imag = -'d6333;
            24: get_wnr_imag = -'d5793;
            25: get_wnr_imag = -'d5197;
            26: get_wnr_imag = -'d4551;
            27: get_wnr_imag = -'d3862;
            28: get_wnr_imag = -'d3135;
            29: get_wnr_imag = -'d2378;
            30: get_wnr_imag = -'d1598;
            31: get_wnr_imag = -'d803;
            default: get_wnr_imag = 'd0;
        endcase
    endfunction
    
    
    
    // butterfly unit
    // 64 point fft, stage = 6, # butterfly unit in each stage = fft point / 2 = 32
    generate
    for (m = 0; m <= clog2(NOF_FFT_POINT) - 1; m = m + 1) begin: fft_stage
        for (n = 0; n <= NOF_FFT_POINT / 2 - 1; n = n + 1) begin: butterfly_unit
            butterfly u_butterfly (
                .clk_data(clk_data),
                .rst(rst),
                .en(en_connect[m * NOF_FFT_POINT / 2 + n]),
                .xp_real(xm_real[ m ] [n[m:0] < (1<<m) ?
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + n[m:0] :
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + (n[m:0]-(1<<m))] ),
                .xp_imag(xm_imag[ m ] [n[m:0] < (1<<m) ?
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + n[m:0] :
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + (n[m:0]-(1<<m))] ),
                .xq_real(xm_real[ m ] [(n[m:0] < (1<<m) ?
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + n[m:0] :
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + (n[m:0]-(1<<m))) + (1<<m) ]),  
                .xq_imag(xm_imag[ m ] [(n[m:0] < (1<<m) ?
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + n[m:0] :
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + (n[m:0]-(1<<m))) + (1<<m) ]),
                .factor_real(factor_real[m][n]),
                .factor_imag(factor_imag[m][n]),
                
                .valid(en_connect[ (m+1)* NOF_FFT_POINT / 2 + n ]),
                .yp_real(xm_real[ m+1 ][n[m:0] < (1<<m) ?
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + n[m:0] :
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + (n[m:0]-(1<<m))] ),
                .yp_imag(xm_imag[ m+1 ][(n[m:0]) < (1<<m) ?
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + n[m:0] :
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + (n[m:0]-(1<<m))] ),
                .yq_real(xm_real[ m+1 ][(n[m:0] < (1<<m) ?
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + n[m:0] :
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + (n[m:0]-(1<<m))) + (1<<m) ]),
                .yq_imag(xm_imag[ m+1 ][((n[m:0]) < (1<<m) ?
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + n[m:0] :
                        (n[clog2(NOF_FFT_POINT):m] << (m+1)) + (n[m:0]-(1<<m))) + (1<<m) ])
            );
        end
    end
    endgenerate
    
    // inputs
    generate
    for (m = 0; m <= NOF_FFT_POINT / 2 - 1; m = m + 1) begin
        assign en_connect[m] = data_in_valid;
    end
    endgenerate
   
    assign xm_real[0][0] = data_in_real[0 * 16 +: 16];
    assign xm_real[0][1] = data_in_real[32 * 16 +: 16];
    assign xm_real[0][2] = data_in_real[16 * 16 +: 16];
    assign xm_real[0][3] = data_in_real[48 * 16 +: 16];
    assign xm_real[0][4] = data_in_real[8 * 16 +: 16];
    assign xm_real[0][5] = data_in_real[40 * 16 +: 16];
    assign xm_real[0][6] = data_in_real[24 * 16 +: 16];
    assign xm_real[0][7] = data_in_real[56 * 16 +: 16];
    assign xm_real[0][8] = data_in_real[4 * 16 +: 16];
    assign xm_real[0][9] = data_in_real[36 * 16 +: 16];
    assign xm_real[0][10] = data_in_real[20 * 16 +: 16];
    assign xm_real[0][11] = data_in_real[52 * 16 +: 16];
    assign xm_real[0][12] = data_in_real[12 * 16 +: 16];
    assign xm_real[0][13] = data_in_real[44 * 16 +: 16];
    assign xm_real[0][14] = data_in_real[28 * 16 +: 16];
    assign xm_real[0][15] = data_in_real[60 * 16 +: 16];
    assign xm_real[0][16] = data_in_real[2 * 16 +: 16];
    assign xm_real[0][17] = data_in_real[34 * 16 +: 16];
    assign xm_real[0][18] = data_in_real[18 * 16 +: 16];
    assign xm_real[0][19] = data_in_real[50 * 16 +: 16];
    assign xm_real[0][20] = data_in_real[10 * 16 +: 16];
    assign xm_real[0][21] = data_in_real[42 * 16 +: 16];
    assign xm_real[0][22] = data_in_real[26 * 16 +: 16];
    assign xm_real[0][23] = data_in_real[58 * 16 +: 16];
    assign xm_real[0][24] = data_in_real[6 * 16 +: 16];
    assign xm_real[0][25] = data_in_real[38 * 16 +: 16];
    assign xm_real[0][26] = data_in_real[22 * 16 +: 16];
    assign xm_real[0][27] = data_in_real[54 * 16 +: 16];
    assign xm_real[0][28] = data_in_real[14 * 16 +: 16];
    assign xm_real[0][29] = data_in_real[46 * 16 +: 16];
    assign xm_real[0][30] = data_in_real[30 * 16 +: 16];
    assign xm_real[0][31] = data_in_real[62 * 16 +: 16];
    assign xm_real[0][32] = data_in_real[1 * 16 +: 16];
    assign xm_real[0][33] = data_in_real[33 * 16 +: 16];
    assign xm_real[0][34] = data_in_real[17 * 16 +: 16];
    assign xm_real[0][35] = data_in_real[49 * 16 +: 16];
    assign xm_real[0][36] = data_in_real[9 * 16 +: 16];
    assign xm_real[0][37] = data_in_real[41 * 16 +: 16];
    assign xm_real[0][38] = data_in_real[25 * 16 +: 16];
    assign xm_real[0][39] = data_in_real[57 * 16 +: 16];
    assign xm_real[0][40] = data_in_real[5 * 16 +: 16];
    assign xm_real[0][41] = data_in_real[37 * 16 +: 16];
    assign xm_real[0][42] = data_in_real[21 * 16 +: 16];
    assign xm_real[0][43] = data_in_real[53 * 16 +: 16];
    assign xm_real[0][44] = data_in_real[13 * 16 +: 16];
    assign xm_real[0][45] = data_in_real[45 * 16 +: 16];
    assign xm_real[0][46] = data_in_real[29 * 16 +: 16];
    assign xm_real[0][47] = data_in_real[61 * 16 +: 16];
    assign xm_real[0][48] = data_in_real[3 * 16 +: 16];
    assign xm_real[0][49] = data_in_real[35 * 16 +: 16];
    assign xm_real[0][50] = data_in_real[19 * 16 +: 16];
    assign xm_real[0][51] = data_in_real[51 * 16 +: 16];
    assign xm_real[0][52] = data_in_real[11 * 16 +: 16];
    assign xm_real[0][53] = data_in_real[43 * 16 +: 16];
    assign xm_real[0][54] = data_in_real[27 * 16 +: 16];
    assign xm_real[0][55] = data_in_real[59 * 16 +: 16];
    assign xm_real[0][56] = data_in_real[7 * 16 +: 16];
    assign xm_real[0][57] = data_in_real[39 * 16 +: 16];
    assign xm_real[0][58] = data_in_real[23 * 16 +: 16];
    assign xm_real[0][59] = data_in_real[55 * 16 +: 16];
    assign xm_real[0][60] = data_in_real[15 * 16 +: 16];
    assign xm_real[0][61] = data_in_real[47 * 16 +: 16];
    assign xm_real[0][62] = data_in_real[31 * 16 +: 16];
    assign xm_real[0][63] = data_in_real[63 * 16 +: 16];

    assign xm_imag[0][0] = data_in_imag[0 * 16 +: 16];
    assign xm_imag[0][1] = data_in_imag[32 * 16 +: 16];
    assign xm_imag[0][2] = data_in_imag[16 * 16 +: 16];
    assign xm_imag[0][3] = data_in_imag[48 * 16 +: 16];
    assign xm_imag[0][4] = data_in_imag[8 * 16 +: 16];
    assign xm_imag[0][5] = data_in_imag[40 * 16 +: 16];
    assign xm_imag[0][6] = data_in_imag[24 * 16 +: 16];
    assign xm_imag[0][7] = data_in_imag[56 * 16 +: 16];
    assign xm_imag[0][8] = data_in_imag[4 * 16 +: 16];
    assign xm_imag[0][9] = data_in_imag[36 * 16 +: 16];
    assign xm_imag[0][10] = data_in_imag[20 * 16 +: 16];
    assign xm_imag[0][11] = data_in_imag[52 * 16 +: 16];
    assign xm_imag[0][12] = data_in_imag[12 * 16 +: 16];
    assign xm_imag[0][13] = data_in_imag[44 * 16 +: 16];
    assign xm_imag[0][14] = data_in_imag[28 * 16 +: 16];
    assign xm_imag[0][15] = data_in_imag[60 * 16 +: 16];
    assign xm_imag[0][16] = data_in_imag[2 * 16 +: 16];
    assign xm_imag[0][17] = data_in_imag[34 * 16 +: 16];
    assign xm_imag[0][18] = data_in_imag[18 * 16 +: 16];
    assign xm_imag[0][19] = data_in_imag[50 * 16 +: 16];
    assign xm_imag[0][20] = data_in_imag[10 * 16 +: 16];
    assign xm_imag[0][21] = data_in_imag[42 * 16 +: 16];
    assign xm_imag[0][22] = data_in_imag[26 * 16 +: 16];
    assign xm_imag[0][23] = data_in_imag[58 * 16 +: 16];
    assign xm_imag[0][24] = data_in_imag[6 * 16 +: 16];
    assign xm_imag[0][25] = data_in_imag[38 * 16 +: 16];
    assign xm_imag[0][26] = data_in_imag[22 * 16 +: 16];
    assign xm_imag[0][27] = data_in_imag[54 * 16 +: 16];
    assign xm_imag[0][28] = data_in_imag[14 * 16 +: 16];
    assign xm_imag[0][29] = data_in_imag[46 * 16 +: 16];
    assign xm_imag[0][30] = data_in_imag[30 * 16 +: 16];
    assign xm_imag[0][31] = data_in_imag[62 * 16 +: 16];
    assign xm_imag[0][32] = data_in_imag[1 * 16 +: 16];
    assign xm_imag[0][33] = data_in_imag[33 * 16 +: 16];
    assign xm_imag[0][34] = data_in_imag[17 * 16 +: 16];
    assign xm_imag[0][35] = data_in_imag[49 * 16 +: 16];
    assign xm_imag[0][36] = data_in_imag[9 * 16 +: 16];
    assign xm_imag[0][37] = data_in_imag[41 * 16 +: 16];
    assign xm_imag[0][38] = data_in_imag[25 * 16 +: 16];
    assign xm_imag[0][39] = data_in_imag[57 * 16 +: 16];
    assign xm_imag[0][40] = data_in_imag[5 * 16 +: 16];
    assign xm_imag[0][41] = data_in_imag[37 * 16 +: 16];
    assign xm_imag[0][42] = data_in_imag[21 * 16 +: 16];
    assign xm_imag[0][43] = data_in_imag[53 * 16 +: 16];
    assign xm_imag[0][44] = data_in_imag[13 * 16 +: 16];
    assign xm_imag[0][45] = data_in_imag[45 * 16 +: 16];
    assign xm_imag[0][46] = data_in_imag[29 * 16 +: 16];
    assign xm_imag[0][47] = data_in_imag[61 * 16 +: 16];
    assign xm_imag[0][48] = data_in_imag[3 * 16 +: 16];
    assign xm_imag[0][49] = data_in_imag[35 * 16 +: 16];
    assign xm_imag[0][50] = data_in_imag[19 * 16 +: 16];
    assign xm_imag[0][51] = data_in_imag[51 * 16 +: 16];
    assign xm_imag[0][52] = data_in_imag[11 * 16 +: 16];
    assign xm_imag[0][53] = data_in_imag[43 * 16 +: 16];
    assign xm_imag[0][54] = data_in_imag[27 * 16 +: 16];
    assign xm_imag[0][55] = data_in_imag[59 * 16 +: 16];
    assign xm_imag[0][56] = data_in_imag[7 * 16 +: 16];
    assign xm_imag[0][57] = data_in_imag[39 * 16 +: 16];
    assign xm_imag[0][58] = data_in_imag[23 * 16 +: 16];
    assign xm_imag[0][59] = data_in_imag[55 * 16 +: 16];
    assign xm_imag[0][60] = data_in_imag[15 * 16 +: 16];
    assign xm_imag[0][61] = data_in_imag[47 * 16 +: 16];
    assign xm_imag[0][62] = data_in_imag[31 * 16 +: 16];
    assign xm_imag[0][63] = data_in_imag[63 * 16 +: 16];


    
    // wnr
    generate
    // stage1 W0
    for (m = 0; m <= NOF_FFT_POINT / 2 - 1; m = m + 1) begin
        assign factor_real[0][m] = get_wnr_real(0);
        assign factor_imag[0][m] = get_wnr_imag(0);
    end
    
    // stage2 W0, W16
    for (m = 0; m <= NOF_FFT_POINT / 4 - 1; m = m + 1) begin
        assign factor_real[1][2 * m] = get_wnr_real(0);
        assign factor_real[1][2 * m + 1] = get_wnr_real(16);
        
        assign factor_imag[1][2 * m] = get_wnr_imag(0);
        assign factor_imag[1][2 * m + 1] = get_wnr_imag(16);
    end
    
    // stage3 W0, W8, W16, W24
    for (m = 0; m <= NOF_FFT_POINT / 8 - 1; m = m + 1) begin
        assign factor_real[2][4 * m] = get_wnr_real(0);
        assign factor_real[2][4 * m + 1] = get_wnr_real(8);
        assign factor_real[2][4 * m + 2] = get_wnr_real(16);
        assign factor_real[2][4 * m + 3] = get_wnr_real(24);
        
        assign factor_imag[2][4 * m] = get_wnr_imag(0);
        assign factor_imag[2][4 * m + 1] = get_wnr_imag(8);
        assign factor_imag[2][4 * m + 2] = get_wnr_imag(16);
        assign factor_imag[2][4 * m + 3] = get_wnr_imag(24);
    end
    
    // stage4 W0, W4, W8, W12, W16, W20, W24, W28
    for (m = 0; m <= NOF_FFT_POINT / 16 - 1; m = m + 1) begin
        assign factor_real[3][8 * m] = get_wnr_real(0);
        assign factor_real[3][8 * m + 1] = get_wnr_real(4);
        assign factor_real[3][8 * m + 2] = get_wnr_real(8);
        assign factor_real[3][8 * m + 3] = get_wnr_real(12);
        assign factor_real[3][8 * m + 4] = get_wnr_real(16);
        assign factor_real[3][8 * m + 5] = get_wnr_real(20);
        assign factor_real[3][8 * m + 6] = get_wnr_real(24);
        assign factor_real[3][8 * m + 7] = get_wnr_real(28);
        
        assign factor_imag[3][8 * m] = get_wnr_imag(0);
        assign factor_imag[3][8 * m + 1] = get_wnr_imag(4);
        assign factor_imag[3][8 * m + 2] = get_wnr_imag(8);
        assign factor_imag[3][8 * m + 3] = get_wnr_imag(12);
        assign factor_imag[3][8 * m + 4] = get_wnr_imag(16);
        assign factor_imag[3][8 * m + 5] = get_wnr_imag(20);
        assign factor_imag[3][8 * m + 6] = get_wnr_imag(24);
        assign factor_imag[3][8 * m + 7] = get_wnr_imag(28);
    end    
    
    // stage5 W0, W2, W4, W6, W8, W10, W12, W14, W16, W18, W20, W22, W24, W26, W28, W30
    for (m = 0; m <= NOF_FFT_POINT / 32 - 1; m = m + 1) begin
        assign factor_real[4][16 * m] = get_wnr_real(0);
        assign factor_real[4][16 * m + 1] = get_wnr_real(2);
        assign factor_real[4][16 * m + 2] = get_wnr_real(4);
        assign factor_real[4][16 * m + 3] = get_wnr_real(6);
        assign factor_real[4][16 * m + 4] = get_wnr_real(8);
        assign factor_real[4][16 * m + 5] = get_wnr_real(10);
        assign factor_real[4][16 * m + 6] = get_wnr_real(12);
        assign factor_real[4][16 * m + 7] = get_wnr_real(14);
        assign factor_real[4][16 * m + 8] = get_wnr_real(16);
        assign factor_real[4][16 * m + 9] = get_wnr_real(18);
        assign factor_real[4][16 * m + 10] = get_wnr_real(20);
        assign factor_real[4][16 * m + 11] = get_wnr_real(22);
        assign factor_real[4][16 * m + 12] = get_wnr_real(24);
        assign factor_real[4][16 * m + 13] = get_wnr_real(26);
        assign factor_real[4][16 * m + 14] = get_wnr_real(28);
        assign factor_real[4][16 * m + 15] = get_wnr_real(30);
        
        assign factor_imag[4][16 * m] = get_wnr_imag(0);
        assign factor_imag[4][16 * m + 1] = get_wnr_imag(2);
        assign factor_imag[4][16 * m + 2] = get_wnr_imag(4);
        assign factor_imag[4][16 * m + 3] = get_wnr_imag(6);
        assign factor_imag[4][16 * m + 4] = get_wnr_imag(8);
        assign factor_imag[4][16 * m + 5] = get_wnr_imag(10);
        assign factor_imag[4][16 * m + 6] = get_wnr_imag(12);
        assign factor_imag[4][16 * m + 7] = get_wnr_imag(14);
        assign factor_imag[4][16 * m + 8] = get_wnr_imag(16);
        assign factor_imag[4][16 * m + 9] = get_wnr_imag(18);
        assign factor_imag[4][16 * m + 10] = get_wnr_imag(20);
        assign factor_imag[4][16 * m + 11] = get_wnr_imag(22);
        assign factor_imag[4][16 * m + 12] = get_wnr_imag(24);
        assign factor_imag[4][16 * m + 13] = get_wnr_imag(26);
        assign factor_imag[4][16 * m + 14] = get_wnr_imag(28);
        assign factor_imag[4][16 * m + 15] = get_wnr_imag(30);
    end
    
    // stage6 W0~W31
    for (m = 0; m <= NOF_FFT_POINT / 2 - 1; m = m + 1) begin
        assign factor_real[5][m] = get_wnr_real(m);
        assign factor_imag[5][m] = get_wnr_imag(m);
    end
    endgenerate
    
    // outputs
    assign data_out_valid = en_connect[192];
    
    generate
    for (m = 0; m <= NOF_FFT_POINT - 1; m = m + 1) begin
        assign data_out_real[m * 16 +: 16] = xm_real[6][m];
        assign data_out_imag[m * 16 +: 16] = xm_imag[6][m];
    end
    endgenerate
   
endmodule
