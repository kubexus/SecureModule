module TopFPGA (

	input wire clk,
	
	input wire RX_JAWNY,
	input wire RX_TAJNY,
	
	output wire TX_JAWNY,
	output wire TX_TAJNY,
	
	output wire dioda1,dioda2,dioda3,dioda4,dioda5,dioda6
	
);


parameter NONCE_SIZE			= 12;
parameter DATA_SIZE 			= 64;
parameter PREAMBLE_SIZE 	= 7;
parameter CRC_SIZE 			= 4;

parameter INFO					=	PREAMBLE_SIZE + CRC_SIZE;
parameter FRAME_SIZE 		= 	PREAMBLE_SIZE + DATA_SIZE + CRC_SIZE;
parameter FRAME_SIZE_NONCE = 	PREAMBLE_SIZE + DATA_SIZE + CRC_SIZE + NONCE_SIZE;

// TYPY RAMEK
parameter [7:0]	FIRST_FRAME 		=	8'h10;
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


wire [0:FRAME_SIZE_NONCE*8-1] fout_j;
wire [0:FRAME_SIZE*8-1] fout_t;

wire fout_j_valid, fout_t_valid;

wire [0:FRAME_SIZE_NONCE*8-1] fin_j;
wire [0:FRAME_SIZE*8-1] fin_t;

wire fin_j_valid, fin_t_valid;

wire semafor_j, semafor_t;

wire [7:0] confirm_code, confirm_from_jawny, confirm_from_tajny;
wire confirm_from_PC_valid, confirm, confirm_from_tajny_valid, confirm_from_jawny_valid, confirm_jawny, confirm_tajny;

wire [95:0] nonce_aes;
wire [127:0] key_in;
wire [127:0] ciphertext_aes;

encrypter aes ( 
	.clock		(clk),     
   .reset      (res_aes),       
   .start      (start_aes),      
   .stop       (stop_aes),         
   .nonce      (nonce_aes),       
   .new_nonce 	(new_nonce),       
   .key       	(key_in),       
   .take      	(take_aes),      
   .ciphertext	(ciphertext_aes)

);

crc600 crc_check_600 (
	.clk		(clk),
	.rst		(rst_600),
	.crc_out	(crc_out600),
	.crc_en	(crc_en600),
	.data_in	(data_in600)
);

Interface #(
	.DATA_SIZE 			(DATA_SIZE ),
	.NONCE_SIZE			(NONCE_SIZE),
	.PREAMBLE_SIZE		(PREAMBLE_SIZE),
	.CRC_SIZE			(CRC_SIZE),
	.FRAME_START      (FRAME_START),
	.FRAME_END 	      (FRAME_END),
	.ESC_VAL 		   (ESC_VAL),
	.ESC_XOR 		   (ESC_XOR),
	.ERROR 		      (ERROR),
	.OKAY					(OKAY),
	.FIRST_FRAME      (FIRST_FRAME),
	.LAST_FRAME 	   (LAST_FRAME)) 
	
	JAWNY (
		.clk							(clk),
		.RX							(RX_JAWNY),
		.semafor_in					(semafor_t),
		.fin							(fin_j),
		.diod1						(dioda5),
		.diod2						(dioda6),
		.confirm						(confirm_jawny),
		.fin_valid					(fin_j_valid),
		.conf_code					(confirm_code),
		.conf_from_PC			(confirm_from_jawny),
		.conf_from_PC_valid	(confirm_from_jawny_valid),
		.fout							(fout_j),
		.fout_valid					(fout_j_valid),    
	   .TX							(TX_JAWNY),
      .semafor_out				(semafor_j)
		//.diod1						(dioda1),
		//.diod2						(dioda2),
		//.diod3						(dioda3)
		);

Interface #(
	.DATA_SIZE 			(DATA_SIZE),
	.PREAMBLE_SIZE		(PREAMBLE_SIZE),
	.CRC_SIZE			(CRC_SIZE),
	.NONCE_SIZE			(0),
	.FRAME_START      (FRAME_START),
	.FRAME_END 	      (FRAME_END),
	.ESC_VAL 		   (ESC_VAL),
	.ESC_XOR 		   (ESC_XOR),
	.OKAY					(OKAY),
	.ERROR 		      (ERROR),
	.FIRST_FRAME      (FIRST_FRAME),
	.LAST_FRAME 	   (LAST_FRAME)) 
	
	TAJNY (
		.clk							(clk),
		.RX							(RX_TAJNY),
		.semafor_in					(semafor_j),
		.fin							(fin_t),
		.diod3						(dioda4),
		.fin_valid					(fin_t_valid),
		.confirm						(confirm_tajny),
		.conf_code					(confirm_code),
		.conf_from_PC				(confirm_from_tajny),
		.conf_from_PC_valid		(confirm_from_tajny_valid),
		.fout							(fout_t),
		.fout_valid					(fout_t_valid),
	   .TX							(TX_TAJNY),
      .semafor_out				(semafor_t));	
	
Core # (
	.DATA_SIZE 			(DATA_SIZE),
	.PREAMBLE_SIZE		(PREAMBLE_SIZE),
	.CRC_SIZE			(CRC_SIZE),
	.NONCE_SIZE			(NONCE_SIZE),
	.FRAME_START      (FRAME_START),
	.FRAME_END 	      (FRAME_END),
	.ESC_VAL 		   (ESC_VAL),
	.ESC_XOR 		   (ESC_XOR),
	.ERROR 		      (ERROR),
	.OKAY					(OKAY),
	.FIRST_FRAME      (FIRST_FRAME),
	.LAST_FRAME 	   (LAST_FRAME)) 

	serce (
		//.crc600in						(data_in600),
		//.crc_en600						(crc_en600),
		//.rst600							(rst_600),
		//.crc600_din						(data_in600),
		.clk								(clk),
		.Fin_j							(fout_j),
		.Fin_j_valid					(fout_j_valid),
		.Fin_t							(fout_t),
		.Fin_t_valid					(fout_t_valid),
		.confirm_from_tajny  		(confirm_from_tajny),
		.confirm_from_tajny_valid	(confirm_from_tajny_valid),
		.confirm_from_jawny			(confirm_from_jawny),
		.confirm_from_jawny_valid 	(confirm_from_jawny_valid),
		
		/////// aes //////
		     
		.res_aes									(res_aes),      
		.start_aes                           (start_aes),    
		.stop_aes                          (stop_aes),     
		.nonce_aes                          (nonce_aes),    
		.new_nonce                           (new_nonce),    
		.key_in                           (key_in),       
		.take_aes                           (take_aes),     
		.ciphertext_aes                           (ciphertext_aes),
		//////////////
		
		.conf_jawny			(confirm_jawny),
		.conf_tajny			(confirm_tajny),
		.conf_code			(confirm_code),
		.Fout_j					(fin_j),
		.Fout_j_valid			(fin_j_valid),
		.Fout_t					(fin_t),
		.Fout_t_valid			(fin_t_valid),
		
		.diod1						(dioda1),
		.diod2						(dioda2),
		.diod3						(dioda3)

		
		);
	

endmodule
