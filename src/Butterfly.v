`timescale 1ns / 1ps

module Butterfly( x0_r,x0_i,x1_r,x1_i,w_r,w_i,y0_r,y0_i,y1_r,y1_i,clk );
    input clk;
    input signed [15:0] x0_r, x0_i;
    input signed [15:0] x1_r, x1_i;
    input signed [15:0] w_r,  w_i;
    output signed [15:0] y0_r, y0_i;
    output signed [15:0] y1_r, y1_i;

    wire signed [31:0] mul_r, mul_i;
    wire signed [15:0] diff_r, diff_i;
    wire signed [15:0] sum_r, sum_i;

    // 1. ADDERS WITH ROUND-HALF-UP
    wire signed [16:0] sum_r_17  = {x0_r[15], x0_r} + {x1_r[15], x1_r};
    wire signed [16:0] sum_i_17  = {x0_i[15], x0_i} + {x1_i[15], x1_i};
    wire signed [16:0] diff_r_17 = {x0_r[15], x0_r} - {x1_r[15], x1_r};
    wire signed [16:0] diff_i_17 = {x0_i[15], x0_i} - {x1_i[15], x1_i};

    // Adding 1 before the arithmetic shift performs perfect Round-to-Nearest
    assign sum_r  = (sum_r_17  + 17'd1) >>> 1;
    assign sum_i  = (sum_i_17  + 17'd1) >>> 1;
    assign diff_r = (diff_r_17 + 17'd1) >>> 1;
    assign diff_i = (diff_i_17 + 17'd1) >>> 1;

    reg signed [15:0] sum_r_reg,  sum_i_reg;
    reg signed [15:0] diff_r_reg, diff_i_reg;
    reg signed [15:0] w_r_reg,    w_i_reg;

    always @(posedge clk) begin
        sum_r_reg  <= sum_r;
        sum_i_reg  <= sum_i;
        diff_r_reg <= diff_r;
        diff_i_reg <= diff_i;
        w_r_reg    <= w_r;
        w_i_reg    <= w_i;
    end

    // 2. MULTIPLIERS WITH Q1.15 ROUNDING
    wire signed [31:0] p_rr = diff_r_reg * w_r_reg;
    wire signed [31:0] p_ii = diff_i_reg * w_i_reg;
    wire signed [31:0] p_ri = diff_r_reg * w_i_reg;
    wire signed [31:0] p_ir = diff_i_reg * w_r_reg;

    assign mul_r = p_rr - p_ii;
    assign mul_i = p_ri + p_ir;

    // Add 0.5 (16'h4000) to the 32-bit product before slicing to round it
    wire signed [31:0] mul_r_round = mul_r + 32'h00004000;
    wire signed [31:0] mul_i_round = mul_i + 32'h00004000;

    assign y0_r = sum_r_reg;
    assign y0_i = sum_i_reg;

    // Output assignment using the rounded multiplier values
    assign y1_r = mul_r_round[30:15];
    assign y1_i = mul_i_round[30:15];

endmodule