`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/20 11:07:22
// Design Name: 
// Module Name: channel_delay
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


module channel_delay #(
    DATA_WIDTH = 16,
    CMD_WIDTH = 32
)
(
    input clk_data,
    input rst,
    input [CMD_WIDTH - 1: 0] nof_delay,
    input [DATA_WIDTH - 1: 0] data_in,
    input data_in_valid,
    
    output [DATA_WIDTH - 1: 0] data_out        
    );
    
   
    (* mark_debug = "true" *) reg [CMD_WIDTH - 1: 0] nof_delay_r ;
    reg fifo_wr_en;
    reg fifo_rd_en;
    (* mark_debug = "true" *) reg [CMD_WIDTH - 1: 0] cnt;
    
    wire fifo_full;
    wire fifo_empty;
    
    // buffer num of delay
    always @(posedge clk_data) begin
        if (rst) begin
            nof_delay_r <= 'd0;
        end
        else begin
            nof_delay_r <= nof_delay;
        end
    end
    
    // generate write enable for fifo
    always @(posedge clk_data) begin
        if (rst) begin
            fifo_wr_en <= 'd0;
        end
        else begin
            if (!fifo_full) begin
                fifo_wr_en <= data_in_valid; // should make sure the data_in_valid only lasts for 1 data clock cycle, otherwise a same data will be written into fifo multiple times 
            end
        end
    end 
    
    
    always @(posedge clk_data) begin
        if (rst) begin
            cnt <= 'd0;
        end
        else if (data_in_valid) begin
            if (!fifo_empty) begin
                if (cnt < nof_delay_r) begin
                    cnt <= cnt + 1;
                end
            end
        end
    end
    
    always @(posedge clk_data) begin
        if (rst) begin
            fifo_rd_en <= 'd0;
        end
        else if (!fifo_empty) begin
            if (cnt == nof_delay_r) begin
                fifo_rd_en <= data_in_valid;
            end
        end
    end
    
    
    fifo_channel_delay u_fifo_channel_delay (
      .clk(clk_data),      // input wire clk
      .srst(rst),      // input wire rst
      .din(data_in),      // input wire [15 : 0] din
      .wr_en(fifo_wr_en),  // input wire wr_en
      .rd_en(fifo_rd_en),  // input wire rd_en
      .dout(data_out),    // output wire [15 : 0] dout
      .full(fifo_full),    // output wire full
      .empty(fifo_empty)  // output wire empty
    );
    
    
endmodule
