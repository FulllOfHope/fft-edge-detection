`timescale 1ns / 1ps

module delay_line #(
    parameter DEPTH = 1
)(
    input  wire clk,
    input  wire reset,
    input  wire signed [15:0] in_r, in_i,
    output wire signed [15:0] out_r, out_i
);
    
    generate
        if (DEPTH == 0) begin
            // The Stage 10 Safety Bypass
            assign out_r = in_r;
            assign out_i = in_i;
        end else begin
            // Standard Shift Register
            reg [31:0] mem [0:DEPTH-1];
            integer i;
            
           always @(posedge clk) begin 
              if (!reset) begin
                for (i = 0; i < DEPTH; i = i + 1)
                  mem[i] <= 32'd0;
              end else begin
                     for (i = DEPTH-1; i > 0; i = i - 1)
                         mem[i] <= mem[i-1];
                         mem[0] <= {in_r, in_i};
              end
           end
          assign {out_r, out_i} = mem[DEPTH-1];
    
         end
    endgenerate
endmodule
