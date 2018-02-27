module Core (
	input wire clk,
	
	input wire [0:FRAME_SIZE_NONCE*8-1] 	Fin_j,
	input wire 						Fin_j_valid,
	input wire [0:FRAME_SIZE*8-1] 	Fin_t,
	input wire 						Fin_t_valid,
	
	input wire [7:0]				confirm_from_tajny,
	input wire 						confirm_from_tajny_valid,
	
	input wire [7:0]				confirm_from_jawny,
	input wire 						confirm_from_jawny_valid,
	
	////// aes///////////
	output wire res_aes	,		
	output wire start_aes   ,  
	output wire stop_aes   ,   
	output wire [95:0] nonce_aes ,    
	output wire new_nonce ,    
	output wire [127:0] key_in ,
	
	input wire take_aes  ,    
	input wire [127:0] ciphertext_aes,
	
	
	
	
	//////////////////////
	input wire [31:0] crc600in,
	

	output reg rst600,
	output wire [FRAME_SIZE*8-1:0] crc600_din,
	
	output wire [0:FRAME_SIZE_NONCE*8-1] Fout_j,
	output wire 					Fout_j_valid,
	output wire [0:FRAME_SIZE*8-1] Fout_t,
	output wire 					Fout_t_valid,
	
	output wire 					conf_tajny,
	output wire 					conf_jawny,
	output wire [7:0] 			conf_code,
	output wire	diod1, diod2, diod3, diod4, diod5, diod6, diod7, diod8, diod9, diod10
	
);

assign crc600_din = frame_t;

parameter NONCE_SIZE			= 0;
parameter DATA_SIZE 			= 0;
parameter PREAMBLE_SIZE 	= 0;
parameter CRC_SIZE 			= 0;

parameter INFO					=	PREAMBLE_SIZE 	+ CRC_SIZE;
parameter FRAME_SIZE 		= 	PREAMBLE_SIZE+DATA_SIZE+CRC_SIZE;
parameter FRAME_SIZE_NONCE = 	PREAMBLE_SIZE+NONCE_SIZE+DATA_SIZE+CRC_SIZE;

reg [127:0] key1, key2;

parameter [32:0] CRC_POLY = 33'h104c11db7;

///////
reg res_aes_w;		
reg start_aes_w; 
reg stop_aes_w;  
reg [95:0] nonce_aes_w;    
reg new_nonce_w;    
reg [127:0] key_in_w;
///////
assign res_aes = res_aes_w;
assign start_aes = start_aes_w;
assign stop_aes = stop_aes_w;
assign nonce_aes = nonce_aes_w;
assign new_nonce = new_nonce_w;
assign key_in = key_in_w;
reg [0:7] typ;
reg [0:7] IDo;
reg [0:7] IDn;
reg [0:31] Nr_Fr;
reg [0:95] nonce;

reg [0:DATA_SIZE*8-1] data;
reg [0:31] crc;

wire [0:FRAME_SIZE*8-1] frame_t;
wire [0:FRAME_SIZE_NONCE*8-1] frame_j;

assign frame_t = {typ,IDo,IDn,Nr_Fr,data,crc};
assign frame_j = {typ,IDo,IDn,Nr_Fr,nonce,data,crc};

reg [0:FRAME_SIZE*8-1] frame;
reg [0:FRAME_SIZE*8-1] frame_crc;



reg [0:31] 	lastFrameNr;
reg [1:0] 	which;
reg 			first;
reg 			fout_j_valid; 
reg			fout_t_valid;

reg confirm_jawny, confirm_tajny;
reg [7:0] 	confirm_code;

integer counter;
integer count_clk;

reg [10:0] state;
parameter [10:0]	IDLE 							= 11'b00000000001,
						VALID_TYPE					= 11'b00000000010,
						CRC_CHECK 					= 11'b00000000100,
						RESET 						= 11'b00000001000,
						FRAME_PROCESSED 			= 11'b00000010000,
						HARD_RESET					= 11'b00000100000,
						SIGN_ERROR					= 11'b00001000000,
						PASS_FRAME					= 11'b00010000000,
						WAIT_CLK						= 11'b00100000000,
						WAIT_TX						= 11'b01000000000,
						ENCRYPT						= 11'b10000000000;            
						
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
reg fat_err;
integer licz;
assign diod1 = dioda3;
assign diod2 = dioda4;
assign diod3 = dioda5;

reg [127:0] ciph;

integer count_aes;

initial begin
	typ				<= 8'h00;
	IDo				<= 8'h00;
	IDn				<= 8'h00;
	Nr_Fr				<= {32{1'b0}};
	nonce				<= {12{8'hff}};
	data				<= {DATA_SIZE*8{1'b0}};
	crc				<= {32{1'b0}};
	count_aes		<= 0;
	key1				<= {128{1'b0}};
	key2				<= {128{1'b1}};
	counter 			<= 0;
	frame 			<= {FRAME_SIZE_NONCE*8{1'b0}};
	frame_crc 		<= {FRAME_SIZE_NONCE*8{1'b0}};
	state 			<= IDLE;
	fout_j_valid 	<= 1'b0;
	fout_t_valid 	<= 1'b0;
	which 			<= 2'b00;
	first 			<= 1'b0;
	licz <= 0;
	confirm_code 	<= 8'h00;
	lastFrameNr 	<= {32{1'b0}};
	fat_err			<=	1'b0;
	//nonce				<= {96{1'b0}};
	count_clk		<= 0;
	dioda1 <= 1'b0;
	dioda2 <= 1'b0;
	dioda3 <= 1'b0;
	dioda4 <= 1'b0;
	dioda5 <= 1'b0;
	dioda6 <= 1'b0;
	dioda7 <= 1'b0;
	dioda8 <= 1'b0;
	dioda9 <= 1'b0;
	dioda10 <= 1'b0;
	//dioda5 <= 1'b0;
	//dioda6 <= 1'b0;
end

//assign diod1 = dioda1;
//assign diod2 = dioda2;
//assign diod3 = dioda3;						
						
always @ (posedge clk) begin
	case (state)
	
		IDLE: begin	
			if (Fin_j_valid) begin
				//frame <= {Fin_j[0:55],Fin_j[152:FRAME_SIZE*8-1]};
				//nonce <= Fin_j[56:151];
				typ	<=	Fin_j[0:7];
				IDo	<= Fin_j[8:15];
				IDn	<= Fin_j[16:23];
				Nr_Fr <= Fin_j[24:55];
				nonce <= Fin_j[56:151];
				data  <= Fin_j[152:FRAME_SIZE_NONCE*8-33];
				crc	<= Fin_j[FRAME_SIZE_NONCE*8-32:FRAME_SIZE_NONCE*8-1];
				which <= JAWNY;
				state <= VALID_TYPE;
			end
			if (Fin_t_valid) begin
				typ	<=	Fin_t[0:7];
				IDo	<= Fin_t[8:15];
				IDn	<= Fin_t[16:23];
				Nr_Fr <= Fin_t[24:55];
				data  <= Fin_t[56:FRAME_SIZE*8-33];
				crc	<= Fin_t[FRAME_SIZE*8-32:FRAME_SIZE*8-1];
				which <= TAJNY;
				state <= VALID_TYPE;
			end
		end
		
		VALID_TYPE: begin
		
		count_aes <= 0;
		case (typ)
		
			FIRST_FRAME: begin
				if (first) begin // byla juz pierwsza
					confirm_code <= ERROR;
					state <= SIGN_ERROR;
				end
				if (!first) begin
					//confirm_jawny <= 1'b1;
					//confirm_tajny <= 1'b1;
					//confirm_code <= OKAY;
					//state <= SIGN_ERROR;
					first <= 1'b1;
					state <= CRC_CHECK;
					lastFrameNr <= Nr_Fr;
					//dioda1 <= 1'b1;
				end
			end
			
			NORMALNA: begin
				if (!first) begin
					confirm_code <= ERROR;
					state <= SIGN_ERROR;
				end
				if (first) begin
					if (Nr_Fr == (lastFrameNr + 1)) begin
						state <= CRC_CHECK;
						lastFrameNr <= lastFrameNr + 1;
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
					if (Nr_Fr == (lastFrameNr + 1)) begin
						state <= CRC_CHECK;
						lastFrameNr <= {32{1'b0}};
						first <= 1'b0;
					end
				end
			end
			
		endcase
		end
		
		CRC_CHECK: begin	
					state <= ENCRYPT;
		end
		
		ENCRYPT: begin
			count_aes <= count_aes + 1;
			if (count_aes == 0) begin
				res_aes_w <= 1'b1;
				nonce_aes_w <= nonce;
				if (IDo == 8'h00) begin
					key_in_w <= key1;
				end
				if (IDo == 8'h01) begin
					key_in_w <= key2;
				end
			end
			if (count_aes == 1) begin
				res_aes_w <= 1'b0;
			end
			if (count_aes == 2) begin
				start_aes_w <= 1'b1;
			end
			if (count_aes > 2 ) begin
				if (take_aes) begin
					dioda3 <= 1'b1;
					//ciph <= ciphertext_aes;
					data[0:127] <= data[0:127] ^ ciphertext_aes[127:0];
					state <= PASS_FRAME;
				end
			end
		end
		
		PASS_FRAME: begin
			count_clk <= 0;
			if (which == JAWNY) begin
				//dioda3 <= 1'b1;
				fout_t_valid <= 1'b1;
				state <= FRAME_PROCESSED;
			end
			if (which == TAJNY) begin
				fout_j_valid <= 1'b1;
				state <= FRAME_PROCESSED;
			end
		end
		
		WAIT_TX: begin
			if (count_clk == 450) begin // bylo 1000
				if (fat_err) begin
					state <= HARD_RESET;
				end else begin
					state <= PASS_FRAME;
				end
			end
			count_clk <= count_clk + 1;
		end
		
		FRAME_PROCESSED: begin
			fout_t_valid <= 1'b0;
			fout_j_valid <= 1'b0;
			case(which)
				TAJNY: begin
					if (confirm_from_jawny_valid) begin
					//dioda8 <= 1'b1;
					dioda3 <= 1'b1;
						if (confirm_from_jawny == OKAY) begin
							if (typ == LAST_FRAME) begin
								confirm_code <= OKAY ^ 8'h10;
							end else begin
								confirm_code <= OKAY;
								//dioda4 <= 1'b1;
							end
							confirm_tajny <= 1'b1;
							state <= SIGN_ERROR; // zamiast reset
						end
						if (confirm_from_tajny == ERROR) begin
							state <= PASS_FRAME;
						end
						if (confirm_from_tajny == FATAL_ERROR) begin
							confirm_code <= FATAL_ERROR;
							confirm_tajny <= 1'b1;
							state <= SIGN_ERROR;
						end
					end
				end
				
				JAWNY: begin
					//dioda6 <= 1'b1;
					if (confirm_from_tajny_valid) begin
					//dioda8 <= 1'b1;
						if (confirm_from_tajny == OKAY) begin
							if (typ == LAST_FRAME) begin
								confirm_code <= OKAY ^ 8'h10;
							end else begin
								confirm_code <= OKAY;
							end
							confirm_jawny <= 1'b1;
							state <= SIGN_ERROR; // zamiast reset
						end
						if (confirm_from_tajny == ERROR) begin
							state <= PASS_FRAME;
						end
						if (confirm_from_tajny == FATAL_ERROR) begin
							confirm_code <= FATAL_ERROR;
							confirm_jawny <= 1'b1;
							state <= SIGN_ERROR;
						end
					end
				end
			endcase
		end
		
		WAIT_CLK: begin
			if (licz >= 5) begin
				state <= RESET;
			end
			licz <= licz + 1;
			end
		
		SIGN_ERROR: begin
		dioda5 <= 1'b1;
		case (which)
			JAWNY: begin
			//dioda9 <= 1'b1;
				confirm_jawny <= 1'b1;
				state <= WAIT_CLK;		// zmienione z reseta
			end
			TAJNY: begin
			//dioda10 <= 1'b1;
				confirm_tajny <= 1'b1;
				state <= WAIT_CLK;		// zmienione z reseta
			end	
		endcase
		end
		
		HARD_RESET: begin
			typ				<= 8'h00;
	IDo				<= 8'h00;
	IDn				<= 8'h00;
	Nr_Fr				<= {32{1'b0}};
	nonce				<= {12{8'h66}};
	data				<= {DATA_SIZE*8{1'b0}};
	crc				<= {32{1'b0}};
	licz <= 0;
			counter 			<= 0;
			frame 			<= {FRAME_SIZE_NONCE*8{1'b0}};
			frame_crc 		<= {FRAME_SIZE_NONCE*8{1'b0}};
			state 			<= IDLE;
			fout_j_valid 	<= 1'b0;
			fout_t_valid 	<= 1'b0;
			count_aes		<= 0;
			which 			<= 2'b00;
			first 			<= 1'b0;
			confirm_code 	<= 8'h00;
			lastFrameNr 	<= {32{1'b0}};
			fat_err			<=	1'b0;
			nonce				<= {12{8'hff}};
		end
		
		RESET: begin
			licz <= 0;
			typ				<= 8'h00;
			IDo				<= 8'h00;
			IDn				<= 8'h00;
			Nr_Fr				<= {32{1'b0}};
			nonce				<= {12{8'hff}};
			data				<= {DATA_SIZE*8{1'b0}};
			crc				<= {32{1'b0}};
			count_clk		<= 0;
			count_aes		<= 0;
			confirm_jawny	<=	1'b0;
			confirm_tajny	<=	1'b0;
			confirm_code	<= 8'h00;
			counter 			<= 0;
			frame				<= {FRAME_SIZE_NONCE*8{1'b0}};
			frame_crc 		<= {FRAME_SIZE_NONCE*8{1'b0}};
			state 			<= IDLE;
			fout_j_valid 	<= 1'b0;
			fout_t_valid 	<= 1'b0;
			which 			<= 2'b00;
			nonce				<= {12{8'h66}};
		end
		
		
	endcase
end

assign conf_code = confirm_code;
assign conf_jawny = confirm_jawny;
assign conf_tajny = confirm_tajny;
assign Fout_j = frame_j;
assign Fout_j_valid = fout_j_valid;

assign Fout_t = frame_t;
assign Fout_t_valid = fout_t_valid;

endmodule
