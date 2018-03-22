/* ----------------------------------------
   シリアル通信プログラム（送信用） 

fname : 送信するファイルの場所と名称
COMNumber : 使用するシリアルポートの指定
baudRate : ボーレート(RS232Cビットレート)

ErrorMessage
 "warning: sirial port could not be accessed!"
 　　シリアルポートにアクセスできない　→　他アプリケーション（TeraTerm等）がポートを占有している等
 "warning: WriteFile() was failed !"
     送信に失敗している　→　送信元ファイルを閉じる等
 ---------------------------------------- */
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

HANDLE h;

int main(void) {
	int i=0;
	char COMNumber[5] = "COM3"; //ポート番号の指定
	char sBuf[65536]; //SendFile関数で送信するデータのバッファ
	int baudRate = 460800; //RS232Cビットレート
	FILE *fp; //送信ファイルのポインタ
	unsigned long nn, sSize;
	unsigned int ret;
	char fname[256] = "../SendFile/RandomString.txt"; //送信ファイル名
	DCB dcb;
	COMMTIMEOUTS cto;


	setvbuf(stdout, 0, _IONBF, 0); //アンバッファモード

	/* ----------------------------------------------
	   ファイルのクリエイト／オープン
	   ---------------------------------------------- */
	// クリエイトしたファイルのファイルハンドルを返す
	h = CreateFile(COMNumber, 
			GENERIC_READ | GENERIC_WRITE,
			0,
			NULL,
			OPEN_EXISTING,
			0,
			NULL ); 
	if ( h == INVALID_HANDLE_VALUE ) {
		printf("warning: sirial port could not be accessed!\n");
		exit -1;
	}
	printf("sirial port was opened !\n");
	/* ----------------------------------------------
	   シリアルポートの状態s操作
	   ---------------------------------------------- */
	GetCommState( h, &dcb ); // シリアルポートの状態を取得	
	dcb.BaudRate = baudRate;
	dcb.DCBlength = sizeof(DCB);//DCBのサイズ
	dcb.ByteSize = 8;//データサイズ:8bit
	dcb.fBinary = TRUE;//バイナリモード:通常TRUE
	dcb.fParity = NOPARITY;//パリティビット:パリティビットなし
	dcb.StopBits = TWOSTOPBITS;//ストップビット:1bitdRate = baudRate;
	SetCommState( h, &dcb ); // シリアルポートの状態を設定

	printf("sirial states setup completed!\n");
	/* ----------------------------------------------
	   シリアルポートのタイムアウト状態操作
	   ---------------------------------------------- */
	GetCommTimeouts( h, &cto ); // タイムアウトの設定状態を取得
	cto.ReadIntervalTimeout = 1000;
	cto.ReadTotalTimeoutMultiplier = 0;
	cto.ReadTotalTimeoutConstant = 1000;
	cto.WriteTotalTimeoutMultiplier = 0;
	cto.WriteTotalTimeoutConstant = 0;
	SetCommTimeouts( h, &cto ); // タイムアウトの状態を設定

	printf("time-out states setup completed!\n");

	/* ----------------------------------------------
	   送信ファイル
	   ---------------------------------------------- */
	
	fp = fopen(fname, "rb");
	if(fp == NULL) {
		printf("[%s] file not found!\n", fname);
		printf("exit");
		return -1;
	} else {
		printf("[%s] file discovered!\n", fname);
	}
	
	/* ----------------------------------------------
	   受信データの読み込み（１行分の文字列）
	   ---------------------------------------------- */
	printf("\nsending...\n\n");
	fgets(sBuf, sizeof(sBuf), fp);
	sSize = strlen(sBuf);
	
	for(i=0;i<sSize;i++) {
		ret = WriteFile( h,		//ファイルのハンドル
				sBuf+i,	//送信データのバッファ
				1, 	//送信データのバイト数？
				&nn,		//送信データのバイト数
				NULL
			       );		//シリアルポートへ出力
		//printf("%c", sBuf[i]);	//送信する内容を出力(デバッグ用)
		if(ret == FALSE) {
			printf("warning: WriteFile() was failed !\n");
			printf("exit\n");
			fclose(fp);
			return -1;
		}
	}

	printf("\nSendFileSize = %d\n", sSize);
	//printf("SendMessage =\n%s\n", sBuf);	//送信したデータを出力

	fclose(fp);
	printf("transmission complete !\n");
	return 0;
}
