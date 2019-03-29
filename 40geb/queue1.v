`timescale 1ns / 1ps

module queue#(
    parameter C_MAX_DEPTH_BITS = 6,
	parameter C_DATA_WIDTH = 8,
	parameter C_MTY_WIDTH = 8
)(
    input            				s_axis_tvalid,
    input [C_DATA_WIDTH - 1:0]       s_axis_tdata,
	input               			s_axis_tlast,
	input [C_MTY_WIDTH - 1:0]        s_axis_tuser_mty,
	output reg          				s_axis_tready,//()
	
	input               			drop_incmpt_pkt,
	
	output reg          			m_axis_tvalid,
	output reg [C_DATA_WIDTH - 1:0]  m_axis_tdata,
	output reg          			m_axis_tlast,
	output reg [C_MTY_WIDTH - 1:0]   m_axis_tuser_mty,
	input               				m_axis_tready,
    
    input areset,
    input aclk
    );
    localparam L_MAX_DEPTH = 2 ** C_MAX_DEPTH_BITS;
	
	
	reg [C_MAX_DEPTH_BITS - 1:0] wr_p;
	reg [C_MAX_DEPTH_BITS - 1:0] rd_p;
	reg wrupdate;
	reg [C_MAX_DEPTH_BITS - 1:0] last_wr;
	reg [C_MAX_DEPTH_BITS - 1:0] last_rd;
	reg wea;
	reg [C_MAX_DEPTH_BITS - 1:0] addra;
	reg [C_DATA_WIDTH + C_MTY_WIDTH + 1 - 1:0] dina;
	reg [C_MAX_DEPTH_BITS - 1:0] addrb;
	wire [C_DATA_WIDTH + C_MTY_WIDTH + 1 - 1:0] doutb;
	reg [C_MAX_DEPTH_BITS - 1:0] depth;
	
	wire full;
	reg full_1;
	
	//wire 							m_axis_tvalid_out;
	wire [C_DATA_WIDTH - 1:0] 		m_axis_tdata_out;
	wire 							m_axis_tlast_out;
	wire [C_MTY_WIDTH - 1:0]   		m_axis_tuser_mty_out;
	assign {m_axis_tdata_out, m_axis_tlast_out, m_axis_tuser_mty_out} = doutb;
	
	//wire  							s_axis_tvalid_in;
	wire [C_DATA_WIDTH - 1:0] 		s_axis_tdata_in;
	wire 							s_axis_tlast_in;
	wire [C_MTY_WIDTH - 1:0]   		s_axis_tuser_mty_in;
	assign {s_axis_tdata_in,s_axis_tlast_in, s_axis_tuser_mty_in} = dina;
	reg bram_valid;
	reg [C_MAX_DEPTH_BITS - 1:0] pkt_cnt;
	
	reg [C_MAX_DEPTH_BITS - 1:0] rd_p_last;//上一个读的地址
	//reg [C_MAX_DEPTH_BITS - 1:0] rd_p_before;
	reg read1;
	reg read2;
	reg read3;
	
	reg [3:0] 										c_cnt;
	reg [C_DATA_WIDTH + C_MTY_WIDTH + 1 - 1:0]  tmp_d1;
	reg [C_DATA_WIDTH + C_MTY_WIDTH + 1 - 1:0]  tmp_d2;
	reg [C_DATA_WIDTH + C_MTY_WIDTH + 1 - 1:0]  tmp_d3;
	
	reg [3:0]										read_delay_3clc;
	
	//blk_290_8192 mm_inst(//290 = 1 + 256 + 1 + 32// = s_axis_tvalid + s_axis_tdata + s_axis_tlast + s_axis_tuser_mty;
	//	.clka(),
	//	.wea(),
	//	.addra(),
	//	.dina(),
	//	.clkb(),
	//	.addrb(),
	//	.doutb()
	//);
	blk_20_64 mm_inst(//18 = 1 + 8 + 1 + 8// = s_axis_tvalid + s_axis_tdata + s_axis_tlast + s_axis_tuser_mty;
		.clka(aclk),
		.clkb(aclk),
		
		.wea(wea),
		.addra(addra),
		.dina(dina),
		
		.addrb(addrb),
		.doutb(doutb)
	);	
	
	always @(posedge aclk) begin//write
		if(areset)begin
			wrupdate <= 1;
			wea <= 0;
			addra <= 0;
			dina <= 0;
			wr_p <= 0;
			last_wr <= 0;
			full_1 <= 0;
			//last_rd <= 0
		end else begin
			if(s_axis_tvalid && !full && !full_1)begin
				wea <= 1;
				addra <= wr_p;
				dina <= {s_axis_tvalid, s_axis_tdata, s_axis_tlast, s_axis_tuser_mty};
				wr_p <= wr_p + 1;
			end else begin
				wea <= 0;
			end
			if(wrupdate && !full)begin
				last_wr <= wr_p;
				wrupdate <= 0;
			end
			if(s_axis_tvalid && s_axis_tlast && !full)begin
				wrupdate <= 1;
			end
			if(full || full_1)begin
			    wr_p <= last_wr;
			    full_1 <= 1;
			end
			if(drop_incmpt_pkt)begin
			    full_1 <= 0;
			    //wr_p <= last_wr;
			end
			//rd_p_last <= wr_p;
		end
	end
	
	assign pkt_in_cnt = s_axis_tvalid && !full && !full_1 && s_axis_tlast;
	assign pkt_out_cnt = m_axis_tvalid && m_axis_tlast && m_axis_tready && bram_valid;
	
	always @(posedge aclk)begin
		if(areset)begin
			pkt_cnt <= 0;
		end else begin
			if(pkt_in_cnt && !pkt_out_cnt)begin
				pkt_cnt <= pkt_cnt + 1;
			end
			if(!pkt_in_cnt && pkt_out_cnt)begin
				pkt_cnt <= pkt_cnt - 1;
			end
			
		end
	end
	
	
	
	
	always @(posedge aclk)begin//read
		if(areset)begin
			rd_p <= 0;
			read1 <= 0;
			read2 <= 0;
			read3 <= 0;
			bram_valid <= 0;
			m_axis_tvalid <= 0;
			m_axis_tdata <= 0;
			m_axis_tlast <= 0;
			m_axis_tuser_mty <= 0;
			//addrb <= 0;//
			rd_p_last <= 0;
			c_cnt <= 0;
			tmp_d1 <= 0;
			tmp_d2 <= 0;
			tmp_d3 <= 0;
			read_delay_3clc <= 0;
		end else begin
			if(pkt_cnt > 0)begin
				if(read_delay_3clc < 6)begin
					read_delay_3clc <= read_delay_3clc + 1;
				end else begin
				
				end
				
			end else begin
				read_delay_3clc <= 0;
			end
			
			rd_p_last <= addrb;//rd_p
			
			if(pkt_cnt > 0 && !m_axis_tready )begin//读取数据不变，需要开始缓存。&& (read_delay_3clc >= 5)
				if(c_cnt == 0)begin
					c_cnt <= 1;
					tmp_d1 <= doutb;
				end else if(c_cnt == 1)begin
					c_cnt <= 2;
					tmp_d2 <= doutb;
				end else if(c_cnt == 2) begin
					c_cnt <= 3;
					tmp_d3 <= doutb;
				end
			end else begin
			end
			//if(pkt_cnt > 0 && depth>1)begin
			
			if(pkt_cnt > 0 && depth>1 )begin//&& (read_delay_3clc >= 5)
				read1 <= 1;
				addrb <= rd_p;
				if(m_axis_tready)begin
					rd_p <= rd_p + 1;
				end
			end else begin
				read1 <= 0;
			end
			if(read1)begin
				read2 <= 1;
				addrb <= rd_p;
				//rd_p <= rd_p + 1;
			end else begin
				read2 <= 0;
			end
			if(read2)begin
				read3 <= 1;
				addrb <= rd_p;
				//rd_p <= rd_p + 1;
			end else begin
				read3 <= 0;
			end
			if(read3 && !(pkt_cnt > 0 && !m_axis_tready)) begin//当发生变化，也要及时输出，所以不光得read3时候输出，在检测ready拉高后就要输出了。
				if(c_cnt == 3)begin
					c_cnt <= 2;
					//bram_valid <= 1;
					{m_axis_tdata, m_axis_tlast, m_axis_tuser_mty} <= tmp_d1;
				end else if(c_cnt == 2)begin
					c_cnt <= 1;
					//bram_valid <= 1;
					{m_axis_tdata, m_axis_tlast, m_axis_tuser_mty} <= tmp_d2;
				end else if(c_cnt == 1) begin
					c_cnt <= 0;
					//bram_valid <= 1;
					{m_axis_tdata, m_axis_tlast, m_axis_tuser_mty} <= tmp_d3;
				end else begin
					//bram_valid <= 1;
					{m_axis_tdata, m_axis_tlast, m_axis_tuser_mty} <= doutb;
				end
				bram_valid <= 1;
				m_axis_tvalid <= 1;
			end else if(pkt_cnt > 0 && !m_axis_tready)begin
				//bram_valid <= 1;
				//m_axis_tvalid <= 1;
				bram_valid <= 0;
				m_axis_tvalid <= 0;
			end else begin
				bram_valid <= 0;
				m_axis_tvalid <= 0;
			end
			
		end
	end
	always @(posedge aclk) begin
	    if(areset)begin
	       depth <= 0;
	       s_axis_tready <= 1;
	    end else begin
	        //if(s_axis_tvalid) begin
		        //depth <= depth + 1;
				depth <= wr_p - rd_p;
			//end   
	        if(full)begin
	            s_axis_tready <= 0;
	        end else begin
	            s_axis_tready <= 1;
	        end
	    end
	end
	
	assign full = depth == (L_MAX_DEPTH - 4);
	
	
	
	
	
	endmodule
