/*******************************************************************************
Function:
	An IP used ton control a seg7 array.
	

Parameters:
	s_address: index used to specfied seg7 unit, 0 means first seg7 unit
	s_writedata: 8 bits map to seg7 as beblow (1:on, 0:off)

      0
	------
	|    |
   5| 6  |1
	------
	|    |
   4|    |2
	------  . 7
      3
      
Map Array:
    unsigned char szMap[] = {
        63, 6, 91, 79, 102, 109, 125, 7, 
        127, 111, 119, 124, 57, 94, 121, 113
    };  // 0,1,2,....9, a, b, c, d, e, f      

Customization:
	SEG7_NUM: 
		specify the number of seg7 unit
		
	ADDR_WIDTH: 
		log2(SEG7_NUM)
		
	DEFAULT_ACTIVE: 
		1-> defualt to turn on all of segments, 
		0: turn off all of segements
		
	LOW_ACTIVE: 
		1->segment is low active, 
		0->segment is high active


******************************************************************************/


module SEG7_IF(	
					//===== avalon MM s1 slave (read/write)
					// write
					s_clk,
					s_address,
					s_read,
					s_readdata,
					s_write,
					s_writedata,
					s_reset,
					//

					//===== avalon MM s1 to export (read)
					// read/write
					SW,
					SEG7
				 );
				
/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/
parameter	SEG7_NUM		=   8;
parameter	ADDR_WIDTH		=	3;		
parameter	DEFAULT_ACTIVE  =   1;
parameter	LOW_ACTIVE  	=   1;

//`define 	SEG7_NUM		   8
//`define		ADDR_WIDTH		   3		
//`define		DEFAULT_ACTIVE     1
//`define		LOW_ACTIVE  	   1



/*****************************************************************************
 *                             Internal Wire/Register                         *
 *****************************************************************************/

reg		[7:0]				base_index;
reg		[7:0]				write_data;
reg		[7:0]				read_data;
//reg		[(SEG7_NUM*8-1):0]  reg_file;
wire            [47:0]  reg_file;
wire            [7:0]  temp_file[2:0]; 
reg             [7:0]  seg7_reg[7:0];   // 8*8-bit registers,   address: 0-7
reg				[15:0]	all_file;
reg 	        [7:0]   sw_reg;
reg             [15:0]  temp;
reg				[29:0]	count = 0;
reg				clk;
reg				[3:0] Ten_Thousands = 0;
reg				[3:0] Thousands = 0;
reg				[3:0] Hundreds = 0;
reg				[3:0] Tens = 0;
reg				[3:0] Ones = 0;
reg				[7:0] Ten_Thousands_temp = 0;
reg				[7:0] Thousands_temp = 0;
reg				[7:0] Hundreds_temp = 0;
reg				[7:0] Tens_temp = 0;
reg				[7:0] Ones_temp = 0;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
 // s1
input						s_clk;
input	[(ADDR_WIDTH-1):0]	s_address;
input						s_read;
output	[7:0]				s_readdata;
input						s_write;
input	[7:0]				s_writedata;
input						s_reset;

//===== Interface to export
 // s1
input     [7:0]     SW;
//output	[(SEG7_NUM*8-1):0]  SEG7;
output   [47:0]  SEG7;





/*****************************************************************************
 *                            Sequence logic                                  *
 *****************************************************************************/
 


always @ (negedge s_clk)
begin
	
	if (s_reset)
	begin
		integer i;
		for (i=0; i < 8; i=i+1)
		begin
		 	seg7_reg[i]=8'h00;
		end
	end
	else if (s_write)
	begin 
	    seg7_reg[s_address]=s_writedata;
	end
	else if (s_read)
	begin
		read_data= seg7_reg[s_address];
	end	
end

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/
assign temp_file[0] = seg7_reg[0];		//後一碼
assign temp_file[1] = seg7_reg[1];		//中兩碼
assign temp_file[2] = seg7_reg[2];		//前兩碼
assign reg_file = {Ten_Thousands_temp,Thousands_temp,Hundreds_temp,Tens_temp,Ones_temp};

always@(posedge s_clk) begin
	integer i;
	Ten_Thousands = 0;
	Thousands = 0;
	Hundreds = 0;
	Tens = 0;
	Ones = 0;
	all_file =  (temp_file[2] * 1000) + (temp_file[1] * 10) + temp_file[0];
	for (i=15;i>=0;i=i-1)
	begin
		if (Ten_Thousands >= 5)
			Ten_Thousands = Ten_Thousands + 3;
		if (Thousands >= 5)
			Thousands = Thousands + 3;
		if (Hundreds >= 5)
			Hundreds = Hundreds + 3;
		if (Tens >= 5)
			Tens = Tens + 3;
		if (Ones >= 5)
			Ones = Ones + 3;

		Ten_Thousands = Ten_Thousands << 1;
		Ten_Thousands[0] = Thousands[3];
		Thousands = Thousands << 1;
		Thousands[0] = Hundreds[3];
		Hundreds = Hundreds << 1;
		Hundreds[0] = Tens[3];
		Tens = Tens << 1;
		Tens[0] = Ones[3];
		Ones = Ones << 1;
		Ones[0] = all_file[i];

		
	end
	if (Ten_Thousands == 0)
		Ten_Thousands_temp = 8'h3F;
	if (Ten_Thousands == 1)
		Ten_Thousands_temp = 8'h06;
	if (Ten_Thousands == 2)
		Ten_Thousands_temp = 8'h5B;
	if (Ten_Thousands == 3)
		Ten_Thousands_temp = 8'h4F;
	if (Ten_Thousands == 4)
		Ten_Thousands_temp = 8'h66;
	if (Ten_Thousands == 5)
		Ten_Thousands_temp = 8'h6D;
	if (Ten_Thousands == 6)
		Ten_Thousands_temp = 8'h7D;
	if (Ten_Thousands == 7)
		Ten_Thousands_temp = 8'h07;
	if (Ten_Thousands == 8)
		Ten_Thousands_temp = 8'h7F;
	if (Ten_Thousands == 9)
		Ten_Thousands_temp = 8'h6F;




	if (Thousands == 0)
		Thousands_temp = 8'h3F;
	if (Thousands == 1)
		Thousands_temp = 8'h06;
	if (Thousands == 2)
		Thousands_temp = 8'h5B;
	if (Thousands == 3)
		Thousands_temp = 8'h4F;
	if (Thousands == 4)
		Thousands_temp = 8'h66;
	if (Thousands == 5)
		Thousands_temp = 8'h6D;
	if (Thousands == 6)
		Thousands_temp = 8'h7D;
	if (Thousands == 7)
		Thousands_temp = 8'h07;
	if (Thousands == 8)
		Thousands_temp = 8'h7F;
	if (Thousands == 9)
		Thousands_temp = 8'h6F;



	if (Hundreds == 0)
		Hundreds_temp = 8'h3F;
	if (Hundreds == 1)
		Hundreds_temp = 8'h06;
	if (Hundreds == 2)
		Hundreds_temp = 8'h5B;
	if (Hundreds == 3)
		Hundreds_temp = 8'h4F;
	if (Hundreds == 4)
		Hundreds_temp = 8'h66;
	if (Hundreds == 5)
		Hundreds_temp = 8'h6D;
	if (Hundreds == 6)
		Hundreds_temp = 8'h7D;
	if (Hundreds == 7)
		Hundreds_temp = 8'h07;
	if (Hundreds == 8)
		Hundreds_temp = 8'h7F;
	if (Hundreds == 9)
		Hundreds_temp = 8'h6F;



	if (Tens == 0)
		Tens_temp = 8'h3F;
	if (Tens == 1)
		Tens_temp = 8'h06;
	if (Tens == 2)
		Tens_temp = 8'h5B;
	if (Tens == 3)
		Tens_temp = 8'h4F;
	if (Tens == 4)
		Tens_temp = 8'h66;
	if (Tens == 5)
		Tens_temp = 8'h6D;
	if (Tens == 6)
		Tens_temp = 8'h7D;
	if (Tens == 7)
		Tens_temp = 8'h07;
	if (Tens == 8)
		Tens_temp = 8'h7F;
	if (Tens == 9)
		Tens_temp = 8'h6F;



	if (Ones == 0)
		Ones_temp = 8'h3F;
	if (Ones == 1)
		Ones_temp = 8'h06;
	if (Ones == 2)
		Ones_temp = 8'h5B;
	if (Ones == 3)
		Ones_temp = 8'h4F;
	if (Ones == 4)
		Ones_temp = 8'h66;
	if (Ones == 5)
		Ones_temp = 8'h6D;
	if (Ones == 6)
		Ones_temp = 8'h7D;
	if (Ones == 7)
		Ones_temp = 8'h07;
	if (Ones == 8)
		Ones_temp = 8'h7F;
	if (Ones == 9)
		Ones_temp = 8'h6F;
		

end

assign SEG7 = (LOW_ACTIVE)?~reg_file:reg_file;
assign s_readdata = read_data;


endmodule