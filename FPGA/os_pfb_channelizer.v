`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/03 11:25:09
// Design Name: 
// Module Name: os_pfb_channelizer
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
module os_pfb_channelizer #(
    NOF_PARALLEL_SAMPLES = 16,
    DATA_WIDTH = 16,
    DATA_BUS_WIDTH = NOF_PARALLEL_SAMPLES * DATA_WIDTH,
    COEFFS_WIDTH = 16,
    NOF_COEFFS = 128,
    NOF_CHANNEL = 64
)(
    input clk_data,
    input rst,
    input [DATA_BUS_WIDTH - 1: 0] data_in,
    input data_in_valid,
    output [DATA_BUS_WIDTH - 1: 0] data_out,
    output data_out_valid
    );
    
    /* local parameters, wires and registers */
    localparam DELAY = 5; // delay the data_to_pfb_valid to generate data_to_csr_valid, DELAY = pipeline stage of polyphase_filter.v
    
    reg [DATA_BUS_WIDTH - 1: 0] data_in_r;
    reg data_in_valid_r;
    reg [DATA_BUS_WIDTH - 1: 0] data_mem [0: NOF_CHANNEL / NOF_PARALLEL_SAMPLES - 1];
    reg [clog2(NOF_CHANNEL / NOF_PARALLEL_SAMPLES / 2) - 1: 0] cnt;
    reg [DATA_BUS_WIDTH - 1: 0] data_to_pfb [0: NOF_CHANNEL / NOF_PARALLEL_SAMPLES - 1];
    reg data_to_pfb_valid;
    reg shift_flag;
    reg signed [DATA_WIDTH - 1: 0] shift_register [0: NOF_CHANNEL - 1];
    reg [DELAY - 1: 0] data_to_pfb_valid_d;
    reg data_to_fft_valid;
    
    wire signed [DATA_WIDTH - 1: 0] data_to_pfb_s [0: NOF_CHANNEL - 1];
    wire signed [DATA_WIDTH - 1: 0] data_to_csr [0: NOF_CHANNEL - 1];
    wire data_to_csr_valid;
    wire [DATA_WIDTH * NOF_CHANNEL - 1: 0] data_to_fft;
    wire [DATA_WIDTH * NOF_CHANNEL - 1: 0] data_out_real_from_fft;
    wire [DATA_WIDTH * NOF_CHANNEL - 1: 0] data_out_imag_from_fft;
    wire data_out_valid_from_fft;
    
    integer i;
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
    
    function signed [COEFFS_WIDTH - 1: 0] get_coeffs;
        input [clog2(NOF_COEFFS) - 1: 0] index;
        case (index)
            0: get_coeffs = -'d1054;
            1: get_coeffs = -'d86;
            2: get_coeffs = -'d89;
            3: get_coeffs = -'d91;
            4: get_coeffs = -'d92;
            5: get_coeffs = -'d93;
            6: get_coeffs = -'d92;
            7: get_coeffs = -'d91;
            8: get_coeffs = -'d90;
            9: get_coeffs = -'d87;
            10: get_coeffs = -'d84;
            11: get_coeffs = -'d79;
            12: get_coeffs = -'d74;
            13: get_coeffs = -'d68;
            14: get_coeffs = -'d61;
            15: get_coeffs = -'d53;
            16: get_coeffs = -'d43;
            17: get_coeffs = -'d32;
            18: get_coeffs = -'d21;
            19: get_coeffs = -'d10;
            20: get_coeffs = 'd5;
            21: get_coeffs = 'd19;
            22: get_coeffs = 'd34;
            23: get_coeffs = 'd51;
            24: get_coeffs = 'd68;
            25: get_coeffs = 'd86;
            26: get_coeffs = 'd105;
            27: get_coeffs = 'd125;
            28: get_coeffs = 'd145;
            29: get_coeffs = 'd167;
            30: get_coeffs = 'd189;
            31: get_coeffs = 'd211;
            32: get_coeffs = 'd235;
            33: get_coeffs = 'd258;
            34: get_coeffs = 'd282;
            35: get_coeffs = 'd307;
            36: get_coeffs = 'd331;
            37: get_coeffs = 'd356;
            38: get_coeffs = 'd381;
            39: get_coeffs = 'd406;
            40: get_coeffs = 'd430;
            41: get_coeffs = 'd455;
            42: get_coeffs = 'd479;
            43: get_coeffs = 'd503;
            44: get_coeffs = 'd527;
            45: get_coeffs = 'd550;
            46: get_coeffs = 'd572;
            47: get_coeffs = 'd594;
            48: get_coeffs = 'd614;
            49: get_coeffs = 'd634;
            50: get_coeffs = 'd653;
            51: get_coeffs = 'd671;
            52: get_coeffs = 'd688;
            53: get_coeffs = 'd704;
            54: get_coeffs = 'd719;
            55: get_coeffs = 'd732;
            56: get_coeffs = 'd744;
            57: get_coeffs = 'd754;
            58: get_coeffs = 'd763;
            59: get_coeffs = 'd771;
            60: get_coeffs = 'd777;
            61: get_coeffs = 'd782;
            62: get_coeffs = 'd785;
            63: get_coeffs = 'd786;
            64: get_coeffs = 'd786;
            65: get_coeffs = 'd785;
            66: get_coeffs = 'd782;
            67: get_coeffs = 'd777;
            68: get_coeffs = 'd771;
            69: get_coeffs = 'd763;
            70: get_coeffs = 'd754;
            71: get_coeffs = 'd744;
            72: get_coeffs = 'd732;
            73: get_coeffs = 'd719;
            74: get_coeffs = 'd704;
            75: get_coeffs = 'd688;
            76: get_coeffs = 'd671;
            77: get_coeffs = 'd653;
            78: get_coeffs = 'd634;
            79: get_coeffs = 'd614;
            80: get_coeffs = 'd594;
            81: get_coeffs = 'd572;
            82: get_coeffs = 'd550;
            83: get_coeffs = 'd527;
            84: get_coeffs = 'd503;
            85: get_coeffs = 'd479;
            86: get_coeffs = 'd455;
            87: get_coeffs = 'd430;
            88: get_coeffs = 'd406;
            89: get_coeffs = 'd381;
            90: get_coeffs = 'd356;
            91: get_coeffs = 'd331;
            92: get_coeffs = 'd307;
            93: get_coeffs = 'd282;
            94: get_coeffs = 'd258;
            95: get_coeffs = 'd235;
            96: get_coeffs = 'd211;
            97: get_coeffs = 'd189;
            98: get_coeffs = 'd167;
            99: get_coeffs = 'd145;
            100: get_coeffs = 'd125;
            101: get_coeffs = 'd105;
            102: get_coeffs = 'd86;
            103: get_coeffs = 'd68;
            104: get_coeffs = 'd51;
            105: get_coeffs = 'd34;
            106: get_coeffs = 'd19;
            107: get_coeffs = 'd5;
            108: get_coeffs = -'d10;
            109: get_coeffs = -'d21;
            110: get_coeffs = -'d32;
            111: get_coeffs = -'d43;
            112: get_coeffs = -'d53;
            113: get_coeffs = -'d61;
            114: get_coeffs = -'d68;
            115: get_coeffs = -'d74;
            116: get_coeffs = -'d79;
            117: get_coeffs = -'d84;
            118: get_coeffs = -'d87;
            119: get_coeffs = -'d90;
            120: get_coeffs = -'d91;
            121: get_coeffs = -'d92;
            122: get_coeffs = -'d93;
            123: get_coeffs = -'d92;
            124: get_coeffs = -'d91;
            125: get_coeffs = -'d89;
            126: get_coeffs = -'d86;
            127: get_coeffs = -'d1054;
            default: get_coeffs = 'd0;
        endcase
    endfunction
    
    /* main code */
    
    // input stage
    always @(posedge clk_data) begin
        data_in_r <= data_in;
        data_in_valid_r <= data_in_valid;
    end
    
    // commutator
    always @(posedge clk_data) begin
        if (rst) begin
            for (i = 0; i <= NOF_CHANNEL / NOF_PARALLEL_SAMPLES - 1; i = i + 1) begin
                data_mem[i] <= 'd0;
            end
        end
        else if (data_in_valid_r) begin
            data_mem[0] <= data_in_r;
            for (i = 1; i <= NOF_CHANNEL / NOF_PARALLEL_SAMPLES - 1; i = i + 1) begin
                data_mem[i] <= data_mem[i-1];
            end        
        end
    end
    
    always @(posedge clk_data) begin
        if (rst) begin
            cnt <= 'd0;
        end
        else if (data_in_valid_r) begin
            cnt <= cnt + 1;
        end
    end
    
    always @(posedge clk_data) begin
        if (rst) begin
            data_to_pfb_valid <= 'd0;
        end
        else if (cnt == NOF_CHANNEL / NOF_PARALLEL_SAMPLES / 2 - 1) begin
            data_to_pfb_valid <= data_in_valid_r;
        end
        else begin
            data_to_pfb_valid <= 'd0;
        end
    end
    
    always @(posedge clk_data) begin
        if (rst) begin
            for (i = 0; i <= NOF_CHANNEL / NOF_PARALLEL_SAMPLES - 1; i = i + 1) begin
                data_to_pfb[i] <= 'd0;
            end
        end
        else begin
            if (data_to_pfb_valid) begin
                for (i = 0; i <= NOF_CHANNEL / NOF_PARALLEL_SAMPLES - 1; i = i + 1) begin
                    data_to_pfb[i] <= data_mem[i];
                end                
            end
        end
    end
    
    // split data for easier handling
    generate
    for (m = 0; m <= NOF_CHANNEL / NOF_PARALLEL_SAMPLES - 1; m = m + 1) begin
        for (n = 0; n <= NOF_PARALLEL_SAMPLES - 1; n = n + 1) begin
            assign data_to_pfb_s[NOF_PARALLEL_SAMPLES * m + n] = data_to_pfb[m][n * DATA_WIDTH +: DATA_WIDTH];
        end
    end
    endgenerate
    
    // polyphase FIR filter bank
    generate
    for (m = 0; m <= NOF_CHANNEL - 1; m = m + 1) begin: polyphase_filter_unit
        polyphase_filter u_polyphase_filter (
            .clk_data(clk_data),
            .rst(rst),
            .data_in(data_to_pfb_s[m]),
            .data_in_valid(data_to_pfb_valid),
            .coeff_a(get_coeffs(m)),
            .coeff_b(get_coeffs(m + NOF_CHANNEL)),
            .data_out(data_to_csr[m])
        );
    end
    endgenerate
    
    always @(posedge clk_data) begin
        data_to_pfb_valid_d <= {data_to_pfb_valid_d[DELAY - 2: 0], data_to_pfb_valid};
    end
    
    assign data_to_csr_valid = data_to_pfb_valid_d[DELAY - 1];
    
    // circular shift
    always @(posedge clk_data) begin
        if (rst) begin
            shift_flag <= 'd0;
            for (i =0; i <= NOF_CHANNEL - 1; i = i + 1) begin
                shift_register[i] <= 'd0;
            end
        end
        else if (data_to_csr_valid) begin
            if (shift_flag == 'd0) begin
                shift_flag <= 'd1;
                for (i =0; i <= NOF_CHANNEL - 1; i = i + 1) begin
                    shift_register[i] <= data_to_csr[i];
                end
            end
            else begin
                shift_flag <= 'd0;
                for (i =0; i <= NOF_CHANNEL/2 - 1; i = i + 1) begin
                    shift_register[i] <= data_to_csr[i + NOF_CHANNEL/2];
                    shift_register[i + NOF_CHANNEL/2] <= data_to_csr[i];
                end
            end
        end
    end
    
    // layout circular shift output in one dimension in order to assign it to FFT module easier
    generate
    for (m = 0; m <= NOF_CHANNEL - 1; m = m + 1) begin
        assign data_to_fft[m * DATA_WIDTH +: DATA_WIDTH] = shift_register[m];
    end
    endgenerate
    
    always @(posedge clk_data) begin
        data_to_fft_valid <= data_to_csr_valid;
    end
   
    // FFT
    fft u_fft (
        .clk_data(clk_data),
        .rst(rst),
        .data_in(data_to_fft),
        .data_in_valid(data_to_fft_valid),
        .data_out_real(data_out_real_from_fft),
        .data_out_imag(data_out_imag_from_fft),
        .data_out_valid(data_out_valid_from_fft)
    );
    
    
endmodule
