`timescale 1ns / 1ps

module multiplier #(
    parameter WIDTH = 32
)(
    input  wire        clk,
	input  wire        rst,
	input  wire [WIDTH-1:0] x,
	input  wire [WIDTH-1:0] y,
	input  wire        start,
	output reg  [2*WIDTH-1:0] z,
	output wire        busy 
);

	localparam O_WID = 2*WIDTH;
    localparam CNT_W = (WIDTH <= 1) ? 1 : $clog2(WIDTH + 1);

    reg [CNT_W-1:0] cnt;
    reg             busy_r;
    reg signed [O_WID:0] product;
    reg signed [O_WID:0] multiplicand;

    wire signed [O_WID:0] product_add =
        (product[1:0] == 2'b01) ? product + multiplicand :
        (product[1:0] == 2'b10) ? product - multiplicand :
                                  product;
    wire signed [O_WID:0] product_next = product_add >>> 1;

    assign busy = busy_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt          <= {CNT_W{1'b0}};
            busy_r       <= 1'b0;
            product      <= {(O_WID+1){1'b0}};
            multiplicand <= {(O_WID+1){1'b0}};
            z            <= {O_WID{1'b0}};
        end else if (start & !busy_r) begin
            cnt          <= {CNT_W{1'b0}};
            busy_r       <= 1'b1;
            product      <= {{WIDTH{1'b0}}, y, 1'b0};
            multiplicand <= {x, {(WIDTH+1){1'b0}}};
        end else if (busy_r) begin
            product <= product_next;
            cnt     <= cnt + {{(CNT_W-1){1'b0}}, 1'b1};

            if (cnt == WIDTH - 1) begin
                busy_r <= 1'b0;
                z      <= product_next[O_WID:1];
            end
        end
    end
    
endmodule
