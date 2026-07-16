`timescale 1ns / 1ps

module divider #(
    parameter WIDTH = 32
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [WIDTH-1:0] x,
    input  wire [WIDTH-1:0] y,
    input  wire       start,
    output wire [WIDTH-1:0] z,
    output reg  [WIDTH-1:0] r,
    output reg        busy     
);

    localparam MAG_W = WIDTH - 1;
    localparam CNT_W = (WIDTH <= 2) ? 1 : $clog2(WIDTH);

    reg [WIDTH-1:0] z_r;
    reg [CNT_W-1:0] cnt;
    reg [MAG_W-1:0] dividend;
    reg [MAG_W-1:0] divisor;
    reg [MAG_W-1:0] quotient;
    reg [MAG_W:0]   rem;
    reg             quo_sign;
    reg             rem_sign;

    wire [MAG_W-1:0] x_mag = x[MAG_W-1:0];
    wire [MAG_W-1:0] y_mag = y[MAG_W-1:0];
    wire [MAG_W:0]   trial_rem = {rem[MAG_W-1:0], dividend[MAG_W-1]};
    wire [MAG_W:0]   divisor_ext = {1'b0, divisor};
    wire             trial_ge = trial_rem >= divisor_ext;
    wire [MAG_W:0]   rem_next = trial_ge ? trial_rem - divisor_ext : trial_rem;
    wire [MAG_W-1:0] dividend_next = {dividend[MAG_W-2:0], 1'b0};
    wire [MAG_W-1:0] quotient_next = {quotient[MAG_W-2:0], trial_ge};

    assign z = z_r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            z_r      <= {WIDTH{1'b0}};
            r        <= {WIDTH{1'b0}};
            busy     <= 1'b0;
            cnt      <= {CNT_W{1'b0}};
            dividend <= {MAG_W{1'b0}};
            divisor  <= {MAG_W{1'b0}};
            quotient <= {MAG_W{1'b0}};
            rem      <= {(MAG_W+1){1'b0}};
            quo_sign <= 1'b0;
            rem_sign <= 1'b0;
        end else if (start & !busy) begin
            z_r      <= {WIDTH{1'b0}};
            r        <= {WIDTH{1'b0}};
            busy     <= 1'b1;
            cnt      <= (y_mag == {MAG_W{1'b0}}) ? {CNT_W{1'b0}} : MAG_W;
            dividend <= x_mag;
            divisor  <= y_mag;
            quotient <= {MAG_W{1'b0}};
            rem      <= {(MAG_W+1){1'b0}};
            quo_sign <= x[WIDTH-1] ^ y[WIDTH-1];
            rem_sign <= x[WIDTH-1];

            if (y_mag == {MAG_W{1'b0}}) begin
                z_r <= {1'b0, {MAG_W{1'b1}}};
                r   <= x;
            end
        end else if (busy) begin
            if (cnt == {CNT_W{1'b0}}) begin
                busy <= 1'b0;
            end else begin
                dividend <= dividend_next;
                quotient <= quotient_next;
                rem      <= rem_next;
                cnt      <= cnt - {{(CNT_W-1){1'b0}}, 1'b1};

                if (cnt == {{(CNT_W-1){1'b0}}, 1'b1}) begin
                    busy <= 1'b0;
                    z_r  <= {quo_sign & (quotient_next != {MAG_W{1'b0}}), quotient_next};
                    r    <= {rem_sign & (rem_next[MAG_W-1:0] != {MAG_W{1'b0}}), rem_next[MAG_W-1:0]};
                end
            end
        end
    end
	
endmodule
