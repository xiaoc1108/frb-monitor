`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/22/2021 08:58:00 PM
// Design Name: 
// Module Name: snapshot
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


module snapshot # (
    parameter   DATA_BUS_WIDTH      =   1024     ,
    parameter   SNAPSHOT_DEPTH      =   1024    ,
    parameter   LOG2_SNAPSHOT_DEPTH =   10
)
(
    input                               clk_data        ,
    input                               clk_reg         ,
    input                               rst            ,
    input                               trigger         ,
    input   [DATA_BUS_WIDTH - 1: 0]     data_in         ,
    input                               data_in_valid   ,
    input                               rd_fifo_en      ,
    (* mark_debug = "true" *) output  [31: 0]   data_out
    );
    
    
    // state machine
    (* mark_debug = "true" *) reg [3:0]   state                    ;
    localparam  state_idle          = 'd0;
    localparam  state_pre_trigger   = 'd1;
    localparam  state_wait_trigger  = 'd2;
    localparam  state_post_trigger  = 'd3;
    localparam  state_readout       = 'd4;
    localparam  state_end           = 'd5;
    
    
    (* mark_debug = "true" *) reg                              acquiring              ;
    reg [LOG2_SNAPSHOT_DEPTH - 1: 0] sample_cnt             ;
    reg [LOG2_SNAPSHOT_DEPTH - 1: 0] read_cnt               ;
    (* mark_debug = "true" *) reg [LOG2_SNAPSHOT_DEPTH - 1: 0] wr_addr                ;
    (* mark_debug = "true" *) reg [LOG2_SNAPSHOT_DEPTH - 1: 0] rd_addr                ;
    reg [LOG2_SNAPSHOT_DEPTH - 1: 0] wr_addr_triggerpoint   ;
    (* mark_debug = "true" *)reg                              wr_ram_en              ;
    (* mark_debug = "true" *) reg                              rd_ram_en              ;
    reg rd_ram_en_d;
    reg wr_fifo_buffer_en;
    reg rd_fifo_buffer_en;
    reg rd_fifo_buffer_en_d;
    reg wr_fifo_snapshot_en;
    reg [1023:0] data_in_r;
    
    (* mark_debug = "true" *) wire                             reading                ;
    (* mark_debug = "true" *) wire [DATA_BUS_WIDTH - 1: 0]data_out_ram           ;
    wire fifo_snapshot_full;
    wire fifo_snapshot_prog_full;
    wire fifo_snapshot_empty;
    wire fifo_buffer_full;
    wire fifo_buffer_empty;
    wire [255:0] fifo_buffer_out;
    
    always @(posedge clk_data) begin
        if (rst) begin
            state <= state_idle;
        end
        else if (data_in_valid) begin
            case (state)
            
            state_idle:
            begin
                acquiring <= 'd1;
                sample_cnt <= 'd0;
                read_cnt <= 'd0;
                wr_addr_triggerpoint <= 'd0;
                state <= state_pre_trigger;
            end
            
            state_pre_trigger:
            begin
                sample_cnt <= sample_cnt + 1;
                if (sample_cnt == SNAPSHOT_DEPTH/2 - 1) begin
                    state <= state_wait_trigger;
                end
            end
            
            state_wait_trigger:
            begin
                if (trigger) begin
                    wr_addr_triggerpoint <= wr_addr;
                    state <= state_post_trigger;
                end
            end
            
            state_post_trigger:
            begin
                if (sample_cnt == SNAPSHOT_DEPTH - 1) begin
                    rd_addr <= wr_addr_triggerpoint ^ 10'h200;
                    acquiring <= 'd0;
                    state <= state_readout;
                end
                else begin
                    sample_cnt <= sample_cnt + 1;
                end
            end
            
            state_readout:
            begin
                if (!fifo_buffer_full) begin
                    if (read_cnt == SNAPSHOT_DEPTH - 1) begin
                        state <= state_end;
                    end
                    else begin
                        rd_addr <= rd_addr + 1;
                        read_cnt <= read_cnt + 1;
                    end
                end
            end
            
            state_end: state <= state_idle;
            
            default: state <= state_idle;
            
            endcase
        end
    end
    
    
    always @(posedge clk_data) begin
        if (rst) begin
            wr_addr <= 'd0;
        end
        else if (data_in_valid) begin
            if (acquiring) begin
                wr_addr <= wr_addr + 1;
            end
        end
    end
    
    always @(posedge clk_data) begin
        if (rst) begin
            wr_ram_en <= 'd0;
        end
        else if (acquiring) begin
            wr_ram_en <= data_in_valid;
        end
        else begin
            wr_ram_en <= 'd0;
        end
    end
    
    assign reading = (state == state_readout)? 'd1: 'd0;
    
    always @(posedge clk_data) begin
        if (rst) begin
            rd_ram_en <= 'd0;
        end
        else if (reading) begin
            if (!fifo_buffer_full) begin
                rd_ram_en <= data_in_valid;
            end
            else begin
                rd_ram_en <= 'd0;
            end
        end
        else begin
            rd_ram_en <= 'd0;
        end
    end
    
    always @(posedge clk_data) begin
        data_in_r <= data_in;
    end
    
    ram_snapshot u_ram_snapshot (
      .clka(clk_data),    // input wire clka
      .ena(wr_ram_en),      // input wire ena
      .wea(1'b1),      // input wire [0 : 0] wea
      .addra(wr_addr),  // input wire [9 : 0] addra
      .dina(data_in_r),    // input wire [1023 : 0] dina
      .clkb(clk_data),    // input wire clkb
      .enb(rd_ram_en),      // input wire enb
      .addrb(rd_addr),  // input wire [9 : 0] addrb
      .doutb(data_out_ram)  // output wire [1023 : 0] doutb
    );
    
    
    always @(posedge clk_data) begin
//        rd_ram_en_d <= rd_ram_en;
//        wr_fifo_buffer_en <= rd_ram_en_d;
        wr_fifo_buffer_en <= rd_ram_en;
    end   
    
    always @(posedge clk_data) begin
        if (!fifo_buffer_empty) begin
            if (!fifo_snapshot_prog_full) begin
                rd_fifo_buffer_en <= data_in_valid;
            end
            else begin
                rd_fifo_buffer_en <= 'd0;
            end
        end
        else begin
            rd_fifo_buffer_en <= 'd0;
        end
    end
    
    fifo_buffer u_fifo_buffer (
      .clk(clk_data),      // input wire clk
      .din(data_out_ram),      // input wire [1023 : 0] din
      .wr_en(wr_fifo_buffer_en),  // input wire wr_en
      .rd_en(rd_fifo_buffer_en),  // input wire rd_en
      .dout(fifo_buffer_out),    // output wire [255 : 0] dout
      .full(fifo_buffer_full),    // output wire full
      .empty(fifo_buffer_empty)  // output wire empty
    );

    always @(posedge clk_data) begin
//        rd_fifo_buffer_en_d <= rd_fifo_buffer_en;
//        wr_fifo_snapshot_en <= rd_fifo_buffer_en_d;

//        if (!fifo_snapshot_prog_full) begin
//            wr_fifo_snapshot_en <= rd_fifo_buffer_en;
//        end
//        else begin
//            wr_fifo_snapshot_en <= 'd0;
//        end
        wr_fifo_snapshot_en <= rd_fifo_buffer_en;
    end   

    fifo_snapshot u_fifo_snapshot (
      .wr_clk(clk_data),  // input wire wr_clk
      .rd_clk(clk_reg),  // input wire rd_clk
      .din(fifo_buffer_out),        // input wire [255 : 0] din
      .wr_en(wr_fifo_snapshot_en),    // input wire wr_en
      .rd_en(rd_fifo_en),    // input wire rd_en
      .dout(data_out),      // output wire [31 : 0] dout
      .full(fifo_snapshot_full),      // output wire full
      .empty(fifo_snapshot_empty),    // output wire empty
      .prog_full(fifo_snapshot_prog_full)  // output wire prog_full
    );
    
endmodule
