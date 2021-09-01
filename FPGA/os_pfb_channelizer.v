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
    NOF_COEFFS = 512,
    NOF_CHANNEL = 128
)(
    input clk_data,
    input rst,
    input [DATA_BUS_WIDTH - 1: 0] data_in,
    input data_in_valid,
    output [DATA_WIDTH * NOF_CHANNEL / 2 - 1: 0] data_out,
    output data_out_valid
    );
    
    /* local parameters, wires and registers */
    localparam DELAY = 2; // delay the input valid signal to generate a valid signal for polyphase_filter output
    
    reg [DATA_BUS_WIDTH - 1: 0] data_in_r;
    reg data_in_valid_r;
    reg [DATA_BUS_WIDTH - 1: 0] data_mem [0: NOF_CHANNEL / NOF_PARALLEL_SAMPLES - 1];
    reg [clog2(NOF_CHANNEL / NOF_PARALLEL_SAMPLES / 2) - 1: 0] cnt;
    reg [DATA_BUS_WIDTH - 1: 0] data_to_pfb [0: NOF_CHANNEL / NOF_PARALLEL_SAMPLES - 1];
    reg data_to_pfb_valid;
    reg data_to_pfb_valid_d;
    reg shift_flag;
    reg signed [DATA_WIDTH - 1: 0] shift_register [0: NOF_CHANNEL - 1];
    reg [DELAY - 1: 0] data_to_pfb_valid_dd;
    reg data_to_fft_valid;
    reg [3: 0] data_to_abs_valid_d;
    
    wire signed [DATA_WIDTH - 1: 0] data_to_pfb_s [0: NOF_CHANNEL - 1];
    wire signed [DATA_WIDTH - 1: 0] data_to_csr [0: NOF_CHANNEL - 1];
    wire data_to_csr_valid;
    wire [DATA_WIDTH * NOF_CHANNEL - 1: 0] data_to_fft;
    wire [DATA_WIDTH * NOF_CHANNEL - 1: 0] data_out_real_from_fft;
    wire [DATA_WIDTH * NOF_CHANNEL - 1: 0] data_out_imag_from_fft;
    wire data_out_valid_from_fft;
    
    wire [DATA_WIDTH * NOF_CHANNEL / 2 - 1: 0] data_to_abs_real;
    wire [DATA_WIDTH * NOF_CHANNEL / 2 - 1: 0] data_to_abs_imag;
    wire data_to_abs_valid;
    wire signed [15:0] data_to_abs_real_s [0: NOF_CHANNEL / 2 - 1];
    wire signed [15:0] data_to_abs_imag_s [0: NOF_CHANNEL / 2 - 1];
    
    wire [15:0] data_out_s [0: NOF_CHANNEL / 2 - 1];
    
    
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
            0: get_coeffs = 'd179;
            1: get_coeffs = -'d7;
            2: get_coeffs = -'d7;
            3: get_coeffs = -'d7;
            4: get_coeffs = -'d7;
            5: get_coeffs = -'d7;
            6: get_coeffs = -'d7;
            7: get_coeffs = -'d7;
            8: get_coeffs = -'d7;
            9: get_coeffs = -'d7;
            10: get_coeffs = -'d7;
            11: get_coeffs = -'d7;
            12: get_coeffs = -'d7;
            13: get_coeffs = -'d7;
            14: get_coeffs = -'d8;
            15: get_coeffs = -'d8;
            16: get_coeffs = -'d8;
            17: get_coeffs = -'d8;
            18: get_coeffs = -'d8;
            19: get_coeffs = -'d9;
            20: get_coeffs = -'d9;
            21: get_coeffs = -'d9;
            22: get_coeffs = -'d9;
            23: get_coeffs = -'d10;
            24: get_coeffs = -'d10;
            25: get_coeffs = -'d10;
            26: get_coeffs = -'d11;
            27: get_coeffs = -'d11;
            28: get_coeffs = -'d11;
            29: get_coeffs = -'d12;
            30: get_coeffs = -'d12;
            31: get_coeffs = -'d13;
            32: get_coeffs = -'d13;
            33: get_coeffs = -'d13;
            34: get_coeffs = -'d14;
            35: get_coeffs = -'d14;
            36: get_coeffs = -'d15;
            37: get_coeffs = -'d15;
            38: get_coeffs = -'d15;
            39: get_coeffs = -'d16;
            40: get_coeffs = -'d16;
            41: get_coeffs = -'d17;
            42: get_coeffs = -'d17;
            43: get_coeffs = -'d18;
            44: get_coeffs = -'d18;
            45: get_coeffs = -'d18;
            46: get_coeffs = -'d19;
            47: get_coeffs = -'d19;
            48: get_coeffs = -'d20;
            49: get_coeffs = -'d20;
            50: get_coeffs = -'d21;
            51: get_coeffs = -'d21;
            52: get_coeffs = -'d21;
            53: get_coeffs = -'d22;
            54: get_coeffs = -'d22;
            55: get_coeffs = -'d23;
            56: get_coeffs = -'d23;
            57: get_coeffs = -'d24;
            58: get_coeffs = -'d24;
            59: get_coeffs = -'d24;
            60: get_coeffs = -'d25;
            61: get_coeffs = -'d25;
            62: get_coeffs = -'d25;
            63: get_coeffs = -'d26;
            64: get_coeffs = -'d26;
            65: get_coeffs = -'d26;
            66: get_coeffs = -'d27;
            67: get_coeffs = -'d27;
            68: get_coeffs = -'d27;
            69: get_coeffs = -'d28;
            70: get_coeffs = -'d28;
            71: get_coeffs = -'d28;
            72: get_coeffs = -'d28;
            73: get_coeffs = -'d29;
            74: get_coeffs = -'d29;
            75: get_coeffs = -'d29;
            76: get_coeffs = -'d29;
            77: get_coeffs = -'d29;
            78: get_coeffs = -'d29;
            79: get_coeffs = -'d30;
            80: get_coeffs = -'d30;
            81: get_coeffs = -'d30;
            82: get_coeffs = -'d30;
            83: get_coeffs = -'d30;
            84: get_coeffs = -'d30;
            85: get_coeffs = -'d30;
            86: get_coeffs = -'d30;
            87: get_coeffs = -'d30;
            88: get_coeffs = -'d29;
            89: get_coeffs = -'d29;
            90: get_coeffs = -'d29;
            91: get_coeffs = -'d29;
            92: get_coeffs = -'d29;
            93: get_coeffs = -'d28;
            94: get_coeffs = -'d28;
            95: get_coeffs = -'d28;
            96: get_coeffs = -'d28;
            97: get_coeffs = -'d27;
            98: get_coeffs = -'d27;
            99: get_coeffs = -'d26;
            100: get_coeffs = -'d26;
            101: get_coeffs = -'d25;
            102: get_coeffs = -'d25;
            103: get_coeffs = -'d24;
            104: get_coeffs = -'d24;
            105: get_coeffs = -'d23;
            106: get_coeffs = -'d23;
            107: get_coeffs = -'d22;
            108: get_coeffs = -'d21;
            109: get_coeffs = -'d20;
            110: get_coeffs = -'d20;
            111: get_coeffs = -'d19;
            112: get_coeffs = -'d18;
            113: get_coeffs = -'d17;
            114: get_coeffs = -'d16;
            115: get_coeffs = -'d15;
            116: get_coeffs = -'d14;
            117: get_coeffs = -'d13;
            118: get_coeffs = -'d12;
            119: get_coeffs = -'d11;
            120: get_coeffs = -'d10;
            121: get_coeffs = -'d8;
            122: get_coeffs = -'d7;
            123: get_coeffs = -'d6;
            124: get_coeffs = -'d5;
            125: get_coeffs = -'d3;
            126: get_coeffs = -'d2;
            127: get_coeffs = 'd0;
            128: get_coeffs = 'd1;
            129: get_coeffs = 'd3;
            130: get_coeffs = 'd4;
            131: get_coeffs = 'd6;
            132: get_coeffs = 'd7;
            133: get_coeffs = 'd9;
            134: get_coeffs = 'd11;
            135: get_coeffs = 'd12;
            136: get_coeffs = 'd14;
            137: get_coeffs = 'd16;
            138: get_coeffs = 'd18;
            139: get_coeffs = 'd20;
            140: get_coeffs = 'd22;
            141: get_coeffs = 'd23;
            142: get_coeffs = 'd25;
            143: get_coeffs = 'd27;
            144: get_coeffs = 'd29;
            145: get_coeffs = 'd32;
            146: get_coeffs = 'd34;
            147: get_coeffs = 'd36;
            148: get_coeffs = 'd38;
            149: get_coeffs = 'd40;
            150: get_coeffs = 'd42;
            151: get_coeffs = 'd45;
            152: get_coeffs = 'd47;
            153: get_coeffs = 'd49;
            154: get_coeffs = 'd52;
            155: get_coeffs = 'd54;
            156: get_coeffs = 'd56;
            157: get_coeffs = 'd59;
            158: get_coeffs = 'd61;
            159: get_coeffs = 'd64;
            160: get_coeffs = 'd66;
            161: get_coeffs = 'd69;
            162: get_coeffs = 'd71;
            163: get_coeffs = 'd74;
            164: get_coeffs = 'd76;
            165: get_coeffs = 'd79;
            166: get_coeffs = 'd82;
            167: get_coeffs = 'd84;
            168: get_coeffs = 'd87;
            169: get_coeffs = 'd90;
            170: get_coeffs = 'd92;
            171: get_coeffs = 'd95;
            172: get_coeffs = 'd98;
            173: get_coeffs = 'd100;
            174: get_coeffs = 'd103;
            175: get_coeffs = 'd106;
            176: get_coeffs = 'd109;
            177: get_coeffs = 'd111;
            178: get_coeffs = 'd114;
            179: get_coeffs = 'd117;
            180: get_coeffs = 'd120;
            181: get_coeffs = 'd122;
            182: get_coeffs = 'd125;
            183: get_coeffs = 'd128;
            184: get_coeffs = 'd131;
            185: get_coeffs = 'd133;
            186: get_coeffs = 'd136;
            187: get_coeffs = 'd139;
            188: get_coeffs = 'd142;
            189: get_coeffs = 'd144;
            190: get_coeffs = 'd147;
            191: get_coeffs = 'd150;
            192: get_coeffs = 'd152;
            193: get_coeffs = 'd155;
            194: get_coeffs = 'd158;
            195: get_coeffs = 'd161;
            196: get_coeffs = 'd163;
            197: get_coeffs = 'd166;
            198: get_coeffs = 'd168;
            199: get_coeffs = 'd171;
            200: get_coeffs = 'd174;
            201: get_coeffs = 'd176;
            202: get_coeffs = 'd179;
            203: get_coeffs = 'd181;
            204: get_coeffs = 'd184;
            205: get_coeffs = 'd186;
            206: get_coeffs = 'd189;
            207: get_coeffs = 'd191;
            208: get_coeffs = 'd194;
            209: get_coeffs = 'd196;
            210: get_coeffs = 'd198;
            211: get_coeffs = 'd200;
            212: get_coeffs = 'd203;
            213: get_coeffs = 'd205;
            214: get_coeffs = 'd207;
            215: get_coeffs = 'd209;
            216: get_coeffs = 'd211;
            217: get_coeffs = 'd213;
            218: get_coeffs = 'd216;
            219: get_coeffs = 'd218;
            220: get_coeffs = 'd219;
            221: get_coeffs = 'd221;
            222: get_coeffs = 'd223;
            223: get_coeffs = 'd225;
            224: get_coeffs = 'd227;
            225: get_coeffs = 'd229;
            226: get_coeffs = 'd230;
            227: get_coeffs = 'd232;
            228: get_coeffs = 'd233;
            229: get_coeffs = 'd235;
            230: get_coeffs = 'd236;
            231: get_coeffs = 'd238;
            232: get_coeffs = 'd239;
            233: get_coeffs = 'd241;
            234: get_coeffs = 'd242;
            235: get_coeffs = 'd243;
            236: get_coeffs = 'd244;
            237: get_coeffs = 'd245;
            238: get_coeffs = 'd246;
            239: get_coeffs = 'd247;
            240: get_coeffs = 'd248;
            241: get_coeffs = 'd249;
            242: get_coeffs = 'd250;
            243: get_coeffs = 'd251;
            244: get_coeffs = 'd252;
            245: get_coeffs = 'd252;
            246: get_coeffs = 'd253;
            247: get_coeffs = 'd253;
            248: get_coeffs = 'd254;
            249: get_coeffs = 'd254;
            250: get_coeffs = 'd255;
            251: get_coeffs = 'd255;
            252: get_coeffs = 'd255;
            253: get_coeffs = 'd255;
            254: get_coeffs = 'd256;
            255: get_coeffs = 'd256;
            256: get_coeffs = 'd256;
            257: get_coeffs = 'd256;
            258: get_coeffs = 'd255;
            259: get_coeffs = 'd255;
            260: get_coeffs = 'd255;
            261: get_coeffs = 'd255;
            262: get_coeffs = 'd254;
            263: get_coeffs = 'd254;
            264: get_coeffs = 'd253;
            265: get_coeffs = 'd253;
            266: get_coeffs = 'd252;
            267: get_coeffs = 'd252;
            268: get_coeffs = 'd251;
            269: get_coeffs = 'd250;
            270: get_coeffs = 'd249;
            271: get_coeffs = 'd248;
            272: get_coeffs = 'd247;
            273: get_coeffs = 'd246;
            274: get_coeffs = 'd245;
            275: get_coeffs = 'd244;
            276: get_coeffs = 'd243;
            277: get_coeffs = 'd242;
            278: get_coeffs = 'd241;
            279: get_coeffs = 'd239;
            280: get_coeffs = 'd238;
            281: get_coeffs = 'd236;
            282: get_coeffs = 'd235;
            283: get_coeffs = 'd233;
            284: get_coeffs = 'd232;
            285: get_coeffs = 'd230;
            286: get_coeffs = 'd229;
            287: get_coeffs = 'd227;
            288: get_coeffs = 'd225;
            289: get_coeffs = 'd223;
            290: get_coeffs = 'd221;
            291: get_coeffs = 'd219;
            292: get_coeffs = 'd218;
            293: get_coeffs = 'd216;
            294: get_coeffs = 'd213;
            295: get_coeffs = 'd211;
            296: get_coeffs = 'd209;
            297: get_coeffs = 'd207;
            298: get_coeffs = 'd205;
            299: get_coeffs = 'd203;
            300: get_coeffs = 'd200;
            301: get_coeffs = 'd198;
            302: get_coeffs = 'd196;
            303: get_coeffs = 'd194;
            304: get_coeffs = 'd191;
            305: get_coeffs = 'd189;
            306: get_coeffs = 'd186;
            307: get_coeffs = 'd184;
            308: get_coeffs = 'd181;
            309: get_coeffs = 'd179;
            310: get_coeffs = 'd176;
            311: get_coeffs = 'd174;
            312: get_coeffs = 'd171;
            313: get_coeffs = 'd168;
            314: get_coeffs = 'd166;
            315: get_coeffs = 'd163;
            316: get_coeffs = 'd161;
            317: get_coeffs = 'd158;
            318: get_coeffs = 'd155;
            319: get_coeffs = 'd152;
            320: get_coeffs = 'd150;
            321: get_coeffs = 'd147;
            322: get_coeffs = 'd144;
            323: get_coeffs = 'd142;
            324: get_coeffs = 'd139;
            325: get_coeffs = 'd136;
            326: get_coeffs = 'd133;
            327: get_coeffs = 'd131;
            328: get_coeffs = 'd128;
            329: get_coeffs = 'd125;
            330: get_coeffs = 'd122;
            331: get_coeffs = 'd120;
            332: get_coeffs = 'd117;
            333: get_coeffs = 'd114;
            334: get_coeffs = 'd111;
            335: get_coeffs = 'd109;
            336: get_coeffs = 'd106;
            337: get_coeffs = 'd103;
            338: get_coeffs = 'd100;
            339: get_coeffs = 'd98;
            340: get_coeffs = 'd95;
            341: get_coeffs = 'd92;
            342: get_coeffs = 'd90;
            343: get_coeffs = 'd87;
            344: get_coeffs = 'd84;
            345: get_coeffs = 'd82;
            346: get_coeffs = 'd79;
            347: get_coeffs = 'd76;
            348: get_coeffs = 'd74;
            349: get_coeffs = 'd71;
            350: get_coeffs = 'd69;
            351: get_coeffs = 'd66;
            352: get_coeffs = 'd64;
            353: get_coeffs = 'd61;
            354: get_coeffs = 'd59;
            355: get_coeffs = 'd56;
            356: get_coeffs = 'd54;
            357: get_coeffs = 'd52;
            358: get_coeffs = 'd49;
            359: get_coeffs = 'd47;
            360: get_coeffs = 'd45;
            361: get_coeffs = 'd42;
            362: get_coeffs = 'd40;
            363: get_coeffs = 'd38;
            364: get_coeffs = 'd36;
            365: get_coeffs = 'd34;
            366: get_coeffs = 'd32;
            367: get_coeffs = 'd29;
            368: get_coeffs = 'd27;
            369: get_coeffs = 'd25;
            370: get_coeffs = 'd23;
            371: get_coeffs = 'd22;
            372: get_coeffs = 'd20;
            373: get_coeffs = 'd18;
            374: get_coeffs = 'd16;
            375: get_coeffs = 'd14;
            376: get_coeffs = 'd12;
            377: get_coeffs = 'd11;
            378: get_coeffs = 'd9;
            379: get_coeffs = 'd7;
            380: get_coeffs = 'd6;
            381: get_coeffs = 'd4;
            382: get_coeffs = 'd3;
            383: get_coeffs = 'd1;
            384: get_coeffs = 'd0;
            385: get_coeffs = -'d2;
            386: get_coeffs = -'d3;
            387: get_coeffs = -'d5;
            388: get_coeffs = -'d6;
            389: get_coeffs = -'d7;
            390: get_coeffs = -'d8;
            391: get_coeffs = -'d10;
            392: get_coeffs = -'d11;
            393: get_coeffs = -'d12;
            394: get_coeffs = -'d13;
            395: get_coeffs = -'d14;
            396: get_coeffs = -'d15;
            397: get_coeffs = -'d16;
            398: get_coeffs = -'d17;
            399: get_coeffs = -'d18;
            400: get_coeffs = -'d19;
            401: get_coeffs = -'d20;
            402: get_coeffs = -'d20;
            403: get_coeffs = -'d21;
            404: get_coeffs = -'d22;
            405: get_coeffs = -'d23;
            406: get_coeffs = -'d23;
            407: get_coeffs = -'d24;
            408: get_coeffs = -'d24;
            409: get_coeffs = -'d25;
            410: get_coeffs = -'d25;
            411: get_coeffs = -'d26;
            412: get_coeffs = -'d26;
            413: get_coeffs = -'d27;
            414: get_coeffs = -'d27;
            415: get_coeffs = -'d28;
            416: get_coeffs = -'d28;
            417: get_coeffs = -'d28;
            418: get_coeffs = -'d28;
            419: get_coeffs = -'d29;
            420: get_coeffs = -'d29;
            421: get_coeffs = -'d29;
            422: get_coeffs = -'d29;
            423: get_coeffs = -'d29;
            424: get_coeffs = -'d30;
            425: get_coeffs = -'d30;
            426: get_coeffs = -'d30;
            427: get_coeffs = -'d30;
            428: get_coeffs = -'d30;
            429: get_coeffs = -'d30;
            430: get_coeffs = -'d30;
            431: get_coeffs = -'d30;
            432: get_coeffs = -'d30;
            433: get_coeffs = -'d29;
            434: get_coeffs = -'d29;
            435: get_coeffs = -'d29;
            436: get_coeffs = -'d29;
            437: get_coeffs = -'d29;
            438: get_coeffs = -'d29;
            439: get_coeffs = -'d28;
            440: get_coeffs = -'d28;
            441: get_coeffs = -'d28;
            442: get_coeffs = -'d28;
            443: get_coeffs = -'d27;
            444: get_coeffs = -'d27;
            445: get_coeffs = -'d27;
            446: get_coeffs = -'d26;
            447: get_coeffs = -'d26;
            448: get_coeffs = -'d26;
            449: get_coeffs = -'d25;
            450: get_coeffs = -'d25;
            451: get_coeffs = -'d25;
            452: get_coeffs = -'d24;
            453: get_coeffs = -'d24;
            454: get_coeffs = -'d24;
            455: get_coeffs = -'d23;
            456: get_coeffs = -'d23;
            457: get_coeffs = -'d22;
            458: get_coeffs = -'d22;
            459: get_coeffs = -'d21;
            460: get_coeffs = -'d21;
            461: get_coeffs = -'d21;
            462: get_coeffs = -'d20;
            463: get_coeffs = -'d20;
            464: get_coeffs = -'d19;
            465: get_coeffs = -'d19;
            466: get_coeffs = -'d18;
            467: get_coeffs = -'d18;
            468: get_coeffs = -'d18;
            469: get_coeffs = -'d17;
            470: get_coeffs = -'d17;
            471: get_coeffs = -'d16;
            472: get_coeffs = -'d16;
            473: get_coeffs = -'d15;
            474: get_coeffs = -'d15;
            475: get_coeffs = -'d15;
            476: get_coeffs = -'d14;
            477: get_coeffs = -'d14;
            478: get_coeffs = -'d13;
            479: get_coeffs = -'d13;
            480: get_coeffs = -'d13;
            481: get_coeffs = -'d12;
            482: get_coeffs = -'d12;
            483: get_coeffs = -'d11;
            484: get_coeffs = -'d11;
            485: get_coeffs = -'d11;
            486: get_coeffs = -'d10;
            487: get_coeffs = -'d10;
            488: get_coeffs = -'d10;
            489: get_coeffs = -'d9;
            490: get_coeffs = -'d9;
            491: get_coeffs = -'d9;
            492: get_coeffs = -'d9;
            493: get_coeffs = -'d8;
            494: get_coeffs = -'d8;
            495: get_coeffs = -'d8;
            496: get_coeffs = -'d8;
            497: get_coeffs = -'d8;
            498: get_coeffs = -'d7;
            499: get_coeffs = -'d7;
            500: get_coeffs = -'d7;
            501: get_coeffs = -'d7;
            502: get_coeffs = -'d7;
            503: get_coeffs = -'d7;
            504: get_coeffs = -'d7;
            505: get_coeffs = -'d7;
            506: get_coeffs = -'d7;
            507: get_coeffs = -'d7;
            508: get_coeffs = -'d7;
            509: get_coeffs = -'d7;
            510: get_coeffs = -'d7;
            511: get_coeffs = 'd179;
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
    
    // sync data_to_pfb_valid and data to pfb
    always @(posedge clk_data) begin
        if (rst) begin
             data_to_pfb_valid_d <= 'd0;       
        end
        else if (data_to_pfb_valid) begin
            data_to_pfb_valid_d <= 'd1;
        end
        else begin
            data_to_pfb_valid_d <= 'd0;
        end
    end
    
    // split data for easier handling
    generate
    for (m = 0; m <= NOF_CHANNEL / NOF_PARALLEL_SAMPLES - 1; m = m + 1) begin
        for (n = 0; n <= NOF_PARALLEL_SAMPLES - 1; n = n + 1) begin
            assign data_to_pfb_s[NOF_PARALLEL_SAMPLES * m + n] = data_to_pfb[m][(15 - n) * DATA_WIDTH +: DATA_WIDTH];
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
            .data_in_valid(data_to_pfb_valid_d),
            .coeff_a(get_coeffs(m + NOF_CHANNEL * 0)),
            .coeff_b(get_coeffs(m + NOF_CHANNEL * 1)),
            .coeff_c(get_coeffs(m + NOF_CHANNEL * 2)),
            .coeff_d(get_coeffs(m + NOF_CHANNEL * 3)),
            .data_out(data_to_csr[m])
        );
    end
    endgenerate
    
    always @(posedge clk_data) begin
        data_to_pfb_valid_dd <= {data_to_pfb_valid_dd[DELAY - 2: 0], data_to_pfb_valid_d};
    end
    
    assign data_to_csr_valid = data_to_pfb_valid_dd[DELAY - 1];
    
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
    real_fft u_real_fft (
        .clk_data(clk_data),
        .rst(rst),
        .data_in(data_to_fft),
        .data_in_valid(data_to_fft_valid),
        .data_out_real(data_to_abs_real),
        .data_out_imag(data_to_abs_imag),
        .data_out_valid(data_to_abs_valid)
    );
 
    generate
    for (m = 0; m <= NOF_CHANNEL / 2 - 1; m = m + 1) begin
        assign data_to_abs_real_s[m] = data_to_abs_real[m * DATA_WIDTH +: DATA_WIDTH];
        assign data_to_abs_imag_s[m] = data_to_abs_imag[m * DATA_WIDTH +: DATA_WIDTH];
    end
    endgenerate    
    
    generate
    for (m = 0; m <= NOF_CHANNEL / 2 - 1; m = m + 1) begin: abs_unit
        abs_complex u_abs_complex (
            .clk_data(clk_data),
            .rst(rst),
            .data_in_valid(data_to_abs_valid),
            .data_in_real(data_to_abs_real_s[m]),
            .data_in_imag(data_to_abs_imag_s[m]),
            .data_out(data_out_s[m]),
            .data_out_valid()
        );
    end
    endgenerate
    
    generate
    for (m = 0; m <= NOF_CHANNEL / 2 - 1; m = m + 1) begin
        assign data_out[m * DATA_WIDTH +: DATA_WIDTH] = data_out_s[m];
    end
    endgenerate    
    
    always @(posedge clk_data) begin
        if (rst) begin
            data_to_abs_valid_d <= 'd0;
        end
        else begin
            data_to_abs_valid_d <= data_to_abs_valid;
        end
    end
    
    assign data_out_valid = data_to_abs_valid_d;
    
endmodule