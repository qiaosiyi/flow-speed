`timescale 1ns / 1ps

module queue(
    input            	s_axis_tvalid,
    input [7:0]       s_axis_tdata,
	input               s_axis_tlast,
	input [7:0]        s_axis_tuser_mty,
	output reg          s_axis_tready,//()
	
	input               drop_incmpt_pkt,
	
	output reg          m_axis_tvalid,
	output reg [7:0]  m_axis_tdata,
	output reg          m_axis_tlast,
	output reg [7:0]   m_axis_tuser_mty,
	input               m_axis_tready,
    
    input areset,
    input aclk
    );
	
	reg [12:0] wr_p;
	reg [12:0] rd_p;
	reg wrupdate;
	reg last_wr;
	reg wea;
	reg [5:0] addra;
	reg [19:0] dina;
	reg [5:0] addrb;
	wire [19:0] doutb;
	
	
	//blk_290_8192 mm_inst(//290 = 1 + 256 + 1 + 32// = s_axis_tvalid + s_axis_tdata + s_axis_tlast + s_axis_tuser_mty;
	//	.clka(),
	//	.wea(),
	//	.addra(),
	//	.dina(),
	//	.clkb(),
	//	.addrb(),
	//	.doutb()
	//);
	blk_20_64 mm_inst(//20 = 1 + 8 + 1 + 8// = s_axis_tvalid + s_axis_tdata + s_axis_tlast + s_axis_tuser_mty;
		.clka(aclk),
		.clkb(aclk),
		
		.wea(wea),
		.addra(addra),
		.dina(dina),
		
		.addrb(addrb),
		.doutb(doutb)
	);	
	
	always @(posedge aclk) begin
		if(areset)begin
			wrupdate <= 1;
			wea <= 0;
			addra <= 0;
			dina <= 0;
			wr_p <= 0;
			last_wr <= 0;
			
		end else begin
			if(s_axis_tvalid)begin
				wea <= 1;
				addra <= wr_p;
				dina <= {s_axis_tvalid, s_axis_tdata, s_axis_tlast, s_axis_tuser_mty};
				wr_p <= wr_p + 1;
			end
			if(wrupdate)begin
				last_wr <= wr_p;
				wrupdate <= 0;
			end
			if(s_axis_tvalid && s_axis_tlast)begin
				wrupdate <= 1;
			end
		end
	end
	
	
	
	
	
	
	
	endmodule
	
