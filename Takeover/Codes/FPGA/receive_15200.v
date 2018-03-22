`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Kitakyushu-Kosen
// Engineer: 
// 
// Create Date:    11:33:43 11/24/2016 
// Design Name: 
// Module Name:    receive_15200.v
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
//   受信機　
//   復号後の信号はボード上LEDに表示
//   kill = 1'b　になるとシステムが停止する仕様なので注意 
//       
////////////////////////////////////////////////////////////////////////////////// 
module tx_115200(CLK_50M, RS232_DCE_TXD, RS232_DTE_RXD, LED);

	input CLK_50M;
	output RS232_DCE_TXD;
	input RS232_DTE_RXD;
	output [7:0] LED;

	reg txd_out;
	assign RS232_DCE_TXD = txd_out;
	wire rxd;
	assign rxd = RS232_DTE_RXD;

	reg [7:0] led_out;
	assign LED = led_out;
	
	reg [12:0] b4_clock_count = 0;
	reg [12:0] b5_clock_count = 0;
	
	reg b4_clk = 1'b1;
	reg b5_clk = 1'b1;
	reg b4_clk_old;
	reg b5_clk_old;
	
	reg receiving = 1'b0;
	reg sending   = 1'b0;

	reg [10:0] buffer = 11'b11111_11111_1;
	reg [9:0] decode  = 10'b11111_11111;
	reg [3:0] send_count = 0;

	reg kill = 1'b0;
	
always @(posedge CLK_50M)
begin
	//異常があったときシステムを強制停止
	if(kill == 1'b1)
	begin
	end

	else if(receiving == 1'b1) //スタートビット検出したら半クロック待つ
	begin
	
		//5b側クロック　　クロックの周期は5/6倍になる
		b5_clock_count <= b5_clock_count + 1;
		if (b5_clock_count < 224) //ボーレート 115200:224, 9600:3255   (*0.625)
		begin
			b5_clk <= 1'b1;
		end
		else if (b5_clock_count < 361) //ボーレート 115200:361, 9600:4340
		begin
			b5_clk <= 1'b0;
		end
		else
		begin
			b5_clock_count <= 0;
		end
	end
	else
	begin
		b5_clock_count <= 0;
		b5_clk <= 1'b1;
	end


	//4b側クロック
	if(sending == 1)
	begin
		b4_clock_count <= b4_clock_count + 1;
		if (b4_clock_count < 269) //ボーレート 115200:269, 9600:3229    (*0.62)
		begin
			b4_clk <= 1'b0;
		end
		else if (b4_clock_count < 434) //ボーレート 115200:434, 9600:5208
		begin
			b4_clk <= 1'b1;
		end
		else
		begin
				b4_clock_count <= 0;
		end
	end
	else
	begin
		b4_clock_count <= 0;
	end
end


always @(negedge CLK_50M)
begin

	b4_clk_old <= b4_clk;
	b5_clk_old <= b5_clk;
	
	if(rxd == 1'b0) //スタートビットの検知、5bクロック開始の合図
	begin
		receiving <= 1'b1;
	end
		
	//信号をPCへ送信
	if ((b4_clk_old == 1'b1) & (b4_clk == 1'b0))
	begin
		//信号の送信
		txd_out      <= decode[0];
		decode[8:0]  <= decode[9:1];
		decode[9]    <= 1'b1;
		send_count    <= send_count + 1;
		
		//LEDへ出力(一回のみ)
		if(send_count == 1'b0)
		begin
			led_out[7:0] <= decode[8:1];
		end
		
		//送信が終わったら
		if(send_count == 4'b1001)
		begin
			send_count <= 0;
			sending    <= 1'b0;
		end
	end
	if(sending == 1'b0)
	begin
		txd_out <= 1'b1; //アイドル時
	end
	
	
	
	//b5_clkが立ち下がったら以下を実行
	if ((b5_clk_old == 1'b1) & (b5_clk == 1'b0))
	begin		
		
		//スタートビットがbuffer[0]に来たら
		if (buffer[0] == 1'b0)
		begin
			
			//////////////////////////
			//異常：システムを停止
			if(sending == 1'b1) //信号が送り終わってないのに次の信号を受信した場合
			begin
				led_out[7:0] <= 8'b1010_1010;
				kill <= 1'b1;
			end
			
			else if(rxd != 1'b1) //ストップビットが検出できていない場合はbuffer破棄（ボーレートの設定ミスで起きやすい）
			begin
				led_out[7:0] <= 8'b1011_1011;
				buffer[10:0] <= 11'b11111_11111_1;
				receiving <= 1'b0;
				//kill <= 1'b1;  //このエラー発生時システムを停止したい場合はこの行のコメントを外す
			end
			
			/////////////////////////////////
			//正常：ストップビット受信できていたら4b信号送信準備
			else
			begin
				case(buffer[5:1])
					5'b11110 : decode[4:1] <= 4'b0000;
					5'b01001 : decode[4:1] <= 4'b0001;
					5'b10100 : decode[4:1] <= 4'b0010;
					5'b10101 : decode[4:1] <= 4'b0011;
					5'b01010 : decode[4:1] <= 4'b0100;
					5'b01011 : decode[4:1] <= 4'b0101;
					5'b01110 : decode[4:1] <= 4'b0110;
					5'b01111 : decode[4:1] <= 4'b0111;
					5'b10010 : decode[4:1] <= 4'b1000;
					5'b10011 : decode[4:1] <= 4'b1001;
					5'b10110 : decode[4:1] <= 4'b1010;
					5'b10111 : decode[4:1] <= 4'b1011;
					5'b11010 : decode[4:1] <= 4'b1100;
					5'b11011 : decode[4:1] <= 4'b1101;
					5'b11100 : decode[4:1] <= 4'b1110;
					5'b11101 : decode[4:1] <= 4'b1111;
					//default  : decode[4:1] <= 4'b1111;
				endcase
				case(buffer[10:6])
					5'b11110 : decode[8:5] <= 4'b0000;
					5'b01001 : decode[8:5] <= 4'b0001;
					5'b10100 : decode[8:5] <= 4'b0010;
					5'b10101 : decode[8:5] <= 4'b0011;
					5'b01010 : decode[8:5] <= 4'b0100;
					5'b01011 : decode[8:5] <= 4'b0101;
					5'b01110 : decode[8:5] <= 4'b0110;
					5'b01111 : decode[8:5] <= 4'b0111;
					5'b10010 : decode[8:5] <= 4'b1000;
					5'b10011 : decode[8:5] <= 4'b1001;
					5'b10110 : decode[8:5] <= 4'b1010;
					5'b10111 : decode[8:5] <= 4'b1011;
					5'b11010 : decode[8:5] <= 4'b1100;
					5'b11011 : decode[8:5] <= 4'b1101;
					5'b11100 : decode[8:5] <= 4'b1110;
					5'b11101 : decode[8:5] <= 4'b1111;
					//default  : decode[8:5] <= 4'b1111;
				endcase
				//スタートストップビットを設定
				decode[0]    <= 1'b0;
				decode[9]    <= 1'b1;
				sending      <= 1'b1;
				receiving    <= 1'b0;
				buffer[10:0] <= 11'b11111_11111_1;
			end
		end
		else
		begin
			//受信信号をbufferにどんどん格納していく
			buffer[9:0]  <= buffer[10:1];
			buffer[10]   <= rxd;
		end
	end
end

endmodule
