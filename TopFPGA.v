module TopFPGA (

	input wire clk,
	
	input wire RX_JAWNY,
	input wire RX_TAJNY,
	
	output wire TX_JAWNY,
	output wire TX_TAJNY,
	
	output wire dioda1, dioda2, dioda3, dioda4, dioda5, dioda6, dioda7, dioda8, dioda9, dioda10
	
);

parameter NONCE_SIZE			= 12;
parameter DATA_SIZE 			= 64;
parameter PREAMBLE_SIZE 	= 7;
parameter CRC_SIZE 			= 4;

parameter FRAME_SIZE = (PREAMBLE_SIZE + DATA_SIZE + CRC_SIZE + NONCE_SIZE)*8-1;

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


wire [0:FRAME_SIZE] fout_j, fout_t;
wire fout_j_valid, fout_t_valid;

wire [0:FRAME_SIZE] fin_j, fin_t;
wire fin_j_valid, fin_t_valid;

wire semafor_j, semafor_t;

wire [7:0] confirm_code, confirm_from_jawny, confirm_from_tajny;
wire confirm_from_PC_valid, confirm, confirm_from_tajny_valid, confirm_from_jawny_valid, confirm_jawny, confirm_tajny;



//wire aes_reset, aes_start, aes_take;

//wire [95:0] aes_nonce;
//wire [127:0] aes_stream;
//wire [1:0] select_key;

//encrypter AES (
//	.clock				(clk),confirm_code
//	.reset				(aes_reset),
//	.start				(aes_start),
//	.nonce				(aes_nonce),
//	.sel					(select_key),
//	.take					(aes_take),
//	.ciphertext			(aes_stream)
//);



CRC_CHECK crc (

	.data_in			(din_crc)	,
   .crc_en			(crc_en)		,
   .crc_out			(dout_crc)	,
   .rst   			(res_crc)	,
   .clk    			(clk)

);


Interface #(
	.DATA_SIZE 			(DATA_SIZE),
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
		.confirm						(confirm_jawny),
		.fin_valid					(fin_j_valid),
		.conf_code					(confirm_code),
		.conf_from_PC			(confirm_from_jawny),
		.conf_from_PC_valid	(confirm_from_jawny_valid),
		.fout							(fout_j),
		.fout_valid					(fout_j_valid),    
	   .TX							(TX_JAWNY),
      .semafor_out				(semafor_j),
		.diod1					(dioda1),
		.diod2					(dioda2),
		.diod3					(dioda3),
		.diod4					(dioda4),
		.diod5					(dioda5),
		.diod6					(dioda6),
		.diod7					(dioda7),
		.diod8					(dioda8),
		.diod9					(dioda9),
		.diod10					(dioda10)	
		);

Interface #(
	.DATA_SIZE 			(DATA_SIZE),
	.NONCE_SIZE			(NONCE_SIZE),
	.PREAMBLE_SIZE		(PREAMBLE_SIZE),
	.CRC_SIZE			(CRC_SIZE),
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

	serce (
		.clk								(clk),
		.Fin_j							(fout_j),
		.Fin_j_valid					(fout_j_valid),
		.Fin_t							(fout_t),
		.Fin_t_valid					(fout_t_valid),
		.confirm_from_tajny  		(confirm_from_tajny),
		.confirm_from_tajny_valid	(confirm_from_tajny_valid),
		.confirm_from_jawny			(confirm_from_jawny),
		.confirm_from_jawny_valid 	(confirm_from_jawny_valid),
		
		.conf_jawny			(confirm_jawny),
		.conf_tajny			(confirm_tajny),
		.conf_code			(confirm_code),
		.Fout_j					(fin_j),
		.Fout_j_valid			(fin_j_valid),
		.Fout_t					(fin_t),
		.Fout_t_valid			(fin_t_valid)
//		.diod1					(dioda1),
//		.diod2					(dioda2),
//		.diod3					(dioda3),
//		.diod4					(dioda4),
//		.diod5					(dioda5),
//		.diod6					(dioda6),
//		.diod7					(dioda7),
//		.diod8					(dioda8),
//		.diod9					(dioda9),
//		.diod10					(dioda10),
		
		);
	

endmodule
