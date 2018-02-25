module Core (
	input wire clk,
	
	input wire [0:FRAME_SIZE] 	Fin_j,
	input wire 						Fin_j_valid,
	input wire [0:FRAME_SIZE] 	Fin_t,
	input wire 						Fin_t_valid,
	
	input wire confirm_from_tajny,
	input wire confirm_from_tajny_valid,
	
	input wire confirm_from_jawny,
	input wire confirm_from_jawny_valid,
	
	output wire [0:FRAME_SIZE] Fout_j,
	output wire 					Fout_j_valid,
	output wire [0:FRAME_SIZE] Fout_t,
	output wire 					Fout_t_valid,
	
	output wire 			conf_tajny,
	output wire 			conf_jawny,
	output wire [7:0] 	conf_code,
	output wire diod1, diod2, diod3, diod4, diod5, diod6, diod7, diod8, diod9, diod10
	
);


parameter DATA_SIZE 		= 64;
parameter PREAMBLE_SIZE = 7;
parameter CRC_SIZE 		= 4;
parameter FRAME_SIZE 	= (PREAMBLE_SIZE + DATA_SIZE + CRC_SIZE)*8-1;

parameter [32:0] CRC_POLY = 33'h104c11db7;


reg [0:FRAME_SIZE] frame;
reg [0:FRAME_SIZE] frame_crc;

reg [0:31] 	lastFrameNr;
reg [1:0] 	which;
reg 			first;
reg 			fout_j_valid; 
reg			fout_t_valid;

reg confirm_jawny, confirm_tajny;
reg [7:0] 	confirm_code;

integer counter;




reg [8:0] state;
parameter [8:0]	IDLE 							= 9'b000000001,
						VALID_TYPE					= 9'b000000010,
						CRC_CHECK 					= 9'b000000100,
						RESET 						= 9'b000001000,
						FRAME_PROCESSED 			= 9'b000010000,
						HARD_RESET					= 9'b000100000,
						SIGN_ERROR					= 9'b001000000,
						PASS_FRAME					= 9'b010000000,
						WAIT_CLK						= 9'b100000000;        

						
						
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

reg dioda1, dioda2, dioda3, dioda4, dioda5, dioda6, dioda7, dioda8, dioda9, dioda10;

initial begin
	counter 			<= 0;
	frame 			<= {FRAME_SIZE+1{1'b0}};
	frame_crc 		<= {FRAME_SIZE+1{1'b0}};
	state 			<= IDLE;
	fout_j_valid 	<= 1'b0;
	fout_t_valid 	<= 1'b0;
	which 			<= 2'b00;
	first 			<= 1'b0;
	confirm_code 	<= 8'h00;
	lastFrameNr 	<= {32{1'b0}};
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
end

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
	case (state)
	
		IDLE: begin	
			if (Fin_j_valid) begin
				frame <= Fin_j;
				frame_crc <= Fin_j;
				which <= JAWNY;
				//confirm_code <= OKAY;
				//	confirm_jawny <= 1'b1;
				//	confirm_tajny <= 1'b1;
				//dioda <= 1'b1;
				state <= VALID_TYPE;
			end
			if (Fin_t_valid) begin
				frame <= Fin_t;
				frame_crc <= Fin_t;
				which <= TAJNY;
				//confirm_code <= OKAY;
				//	confirm_jawny <= 1'b1;
				//	confirm_tajny <= 1'b1;
				//dioda <= 1'b1;
				state <= VALID_TYPE;
			end
		end
		
		VALID_TYPE: begin
		case (frame[0:7])
		
			FIRST_FRAME: begin
				if (frame[0:7] == FIRST_FRAME) begin
					if (first) begin // byla juz pierwsza
						confirm_code <= ERROR;
						state <= SIGN_ERROR;
					end
					if (!first) begin
						confirm_jawny <= 1'b1;
						confirm_tajny <= 1'b1;
						//confirm_code <= OKAY;
						//state <= SIGN_ERROR;
						state <= CRC_CHECK;
						lastFrameNr <= frame[24:55];
						dioda1 <= 1'b1;
					end
				end
			end
			
			NORMALNA: begin
				if (!first) begin
					confirm_code <= ERROR;
					state <= SIGN_ERROR;
				end
				if (first) begin
					if (frame[24:55] == (lastFrameNr + 1)) begin
						state <= CRC_CHECK;
					end else begin
						confirm_code <= ERROR;
						state <= SIGN_ERROR;
					end
				end
			end
			
			POJEDYNCZA: begin
				if (first) begin
					confirm_code <= ERROR;
					state <= SIGN_ERROR;
				end
				if (!first) begin
					state <= CRC_CHECK;
				end
			end
			
			LAST_FRAME: begin
				if (!first) begin
					confirm_code <= ERROR;
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
					dioda2 <= 1'b1;
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
				dioda3 <= 1'b1;
				fout_t_valid <= 1'b1;
				state <= FRAME_PROCESSED;
			end
			if (which == TAJNY) begin
				dioda4 <= 1'b1;
				fout_j_valid <= 1'b1;
				state <= FRAME_PROCESSED;
			end
		end
		
		FRAME_PROCESSED: begin
			case(which)
				TAJNY: begin
					dioda5 <= 1'b1;
					if (confirm_from_jawny_valid) begin
						//dioda7 <= 1'b1;
						if (confirm_from_jawny == OKAY) begin
							confirm_code <= OKAY;
							confirm_tajny <= 1'b1;
							state <= SIGN_ERROR;
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
					//dioda6 <= 1'b1;
					if (confirm_from_tajny_valid) begin
					//dioda8 <= 1'b1;
						if (confirm_from_tajny == OKAY) begin
							confirm_code <= OKAY;
							confirm_jawny <= 1'b1;
							state <= SIGN_ERROR; // zamiast reset
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
		
		WAIT_CLK: begin
			state <= RESET;
		end
		
		SIGN_ERROR: begin
		case (which)
			JAWNY: begin
			dioda9 <= 1'b1;
				confirm_jawny <= 1'b1;
				state <= WAIT_CLK;		// zmienione z reseta
			end
			TAJNY: begin
			dioda10 <= 1'b1;
				confirm_tajny <= 1'b1;
				state <= WAIT_CLK;		// zmienione z reseta
			end	
		endcase
		end
		
		HARD_RESET: begin
			counter 			<= 0;
			frame 			<= {FRAME_SIZE+1{1'b0}};
			frame_crc 		<= {FRAME_SIZE+1{1'b0}};
			state 			<= IDLE;
			fout_j_valid 	<= 1'b0;
			fout_t_valid 	<= 1'b0;
			which 			<= 2'b00;
			first 			<= 1'b0;
			confirm_code 	<= 8'h00;
			lastFrameNr 	<= {32{1'b0}};
		end
		
		RESET: begin
			confirm_jawny	<=	1'b0;
			confirm_tajny	<=	1'b0;
			confirm_code	<= 8'h00;
			counter 			<= 0;
			frame				<= {FRAME_SIZE+1{1'b0}};
			frame_crc 		<= {FRAME_SIZE+1{1'b0}};
			state 			<= IDLE;
			fout_j_valid 	<= 1'b0;
			fout_t_valid 	<= 1'b0;
			which 			<= 2'b00;
			//confirm_code 	<= 8'h00;
		end
		
		
	endcase
end

assign conf_code = confirm_code;
assign conf_jawny = confirm_jawny;
assign conf_tajny = confirm_tajny;
assign Fout_j = frame;
assign Fout_j_valid = fout_j_valid;

assign Fout_t = frame;
assign Fout_t_valid = fout_t_valid;

endmodule
