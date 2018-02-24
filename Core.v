module Core (
	input wire clk,
	
	input wire [0:FRAME_SIZE] Fin_j,
	input wire Fin_j_valid,
	input wire [0:FRAME_SIZE] Fin_t,
	input wire Fin_t_valid,
	
	input wire confirm_from_tajny,
	input wire confirm_from_tajny_valid,
	
	input wire confirm_from_jawny,
	input wire confirm_from_jawny_valid,
	
	output wire [0:FRAME_SIZE] Fout_j,
	output wire Fout_j_valid,
	output wire [0:FRAME_SIZE] Fout_t,
	output wire Fout_t_valid,
	
	output reg confirm_tajny,
	output reg [7:0] confirm_code,
	output reg confirm_jawny
);


parameter DATA_SIZE = 64;
parameter PREAMBLE_SIZE = 7;
parameter CRC_SIZE = 4;
parameter FRAME_SIZE = (PREAMBLE_SIZE + DATA_SIZE + CRC_SIZE)*8-1;




reg [0:FRAME_SIZE] frame;
reg [0:FRAME_SIZE] frame_crc;


reg first;
reg confirm;
reg 	[0:31] 		lastFrameNr;
parameter [32:0] CRC_POLY = 33'h104c11db7;

reg fout_j_valid, fout_t_valid;
reg [1:0] which;

integer counter;
parameter [7:0]	IDLE 							= 8'b00000001,
						VALID_TYPE					= 8'b00000010,
						CRC_CHECK 					= 8'b00000100,
						RESET 						= 8'b00001000,
						FRAME_PROCESSED 			= 8'b00010000,
						HARD_RESET					= 8'b00100000,
						SIGN_ERROR					= 8'b01000000,
						PASS_FRAME					= 8'b10000000;
reg [7:0] state;
						
						
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


parameter [1:0] JAWNY = 2'b01;
parameter [1:0] TAJNY = 2'b10;

initial begin
	counter <= 0;
	frame <= {FRAME_SIZE+1{8'h00}};
	frame_crc <= {FRAME_SIZE+1{8'h00}};
	state <= IDLE;
	fout_j_valid <= 1'b0;
	fout_t_valid <= 1'b0;
	which <= 2'b00;
	first <= 1'b0;
	confirm <= 1'b1;
	confirm_code <= 8'h00;
	lastFrameNr 		<= {32{1'b0}};
end
						
						
always @ (posedge clk) begin
	case (state)
	
		IDLE: begin
			state <= VALID_TYPE;
			if (Fin_j_valid) begin
				frame <= Fin_j;
				frame_crc <= Fin_j;
				which <= JAWNY;
			end
			if (Fin_t_valid) begin
				frame <= Fin_t;
				frame_crc <= Fin_t;
				which <= TAJNY;
			end
		end
		
		VALID_TYPE: begin
		case (frame[0:7])
		
			FIRST_FRAME: begin
				if (first) begin // byla juz pierwsza
					confirm_code <= ERROR;
					confirm <= 1'b1;
					state <= SIGN_ERROR;
				end
				if (!first) begin
					state <= CRC_CHECK;
					lastFrameNr <= frame[24:55];
				end
			end
			
			NORMALNA: begin
				if (!first) begin
					confirm_code <= ERROR;
					confirm <= 1'b1;
					state <= SIGN_ERROR;
				end
				if (first) begin
					if (frame[24:55] == (lastFrameNr + 1)) begin
						state <= CRC_CHECK;
					end else begin
						confirm_code <= ERROR;
						confirm <= 1'b1;
						state <= SIGN_ERROR;
					end
				end
			end
			
			POJEDYNCZA: begin
				if (first) begin
					confirm_code <= ERROR;
					confirm <= 1'b1;
					state <= SIGN_ERROR;
				end
				if (!first) begin
					state <= CRC_CHECK;
				end
			end
			
			LAST_FRAME: begin
				if (!first) begin
					confirm_code <= ERROR;
					confirm <= 1'b1;
					state <= SIGN_ERROR;
				end
				if (first) begin
					if (frame[24:55] == (lastFrameNr + 1)) begin
						state <= CRC_CHECK;
						lastFrameNr <= {32{1'b0}};
					end
				end
			end
			
		endcase
		end
		
		CRC_CHECK: begin
//			if (counter <= (DATA_SIZE+7)*8-2 && frame_crc[counter] == 1'b1) begin
//				frame_crc <= (frame_crc[counter+:33] ^ CRC_POLY);
//			end
//			if (counter == (DATA_SIZE+7)*8-1) begin
//				if (frame_crc[((DATA_SIZE+7)*8-1)+:32] == 32'h00000000) begin


					state <= PASS_FRAME;
//					if (which == JAWNY) begin
//						fout_t_valid <= 1'b1;
//						state <= FRAME_PROCESSED;
//					end
//					if (which == TAJNY) begin
//						fout_j_valid <= 1'b1;
//						state <= FRAME_PROCESSED;
//					end
//				end
//			end
//			counter <= counter + 1;
		end
		
		PASS_FRAME: begin
			if (which == JAWNY) begin
				fout_t_valid <= 1'b1;
				state <= FRAME_PROCESSED;
			end
			if (which == TAJNY) begin
				fout_j_valid <= 1'b1;
				state <= FRAME_PROCESSED;
			end
		end
		
		FRAME_PROCESSED: begin
			case(which)
				TAJNY: begin
					if (confirm_from_jawny_valid) begin
						if (confirm_from_jawny == OKAY) begin
							confirm_code <= OKAY;
							confirm_tajny <= 1'b1;
							state <= RESET;
						end
						if (confirm_from_jawny == ERROR) begin
							state <= PASS_FRAME;
						end
						if (confirm_from_jawny == FATAL_ERROR) begin
							confirm_code <= FATAL_ERROR;
							confirm_tajny <= 1'b1;
							state <= HARD_RESET;
						end
					end
				end
				
				JAWNY: begin
					if (confirm_from_tajny_valid) begin
						if (confirm_from_tajny == OKAY) begin
							confirm_code <= OKAY;
							confirm_jawny <= 1'b1;
							state <= RESET;
						end
						if (confirm_from_tajny == ERROR) begin
							state <= PASS_FRAME;
						end
						if (confirm_from_tajny == FATAL_ERROR) begin
							confirm_code <= FATAL_ERROR;
							confirm_tajny <= 1'b1;
							state <= HARD_RESET;
						end
					end
				end
				
			endcase
		end
		
		SIGN_ERROR: begin
		case (which)
			JAWNY: begin
				confirm_jawny <= 1'b1;
				state <= RESET;
			end
			TAJNY: begin
				confirm_tajny <= 1'b1;
				state <= RESET;
			end
		endcase
		end
		
		HARD_RESET: begin
			counter <= 0;
			frame <= {FRAME_SIZE+1{1'b0}};
			frame_crc <= {FRAME_SIZE+1{1'b0}};
			state <= IDLE;
			fout_j_valid <= 1'b0;
			fout_t_valid <= 1'b0;
			which <= 2'b00;
			first <= 1'b0;
			confirm <= 1'b1;
			confirm_code <= 8'h00;
			lastFrameNr 		<= {32{1'b0}};
		end
		
		RESET: begin
			confirm <= 1'b0;
			counter <= 0;
			frame <= {FRAME_SIZE+1{1'b0}};
			frame_crc <= {FRAME_SIZE+1{1'b0}};
			state <= IDLE;
			fout_j_valid <= 1'b0;
			fout_t_valid <= 1'b0;
			which <= 2'b00;
			confirm_code <= 8'h00;
		end
		
		
	endcase
end

assign Fout_j = frame;
assign Fout_j_valid = fout_j_valid;

assign Fout_t = frame;
assign Fout_t_valid = fout_t_valid;

endmodule
