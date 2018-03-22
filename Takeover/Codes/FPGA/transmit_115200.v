`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Kitakyushu-Kosen
// Engineer: 
// 
// Create Date:    15:45:42 11/24/2016 
// Design Name: 
// Module Name:    transmit_115200.v
// Project Name: 
// Target Devices: Spartan-3A Starter Kit
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:  
//   ���M�@�@
//   �������O�̐M���̓{�[�h��LED�ɕ\��
//   kill = 1'b�@�ɂȂ�ƃV�X�e������~����d�l�Ȃ̂Œ���   
//        
//////////////////////////////////////////////////////////////////////////////////

module rx_115200(CLK_50M, RS232_DCE_RXD, RS232_DTE_TXD, LED);

	input CLK_50M;
	input RS232_DCE_RXD;
	output RS232_DTE_TXD;
	output [7:0] LED;

	wire rxd;
	assign rxd = RS232_DCE_RXD;
	reg txd_out = 1'b1;
	assign RS232_DTE_TXD = txd_out;

	reg [7:0] led_out;
	assign LED = led_out;
	
	reg [15:0] b4_clock_count = 0;
	reg [15:0] b5_clock_count = 0;
	
	reg b4_clk = 1'b1;
	reg b5_clk = 1'b1;
	reg b4_clk_old;
	reg b5_clk_old;

	reg receiving = 1'b0;
	reg sending   = 1'b0;
	
	reg [8:0] buffer  = 9'b11111_1111;
	reg [11:0] encode = 12'b11111_11111_11;
	reg [3:0] send_count = 0;

	reg kill = 1'b0;
	

always @(posedge CLK_50M)
begin
	
	//�ُ킪�������Ƃ��V�X�e����������~
	if(kill == 1'b1)
	begin
	end
	
	
	else if(receiving == 1'b1) //�X�^�[�g�r�b�g���o������4b���N���b�N�J�n
	begin		
		if (b4_clock_count < 271) //�{�[���[�g 115200:271, 9600:3255   (*0.625)
		begin
			b4_clk <= 1'b1;
			b4_clock_count <= b4_clock_count + 1;
		end
		else if (b4_clock_count < 434) //�{�[���[�g 115200:434, 9600:5208
		begin
			b4_clk <= 1'b0;
			b4_clock_count <= b4_clock_count + 1;
		end
		else
		begin
			b4_clock_count <= 0;
		end
	end
	else
	begin
		b4_clock_count <= 0;
		b4_clk <= 1'b0;
	end

		
	//5b���N���b�N ������5/6�{�ɂȂ�
	if(sending == 1)
	begin
		if (b5_clock_count < 224) //�{�[���[�g 115200:224, 9600:2691    (*0.62)
		begin
			//5b���͂����Ȃ�M���𗧂�����
			b5_clk <= 1'b0;
			b5_clock_count <= b5_clock_count + 1;
		end
		else if (b5_clock_count < 361) //�{�[���[�g 115200:361, 9600:4340
		begin
			b5_clk <= 1'b1;
			b5_clock_count <= b5_clock_count + 1;
		end
		else
		begin
			b5_clock_count <= 0;
		end
	end
	else
	begin
		b5_clock_count <= 0;
		b5_clk         <= 1'b1;
	end
	
end

always @(negedge CLK_50M)
begin

	b4_clk_old <= b4_clk;
	b5_clk_old <= b5_clk;
	
	if(rxd == 1'b0) //�X�^�[�g�r�b�g�̌��m�A4b�N���b�N�J�n�̍��}
	begin
		receiving <= 1'b1;
	end
	
	if ((b5_clk_old == 1'b1) && (b5_clk == 1'b0))
	begin
		//buffer�֎�M�M���̊i�[���I����Ă�����A�X�^�[�g�r�b�g��buffer[0]�ɗ���
		txd_out      <= encode[0];
		encode[10:0] <= encode[11:1];
		encode[11]   <= 1'b1;
		send_count    <= send_count + 1;
		if(send_count == 4'b1011)
		begin
			send_count    <= 0;
			sending <= 1'b0;
		end
	end
	
	//b4_clk����������������ȉ������s
	if ((b4_clk_old == 1'b1) && (b4_clk == 1'b0))
	begin
		// start bit��buffer[9]�܂ŗ��Ĉȍ~�̓p���e�B�`�F�b�N����(������)
		//if (receiving)
		//	parity <= parity ^ buffer[9];
		
		// start bit��buffer[9]�܂ŗ����Ƃ��i�A�C�h�����͐M��"1"�A�X�^�[�g��"0"����M����j
		//else if (buffer[9] == 1'b0)
		//begin
		//	parity    <= 1'b0;
		//	receiving <= 1'b1;
		//end
		
		////////////////
		//�X�^�[�g�r�b�g��buffer[0]�ɂ�����
		if(buffer[0] == 1'b0)
		begin
			
			//////////////////////////
			//�ُ�F�V�X�e�����~			//
			if(sending == 1'b1) //�M��������I����ĂȂ��̂Ɏ��̐M������M�����ꍇ
			begin
				led_out[7:0] <= 8'b1010_1010;
				kill <= 1'b1;
			end
			
			else if(rxd != 1'b1) //�X�g�b�v�r�b�g�����o�ł��Ă��Ȃ��ꍇbuffer�j��(�r�b�g���[�g�̐ݒ��莞�ɋN���₷��)
			begin
				led_out[7:0] <= 8'b1011_1011;
				buffer[8:0] <= 9'b11111_1111; 
				receiving <= 0;
				//kill <= 1'b1;  //���̃G���[�������V�X�e�����~�������ꍇ�͂��̍s�̃R�����g���O��
			end				
				
			/////////////////////////////////
			//����F��M�̏I���ƐM�����M����		//
			else
			begin
			case(buffer[4:1])
				4'b0000 : encode[5:1] <= 5'b11110;
				4'b0001 : encode[5:1] <= 5'b01001;
				4'b0010 : encode[5:1] <= 5'b10100;
				4'b0011 : encode[5:1] <= 5'b10101;
				4'b0100 : encode[5:1] <= 5'b01010;
				4'b0101 : encode[5:1] <= 5'b01011;
				4'b0110 : encode[5:1] <= 5'b01110;
				4'b0111 : encode[5:1] <= 5'b01111;
				4'b1000 : encode[5:1] <= 5'b10010;
				4'b1001 : encode[5:1] <= 5'b10011;
				4'b1010 : encode[5:1] <= 5'b10110;
				4'b1011 : encode[5:1] <= 5'b10111;
				4'b1100 : encode[5:1] <= 5'b11010;
				4'b1101 : encode[5:1] <= 5'b11011;
				4'b1110 : encode[5:1] <= 5'b11100;
				4'b1111 : encode[5:1] <= 5'b11101;
				default : kill <= 1'b1;
			endcase
			case(buffer[8:5])
				4'b0000 : encode[10:6] <= 5'b11110;
				4'b0001 : encode[10:6] <= 5'b01001;
				4'b0010 : encode[10:6] <= 5'b10100;
				4'b0011 : encode[10:6] <= 5'b10101;
				4'b0100 : encode[10:6] <= 5'b01010;
				4'b0101 : encode[10:6] <= 5'b01011;
				4'b0110 : encode[10:6] <= 5'b01110;
				4'b0111 : encode[10:6] <= 5'b01111;
				4'b1000 : encode[10:6] <= 5'b10010;
				4'b1001 : encode[10:6] <= 5'b10011;
				4'b1010 : encode[10:6] <= 5'b10110;
				4'b1011 : encode[10:6] <= 5'b10111;
				4'b1101 : encode[10:6] <= 5'b11011;
				4'b1100 : encode[10:6] <= 5'b11010;
				4'b1110 : encode[10:6] <= 5'b11100;
				4'b1111 : encode[10:6] <= 5'b11101;
				default : kill <= 1'b1;
			endcase
			led_out[7:0] <= buffer[8:1];
			encode[0]    <= 1'b0;
			encode[11]   <= 1'b1;
			buffer[8:0]  <= 9'b11111_1111;
			sending      <= 1'b1;
			receiving    <= 1'b0;
			end
		end
		else
		begin
				//��M�M����buffer�ɂǂ�ǂ�i�[���Ă���
			buffer[7:0] <= buffer[8:1];
			buffer[8]   <= rxd;
		end
	end
end

endmodule
