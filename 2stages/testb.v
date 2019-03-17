
`timescale 1ns / 1ps
//pkt_ctl 0x00:invalid
//pkt_ctl 0x01:start
//pkt_ctl 0x02:payload
//pkt_ctl 0x03:end.
//pkt_ctl 0x04:64byte packet, only takes one cycle.

module test_b_cm;
	reg                            in_valid_5tuple_0 = 0;//egress 数据包parser 结果
	reg [103:0]                    in_5tuple_0 = 0;
	reg                            in_valid_sqn_0 = 0;
	reg [31:0]                     in_sqn_0 = 0;
	
	reg                            in_valid_5tuple_1 = 0;//ingress 数据包parser 结果
	reg [103:0]                    in_5tuple_1 = 0;
	reg                            in_valid_sqn_1 = 0;
	reg [31:0]                     in_sqn_1 = 0;
	
	wire                           out_valid_0;//egress 数据包lookup 结果
	wire [31:0]                    out_time_0;
	wire [31:0]                    out_sqn_0;
	wire [15:0]                    out_id_0;
	
	wire                           out_valid_1;//ingress 数据包lookup 结果
	wire [31:0]                    out_time_1;
	wire [31:0]                    out_sqn_1;
	wire [15:0]                    out_id_1;
	wire                           out_valid_tuple4search;
	wire [95 : 0]                  out_tuple4search;
	
	reg                            in_valid_id = 0;
	reg [15:0]                     in_id = 0;

	reg	reset=1, clk=1;

	
	always begin
		#5 clk = ~clk;

	end

	initial begin

		#7 reset = 1;

		#23 reset = 0;
		#10 in_valid_5tuple_0 = 1; in_5tuple_0 = 'haaaa1111;in_valid_sqn_0 = 1; in_sqn_0 = 'hbbbb1111;
		#10 in_valid_5tuple_0 = 0; in_5tuple_0 = 0;in_valid_sqn_0 = 0; in_sqn_0 = 0;
		
		#10 in_valid_5tuple_1 = 1; in_5tuple_1 = 'haaaa2222;in_valid_sqn_1 = 1; in_sqn_1 = 'hbbbb2222;
		#10 in_valid_5tuple_1 = 0; in_5tuple_1 = 0;in_valid_sqn_1 = 0; in_sqn_1 = 0;
		
		#10 in_valid_5tuple_0 = 1; in_5tuple_0 = 'haaaa3333;in_valid_sqn_0 = 1; in_sqn_0 = 'hbbbb3333;
		#10 in_valid_5tuple_0 = 0; in_5tuple_0 = 0;in_valid_sqn_0 = 0; in_sqn_0 = 0;
		
		#10 in_valid_5tuple_1 = 1; in_5tuple_1 = 'haaaa4444;in_valid_sqn_1 = 1; in_sqn_1 = 'hbbbb4444;
		#10 in_valid_5tuple_1 = 0; in_5tuple_1 = 0;in_valid_sqn_1 = 0; in_sqn_1 = 0;
		
		#10 in_valid_id = 1; in_id = 'h0011;
		#10 in_valid_id = 0; in_id = 0;
		
		#10 in_valid_5tuple_0 = 1; in_5tuple_0 = 'haaaa5555;in_valid_sqn_0 = 1; in_sqn_0 = 'hbbbb5555;
		#10 in_valid_5tuple_0 = 0; in_5tuple_0 = 0;in_valid_sqn_0 = 0; in_sqn_0 = 0;
		
		#10 in_valid_5tuple_0 = 1; in_5tuple_0 = 'haaaa6666;in_valid_sqn_0 = 1; in_sqn_0 = 'hbbbb6666;
		#10 in_valid_5tuple_0 = 0; in_5tuple_0 = 0;in_valid_sqn_0 = 0; in_sqn_0 = 0;
		
		#10 in_valid_id = 1; in_id = 'h0022;
		#10 in_valid_id = 0; in_id = 0;
		
		#10 in_valid_5tuple_1 = 1; in_5tuple_1 = 'haaaa7777;in_valid_sqn_1 = 1; in_sqn_1 = 'hbbbb7777;
		#10 in_valid_5tuple_1 = 0; in_5tuple_1 = 0;in_valid_sqn_1 = 0; in_sqn_1 = 0;
		
		#10 in_valid_5tuple_1 = 1; in_5tuple_1 = 'haaaa8888;in_valid_sqn_1 = 1; in_sqn_1 = 'hbbbb8888;
		#10 in_valid_5tuple_1 = 0; in_5tuple_1 = 0;in_valid_sqn_1 = 0; in_sqn_1 = 0;
		
		#10 in_valid_id = 1; in_id = 'h0011;
		#10 in_valid_id = 0; in_id = 0;
		
		#10 in_valid_id = 1; in_id = 'h0022;
		#10 in_valid_id = 0; in_id = 0;
		
		#10 in_valid_id = 1; in_id = 'h0011;
		#10 in_valid_id = 0; in_id = 0;
		
		#10 in_valid_id = 1; in_id = 'h0011;
		#10 in_valid_id = 0; in_id = 0;
		
		#10 in_valid_id = 1; in_id = 'h0022;
		#10 in_valid_id = 0; in_id = 0;
		
		#10 in_valid_id = 1; in_id = 'h0022;
		#10 in_valid_id = 0; in_id = 0;
	end
   
   

	
	arbiter #(
		
	) arbiter_inst(
		.clk(clk),
		.reset(reset),
		
		.in_valid_5tuple_0(in_valid_5tuple_0),
		.in_5tuple_0(in_5tuple_0),
		.in_valid_sqn_0(in_valid_sqn_0),
		.in_sqn_0(in_sqn_0),
		
		.in_valid_5tuple_1(in_valid_5tuple_1),
		.in_5tuple_1(in_5tuple_1),
		.in_valid_sqn_1(in_valid_sqn_1),
		.in_sqn_1(in_sqn_1),
		
		.out_valid_0(out_valid_0),
		.out_time_0(out_time_0),
		.out_sqn_0(out_sqn_0),
		.out_id_0(out_id_0),
		
		.out_valid_1(out_valid_1),
		.out_time_1(out_time_1),
		.out_sqn_1(out_sqn_1),
		.out_id_1(out_id_1),
		
		.out_valid_tuple4search(out_valid_tuple4search),
		.out_tuple4search(out_tuple4search),

		.in_valid_id(in_valid_id),
		.in_id(in_id)
	);
	
	txrx_ram_update#()tx_ram_update_inst(
		.in_valid_tx(out_valid_0),
		.in_id_tx(out_id_0),
		.in_time_tx(out_time_0),
		.in_sqn_tx(out_sqn_0),      

		.in_valid_rx(out_valid_1),
		.in_id_rx(out_id_1),
		.in_time_rx(out_time_1),
		.in_sqn_rx(out_sqn_1),
		
		.clk(clk),
		.reset(reset)//高复位
	);

endmodule // main
