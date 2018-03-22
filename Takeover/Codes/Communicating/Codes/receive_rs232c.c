
/* ----------------------------------------
   シリアル通信プログラム（受信用）

fname : 受信信号の書き込み先のファイルの場所と名称
COMNumber : 使用するシリアルポートの指定
baudRate : ボーレート(RS232Cビットレート)

ErrorMessage
 "error: sirial port could not be accessed!"
   シリアルポートにアクセスできない　→　他アプリケーション（TeraTerm等）がポートを占有している等
 "error: the file could not be written"
   ファイルを書き込みモードで開けない　→　該当ファイルを閉じる等
 "error: ReadFile failed !"
   信号を読み込めなかった →　ポートの接続状態を確認する等
 ---------------------------------------- */
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

HANDLE h;

int main(void) {
	int i=0;
	char rBuf[65536]; //ReadFile関数で読み取ったデータの格納場所
	char c;
	char COMNumber[5] = "COM4"; //ポート番号の指定
	int baudRate = 460800; //RS232Cビットレート
	FILE *fp; //受信ファイルのポインタ
	unsigned long nn, rSize;
	unsigned long rn = 0; //受信バッファの配列番号を指定
	unsigned int ret;
	int flag = 0; //受信終了の判定に使用
	char fname[256] = "../ReceiveFile/RandomString.txt"; //書き込み先のファイル名
	DCB dcb; //シリアル通信構成情報を記録する構造体の生成
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
		printf("error: sirial port could not be accessed!\n");
		exit -1;
	}
	printf("sirial port was opened !\n");
	/* ----------------------------------------------
	   シリアルポートの状態操作
	   ---------------------------------------------- */
	GetCommState( h, &dcb ); // シリアルポートの状態を取得
	dcb.BaudRate = baudRate;
	dcb.DCBlength = sizeof(DCB);//DCBのサイズ
	dcb.ByteSize = 8;//データサイズ:8bit
	dcb.fBinary = TRUE;//バイナリモード:通常TRUE
	dcb.fParity = NOPARITY;//パリティビット:パリティビットなし
	dcb.StopBits = ONESTOPBIT;//ストップビット:1bit
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
	   書き込み先のファイル
	   ---------------------------------------------- */
	putchar('\n');
	fp = fopen(fname, "rb");
	if(fp == NULL) {
		printf("[%s] file was not found!\n", fname);
		printf("Create New File? (y / n)\n");
		scanf("%c%*c", &c);
		if(c == 'y') {
			fp = fopen(fname, "wb");
			printf("[%s] file was created!\n", fname);
		} else {
			fclose(fp);
			printf("exit\n");
			return -1;
		}
	} else {
		printf("[%s] file was found!\n", fname);
		fclose(fp);
		printf("overwrite ? (y / n)\n");
		scanf("%c", &c);
		if(c == 'y') {
			fp = fopen(fname, "wb");
			if(fp == NULL) {
				printf("error: the file could not be written\n", fname);
				return -1;
			}
			printf("mode: overwite\n");
		} else {
			printf("exit\n");
			return -1;

		}
	}

	/* ----------------------------------------------
	   受信データの読み込み
	   ---------------------------------------------- */
	printf("\nreceiving...\n");
	rSize = sizeof(rBuf);
	while(1) {
		//シリアルポートから信号を読み取る					
		ret = ReadFile( h,	//ファイルのハンドル
				rBuf + rn,	//データバッファ
				1, 	//読み取る信号のバイト数
				&nn,	//読み取ったバイト数
				NULL	//オーバーラップ構造体のバッファ
			      );

		//printf("%c", rBuf[rn]);
		rn += nn;  //受信データバッファの配列番号を調整

		//printf("GetFileSize = %d\n", rSize);
		if (ret == FALSE) {
			printf("error: ReadFile() failed !\n");
			return -1;
		}
		/*if(rSize != nn) {
		  printf("rSize(%d) != nn(%d)\n", rSize, nn); //デバッグ用
		  printf("rn = %d\n", rn);
		  }*/

		if(nn != 0) {
			flag = 1;
		}
		if(flag == 1 && nn == 0) { //受信終了
			//printf("rBuf = %s", rBuf);i
			printf("rn = %d", rn);

			fprintf(fp, "%s",rBuf);
			break;
		}


		//1bitずつ受信するときに使うかも？
		//if ( nn==1 ) {
		//printf("nn ==1\n");
		//if ( sBuf[0]==10 || sBuf[0]==13 ) { // '\r'や'\n'を受信すると文字列を閉じる
		//printf("find out return key\n");
		//if ( i!=0 ) {
		//str[i] = '\0';
		//i=0;
		//printf("%s\n",str);
		//}
		//} else { 
		//	str[i] = sBuf[0];
		//	i++;
		//}
		//} else {
		//	printf(" ! nn = %lu\n");
		//}
	}

	fclose(fp);
	return 0;
}
