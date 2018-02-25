module Interface (

	input wire 	clk,
	input wire 	RX,
	input wire 	semafor_in,
	
	input wire 	[0:FRAME_SIZE] fin,
	input wire 						fin_valid,
	
	input wire 						confirm,
	input wire 	[7:0] 			conf_code,
	
	output wire [0:FRAME_SIZE] fout,
	output reg 						fout_valid,
	output reg 						semafor_out,
	
	output wire 	[7:0]				conf_from_PC,
	output wire 						conf_from_PC_valid,
	
	output reg TX,
	
	output wire diod1, diod2, diod3, diod4, diod5, diod6, diod7, diod8, diod9, diod10
	
);

parameter DATA_SIZE 			= 64;
parameter PREAMBLE_SIZE 	= 7;
parameter CRC_SIZE 			= 4;
parameter FRAME_SIZE 		= (PREAMBLE_SIZE + DATA_SIZE + CRC_SIZE)*8-1; // in bits

// TYPY RAMEK
parameter [7:0]	FIRST_FRAME 		=	8'h00;
parameter [7:0]	LAST_FRAME 			=	8'h01;
parameter [7:0]	NORMALNA 			=	8'h02;
parameter [7:0]	POJEDYNCZA 			=	8'h03;

//FLAGI
parameter [7:0]	FRAME_START 		=	8'h06; 
parameter [7:0]	FRAME_END 			=	8'h07; 
parameter [7:0]	ESC_VAL 				=	8'h14; 
parameter [7:0]	ESC_XOR 				=	8'h20; 

//POTWIERDZENIA
parameter [7:0] 	OKAY					=	8'h05; 
parameter [7:0]	ERROR 				=	8'h04;
parameter [7:0]	FATAL_ERROR			= 	8'h08;

parameter [9:0]	IDLE 					= 10'b0000000001,
						RECEIVING 			= 10'b0000000010,
						TRANSMITTING 		= 10'b0000000100,
						WAIT_FOR_CONF 		= 10'b0000001000,
						WAIT_TX			 	= 10'b0000010000,
						CONFIRM				= 10'b0000100000,
						RESET					= 10'b0001000000,
						WAIT_CLK				= 10'b0010000000,
						WAIT_LONG			= 10'b0100000000,
						HARD_RESET			= 10'b1000000000;        
						
reg 	[9:0] 			state; 

reg [7:0]	confirm_from_PC;
reg 			confirm_from_PC_valid;
			
reg 	[0:FRAME_SIZE] frame;
reg 	[7:0] 			byte_out;
reg						frame_loaded;

reg 						to_escape;
wire 	[7:0] 			byte_in;
wire 						byte_ready;
wire 						tx_ready;

reg 						transmit_frame;
wire 						transmit;

reg dioda1, dioda2, dioda3, dioda4, dioda5, dioda6, dioda7, dioda8, dioda9, dioda10;

integer 					counter_r, counter_s; // liczniki receivera i tranmittera
integer 					count_clk;
wire init	=	1'b0;

RS232_TRANSMITTER transmitter (
	.CLK	(clk),
	.INIT	(init),
	.DRL	(transmit),
	.LOAD	(tx_ready),
	.DIN	(byte_out),
	.TX	(TX)
);

RS232_RECEIVER receiver (
	.CLK		(clk),
	.INIT		(init),
	.RX		(RX),
	.STORE	(byte_ready),
	.DOUT		(byte_in)
);


initial begin
	frame 						<= {FRAME_SIZE+1{1'b0}};
	fout_valid 					<= 1'b0;
	frame_loaded 				<= 1'b0;
	transmit_frame				<=	1'b0;
	byte_out 					<= 8'h00;
	counter_r 					<= 0;
	counter_s					<=	0;
	to_escape 					<= 1'b0;
	state							<=	IDLE;
	semafor_out					<= 1'b0;
	confirm_from_PC			<= 8'h00;
	confirm_from_PC_valid	<= 1'b0;
	count_clk					<= 0;
	dioda1 			<= 1'b0;
	dioda2 			<= 1'b0;
	dioda3 			<= 1'b0;
	dioda4 			<= 1'b0;
	dioda5 			<= 1'b0;
	dioda6 			<= 1'b0;
	dioda7 			<= 1'b0;
	dioda8 			<= 1'b0;
	dioda9 			<= 1'b0;
	dioda10 			<= 1'b0;
	temp <= 1'b0;
end

reg temp;

assign diod1 = dioda1;	
assign diod2 = dioda2;	
assign diod3 = dioda3;	
assign diod4 = dioda4;	
assign diod5 = dioda5;	
assign diod6 = dioda6;	
assign diod7 = dioda7;	
assign diod8 = dioda8;	
assign diod9 = dioda9;	
assign diod10 = dioda10;

always @ (posedge clk) begin

case(state)
	IDLE: begin
		if (fout_valid) begin
			fout_valid <= 1'b0;
		end
		if (fin_valid) begin
			frame <= fin;
			transmit_frame <= 1'b1;
			state <= TRANSMITTING;
		end
		if (byte_ready) begin
			if (byte_in == FRAME_START && !semafor_in) begin
				state <= RECEIVING;
				semafor_out <= 1'b1;
			end
			if (byte_in == FATAL_ERROR) begin
				state <= HARD_RESET;
			end
		end
	end
	RECEIVING: begin
//		if (frame_loaded) begin
//			state <= CONFIRM;
//		end
		if (byte_ready) begin
			if (to_escape) begin
				frame[counter_r*8+:8] <= (byte_in ^ ESC_XOR);
				to_escape <= 1'b0;
				counter_r <= counter_r + 1;
			end
			if (!to_escape) begin
				if (byte_in == FRAME_END) begin
					if (counter_r == DATA_SIZE + 11) begin // ramka wychodzi z interfejsu
						fout_valid <= 1'b1;
						frame_loaded <= 1'b1;
						state <= CONFIRM;
					end else begin			// nie odebrano calej ramki, counter za maly
						transmit_frame <= 1'b1;
						byte_out <= 8'h66;
						state <= WAIT_TX;
					end
				end
				if (byte_in == ESC_VAL) begin
					to_escape <= 1'b1;
				end
				if (byte_in != FRAME_END && byte_in != ESC_VAL) begin
					frame[counter_r*8+:8] <= byte_in;
					counter_r <= counter_r + 1;
				end
			end
		end
		if (counter_r > DATA_SIZE + 13) begin // counter przekrozyl ramke, nie napotano frame end
			transmit_frame <= 1'b1;
			byte_out <= ERROR;
			state <= WAIT_TX;
		end
	end
	
//	VALID: begin
//			if (frame[0:7] == FIRST_FRAME) begin
//				fout_valid <= 1'b1;
//				state <= CONFIRM;
//				transmit_frame <= 1'b1;
//				byte_out <= OKAY;
//				lastFrameNr <= frame[24:55];
//			end else begin
//				if (frame[24:55] == (lastFrameNr + 1)) begin
//					fout_valid <= 1'b1;
//					transmit_frame <= 1'b1;
//					byte_out <= OKAY;
//					lastFrameNr <= lastFrameNr + 1;
//					frame_loaded <= 1'b0;
//					state <= CONFIRM;
//				end else begin
//					transmit_frame <= 1'bcounter_r == DATA_SIZE + 111;
//					byte_out <= ERR_NR;
//					state <= CONFIRM;
//					semafor_out <= 1'b0;
//				end
//				if (frame[0:7] == LAST_FRAME) begin
//					semafor_out <= 1'b0;
//					//state <= RESET;
//					lastFrameNr <= {32{1'b0}};
//				end
//			end
//	endFIRST_FRAME
	
	TRANSMITTING: begin
//		if (temp) begin
//			dioda8 <= 1'b1;
//		end
		if (tx_ready) begin
//			if (temp) begin
//				dioda9 <= 1'b1;
//			end
			if (counter_s == 0) begin
				byte_out <= FRAME_START;
				to_escape <= 1'b0;
				counter_s <= counter_s + 1;
			end
			if (counter_s > 0 && counter_s <= DATA_SIZE+11) begin
				if (to_escape) begin
					byte_out <= (frame[(counter_s+1)*8+:8] ^ ESC_XOR);
					to_escape <= 1'b0;
					counter_s <= counter_s + 1;
				end else begin
					if (frame[(counter_s+1)*8+:8] == FRAME_END || frame[(counter_s+1)*8+:8] == FRAME_START || frame[(counter_s+1)*8+:8] == ESC_VAL) begin // dodac eskejpowanie bajtu eskejpacji
						byte_out <= ESC_VAL;
						to_escape <= 1'b1;
					end else begin
						byte_out <= frame[(counter_s+1)*8+:8];
						counter_s <= counter_s + 1;
					end
				end
			end
			if (counter_s == DATA_SIZE+12) begin
				byte_out <= FRAME_END;
				counter_s <= counter_s + 1;
				transmit_frame <= 1'b0;	
			end
		end
		if (counter_s == DATA_SIZE+13) begin
			state <= WAIT_FOR_CONF;
		end
	end
	
	WAIT_LONG: begin
			if (count_clk == 20) begin
				if (confirm_from_PC == FATAL_ERROR) begin
					state <= HARD_RESET;
				end else begin
					state <= RESET;
				end
			end
			count_clk <= count_clk + 1;
		end
	
	WAIT_TX: begin
		if (tx_ready) begin
			state <= RESET;
		end
	end
	
	WAIT_CLK: begin
		state <= RESET;
	end
	
	WAIT_FOR_CONF: begin // czeka na confirm od peceta
		dioda1 <= 1'b1;
		if (byte_ready) begin
				confirm_from_PC <= byte_in;
				confirm_from_PC_valid <= 1'b1;
				state <= WAIT_LONG; // zamiast WAIT_CLK
		end
	end
	
	CONFIRM: begin
		if (confirm) begin
			byte_out <= conf_code;
			transmit_frame <= 1'b1;
			state <= WAIT_TX;
		end
	end
	
	HARD_RESET: begin
		frame 						<= {FRAME_SIZE+1{1'b0}};
		fout_valid 					<= 1'b0;
		frame_loaded 				<= 1'b0;
		transmit_frame				<=	1'b0;
		byte_out 					<= 8'h00;
		counter_r 					<= 0;
		counter_s					<=	0;
		to_escape 					<= 1'b0;
		state							<=	IDLE;
		semafor_out					<= 1'b0;
		confirm_from_PC			<= 8'h00;
		confirm_from_PC_valid	<= 1'b0;
		count_clk					<= 0;
	end
	
	RESET: begin
		frame 						<= {FRAME_SIZE+1{1'b0}};
		count_clk 					<= 0;
		fout_valid 					<= 1'b0;
		frame_loaded 				<= 1'b0;
		transmit_frame				<=	1'b0;
		byte_out 					<= 8'h00;
		counter_r 					<= 0;
		counter_s					<=	0;
		to_escape 					<= 1'b0;
		state							<=	IDLE;
		confirm_from_PC			<= 8'h00;
		confirm_from_PC_valid	<= 1'b0;
	end
	
endcase	
end

assign conf_from_PC = confirm_from_PC;
assign conf_from_PC_valid = confirm_from_PC_valid;

assign fout = frame;
assign transmit = (transmit_frame) ? 1'b1:1'b0;


endmodule



















