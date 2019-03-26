`timescale 1ns / 1ps

module qtb;
	reg clk = 1;
	reg reset = 1;
	reg s_axis_tvalid = 0;
	reg s_axis_tdata = 0;
	reg s_axis_tlast = 0;
	reg s_axis_tuser_mty = 0;
	wire s_axis_tready;
	reg drop_incmpt_pkt = 0;
	
	wire m_axis_tvalid;
	wire m_axis_tdata;
	wire m_axis_tlast;
	wire m_axis_tuser_mty;
	reg m_axis_tready = 1;

always begin
	#5 clk = 1;
	#5 clk = 0;
end
	
initial begin

	#7 reset = 1;

	#23 reset = 0;
	
	#10 s_axis_tvalid = 1;s_axis_tdata = 'h01;s_axis_tlast = 0;s_axis_tuser_mty = 0;
	#10 s_axis_tvalid = 1;s_axis_tdata = 'h02;s_axis_tlast = 0;s_axis_tuser_mty = 0;
	#10 s_axis_tvalid = 1;s_axis_tdata = 'h03;s_axis_tlast = 0;s_axis_tuser_mty = 0;
	#10 s_axis_tvalid = 1;s_axis_tdata = 'h04;s_axis_tlast = 0;s_axis_tuser_mty = 0;
	#10 s_axis_tvalid = 1;s_axis_tdata = 'h05;s_axis_tlast = 1;s_axis_tuser_mty = 'h01;
	
	#10 s_axis_tvalid = 1;s_axis_tdata = 'h01;s_axis_tlast = 0;s_axis_tuser_mty = 0;
	#10 s_axis_tvalid = 1;s_axis_tdata = 'h02;s_axis_tlast = 0;s_axis_tuser_mty = 0;
	#10 s_axis_tvalid = 1;s_axis_tdata = 'h03;s_axis_tlast = 0;s_axis_tuser_mty = 0;
	#10 s_axis_tvalid = 1;s_axis_tdata = 'h04;s_axis_tlast = 0;s_axis_tuser_mty = 0;
	#10 s_axis_tvalid = 1;s_axis_tdata = 'h05;s_axis_tlast = 1;s_axis_tuser_mty = 'h02;
	
	#10 s_axis_tvalid = 0;s_axis_tdata = 'h00;s_axis_tlast = 0;s_axis_tuser_mty = 0;
	

end


queue#()queue_inst(
		.s_axis_tvalid(s_axis_tvalid),
		.s_axis_tdata(s_axis_tdata),
        .s_axis_tlast(s_axis_tlast),
		.s_axis_tuser_mty(s_axis_tuser_mty),
		.s_axis_tready(s_axis_tready),//()
		
		.drop_incmpt_pkt(drop_incmpt_pkt),
   
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tuser_mty(m_axis_tuser_mty),
        .m_axis_tready(m_axis_tready)
	);
	
	
endmodule
