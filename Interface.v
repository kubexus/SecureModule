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
	
	output reg TX
	
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

parameter [7:0]	IDLE 					= 8'b00000001,
						RECEIVING 			= 8'b00000010,
						TRANSMITTING 		= 8'b00000100,
						WAIT_FOR_CONF 		= 8'b00001000,
						WAIT_TX			 	= 8'b00010000,
						CONFIRM				= 8'b00100000,
						RESET					= 8'b01000000,
						WAIT_CLK				= 8'b10000000;
						
reg 	[7:0] 			state; 

reg [7:0]	confirm_from_PC;
reg confirm_from_PC_valid;
			
reg 	[0:FRAME_SIZE] frame;
reg 	[7:0] 			byte_out;
reg						frame_loaded;

reg 						to_escape;
wire 	[7:0] 			byte_in;
wire 						byte_ready;
wire 						tx_ready;

reg 						transmit_frame;
wire 						transmit;

integer 					counter_r, counter_s; // liczniki receivera i tranmittera

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
end


always @ (posedge clk) begin
//	if (byte_ready && byte_in == 8'h08) begin
//		state 				<= RESET;
//		semafor_out			<= 1'b0;
//	end
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
		if (tx_ready) begin
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
	
	WAIT_TX: begin
		if (tx_ready) begin
			state <= RESET;
		end
	end
	
	WAIT_CLK: begin
		state <= RESET;
	end
	
	WAIT_FOR_CONF: begin // czeka na confirm od peceta
		if (byte_ready) begin
			confirm_from_PC <= byte_in;
			confirm_from_PC_valid <= 1'b1;
			state <= WAIT_CLK;
		end
	end
	
	CONFIRM: begin
		if (confirm) begin
			byte_out <= conf_code;
			transmit_frame <= 1'b1;
			state <= WAIT_TX;
		end
	end
	
	RESET: begin
		frame 						<= {FRAME_SIZE+1{1'b0}};
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



















