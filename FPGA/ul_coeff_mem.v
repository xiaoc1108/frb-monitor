/* -*- coding: us-ascii-dos -*-
 *
 * Copyright Signal Processing Devices Sweden AB. All rights reserved.
 * See document "08-0175 EULA" for specific license terms regarding this file.
 *
 * Description: Coefficient memory for the linear phase FIR filter.
 */

`timescale 1 ns / 1 ps
`default_nettype none

module ul_coeff_mem #(
   COEFF_WIDTH      = 0,
   COEFF_FRAC_WIDTH = 0,
   NOF_COEFFS       = 0
)(
   input wire clk_i,
   input wire rst_i,

   input wire [COEFF_WIDTH-1:0] coeff_i,
   input wire [6:0] coeff_index_i,
   input wire coeff_update_i,
   input wire coeff_wren_i,

   output wire [NOF_COEFFS*COEFF_WIDTH-1:0] coeffs_o
);
   /* Parameter validation */
   if (COEFF_WIDTH == 0)
      always ERROR_COEFF_MEM_COEFF_WIDTH_IS_ZERO();
   if (COEFF_FRAC_WIDTH == 0)
      always ERROR_COEFF_MEM_COEFF_FRAC_WIDTH_IS_ZERO();
   if (NOF_COEFFS == 0)
      always ERROR_COEFF_MEM_NOF_COEFFS_IS_ZERO();
   if (NOF_COEFFS > (1 << 6))
      always ERROR_COEFF_MEM_ADDR();

   /* Local parameters, wires & registers */
   reg [COEFF_WIDTH-1:0] coeff_mem [NOF_COEFFS-1:0];
   reg [COEFF_WIDTH-1:0] coeff_latch [NOF_COEFFS-1:0];
   reg coeff_update_d;
   wire coeff_update_posedge;

   genvar k;
   integer i;

   /* Coefficient memory */
   always @(posedge clk_i) begin
      if (rst_i) begin
         for (i = 0; i < NOF_COEFFS; i = i + 1) begin
            coeff_mem[i] <= {(COEFF_WIDTH){1'b0}};
         end
      end else begin
         if (coeff_wren_i)
            coeff_mem[coeff_index_i] <= coeff_i;
      end
   end

   /* Register stage to ensure stable coefficients are applied to the filter */
   assign coeff_update_posedge = coeff_update_i & ~coeff_update_d;
   always @(posedge clk_i) begin
      if (rst_i) begin
         for (i = 0; i < NOF_COEFFS; i = i + 1) begin
            if (i == NOF_COEFFS-1) begin
               /* Center tap default value = 1. */
               coeff_latch[i] <= {{(COEFF_WIDTH-COEFF_FRAC_WIDTH-1){1'b0}},
                                  1'b1, {(COEFF_FRAC_WIDTH){1'b0}}};
            end else begin
               coeff_latch[i] <= {(COEFF_WIDTH){1'b0}};
            end
         end
         coeff_update_d <= 1'b0;
      end else begin
         if (coeff_update_posedge) begin
            /* Update w/ new values from memory. */
            for (i = 0; i < NOF_COEFFS; i = i + 1) begin
               coeff_latch[i] <= coeff_mem[i];
            end
         end
         coeff_update_d <= coeff_update_i;
      end
   end

   /* Layout coefficients in one dimension and assign output. */
   generate
      for (k = 0; k < NOF_COEFFS; k = k + 1) begin
         assign coeffs_o[k*COEFF_WIDTH +: COEFF_WIDTH] = coeff_latch[k];
      end
   endgenerate
endmodule

`default_nettype wire