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
//   送信機　
//   符号化前の信号はボード上LEDに表示
//   kill = 1'b　になるとシステムが停止する仕様なので注意   
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
	
	//異常があったときシステムを強制停止
	if(kill == 1'b1)
	begin
	end
	
	
	else if(receiving == 1'b1) //スタートビット検出したら4b側クロック開始
	begin		
		if (b4_clock_count < 271) //ボーレート 115200:271, 9600:3255   (*0.625)
		begin
			b4_clk <= 1'b1;
			b4_clock_count <= b4_clock_count + 1;
		end
		else if (b4_clock_count < 434) //ボーレート 115200:434, 9600:5208
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

		
	//5b側クロック 周期は5/6倍になる
	if(sending == 1)
	begin
		if (b5_clock_count < 224) //ボーレート 115200:224, 9600:2691    (*0.62)
		begin
			//5b側はいきなり信号を立ち下げ
			b5_clk <= 1'b0;
			b5_clock_count <= b5_clock_count + 1;
		end
		else if (b5_clock_count < 361) //ボーレート 115200:361, 9600:4340
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
	
	if(rxd == 1'b0) //スタートビットの検知、4bクロック開始の合図
	begin
		receiving <= 1'b1;
	end
	
	if ((b5_clk_old == 1'b1) && (b5_clk == 1'b0))
	begin
		//bufferへ受信信号の格納が終わっていたら、スタートビットがbuffer[0]に来る
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
	
	//b4_clkが立ち下がったら以下を実行
	if ((b4_clk_old == 1'b1) && (b4_clk == 1'b0))
	begin
		// start bitがbuffer[9]まで来て以降はパリティチェックする(未実装)
		//if (receiving)
		//	parity <= parity ^ buffer[9];
		
		// start bitがbuffer[9]まで来たとき（アイドル時は信号"1"、スタートは"0"を受信する）
		//else if (buffer[9] == 1'b0)
		//begin
		//	parity    <= 1'b0;
		//	receiving <= 1'b1;
		//end
		
		////////////////
		//スタートビットがbuffer[0]にきたら
		if(buffer[0] == 1'b0)
		begin
			
			//////////////////////////
			//異常：システムを停止			//
			if(sending == 1'b1) //信号が送り終わってないのに次の信号を受信した場合
			begin
				led_out[7:0] <= 8'b1010_1010;
				kill <= 1'b1;
			end
			
			else if(rxd != 1'b1) //ストップビットが検出できていない場合buffer破棄(ビットレートの設定誤り時に起きやすい)
			begin
				led_out[7:0] <= 8'b1011_1011;
				buffer[8:0] <= 9'b11111_1111; 
				receiving <= 0;
				//kill <= 1'b1;  //このエラー発生時システムを停止したい場合はこの行のコメントを外す
			end				
				
			/////////////////////////////////
			//正常：受信の終了と信号送信準備		//
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
				//受信信号をbufferにどんどん格納していく
			buffer[7:0] <= buffer[8:1];
			buffer[8]   <= rxd;
		end
	end
end

endmodule
