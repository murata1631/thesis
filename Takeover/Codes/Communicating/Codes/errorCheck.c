///////////////////////////////////////////////
//送受信したファイルからビット単位で受信精度を求めるプログラム
//(両ファイルのサイズが異なる場合は正確な精度が求まらないので注意)
//
// sname : 送信元ファイルの場所と名称
// rname : 受信したファイルの場所と名称
//
// ErrorCode 
//   1:送信ファイルが開けない
//   2:受信ファイルが開けない
//   3:送受信ファイルどちらも開けない
//   4:fstat失敗（送信側）
//   5:fstat失敗（受信側）
///////////////////////////////////////////////

#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <fcntl.h>

//文字を2進数に変換する関数
void to_binString(char *ch, char *output)
{
	unsigned int val;
	int i;

	val = (int)*ch;

	if( !val ) {
        //return -1;
	}else {
		output[8] = '\0';
		for(i = 0; i < 8; i++) {
    			if( (val % 2) == 0 ) {  // val は偶数か？
				output[7-i] = 0x30;	//偶数："0"を代入
			} else {
				output[7-i] = 0x31;	//奇数："1"を代入
			}
			val = val >> 1;
		}
		/*
		for(i=0;i<10;i++){
			printf("\noutput[%d] = %c\n", i, output[i]); 
		}
		*/
	}
	//return 0;
}

//2進数の文字sStrとrStrの距離を求める
int diff_count(char *sStr, char *rStr)
{ 
	int i=0;
	int count=0;
	while(sStr[i]!='\0' && rStr[i]!='\0') {
		if(sStr[i] != rStr[i]){
			count++;
		}
		i++;
	}
	
	return count;
  }


int main(void)
{
	FILE *sfp, *rfp; //送受信したファイルのポインタ
	char sfname[256] = "../SendFile/RandomString.txt"; //送信ファイル名
	char rfname[256] = "../ReceiveFile/RandomString.txt"; //受信ファイル名
	char sch, rch; //読みだした文字の格納
	char sbin[9], rbin[9]; //2進数変換した文字の格納場所
	int diffcnt = 0; //誤りビット数のカウント用
	char c;
	int flag=0;
	int i=0;
	int sfd, rfd;
	struct stat sstbuf, rstbuf;
	fpos_t sfSize, rfSize; //送受信ファイルのサイズ取得用

	setvbuf(stdout, 0, _IONBF, 0); //アンバッファモード
	
	//ファイル名を指定したい場合は次のコメントを外す
	/*
	while(1) {
		if(i == 0) {
			printf("ReceiveFileName = [%s] : (y / n)", rfname);
			scanf("%s%*c", &c);
			if(c == 'y') break; break;
		}
		printf("input ReceiveFileName :");
		scanf("%s%*c", rfname + 15);
		printf("ReceiveFileName = [%s] : (y / n)", rfname);
		scanf("%s%*c", &c);
		if(c == 'y') break;
	}
	*/
	putchar('\n');
	

	printf("SendFileName    = [%s]\n", sfname);
	printf("ReceiveFileName = [%s]\n", rfname);
	sfd = open(sfname, O_RDONLY);
	rfd = open(rfname, O_RDONLY);
	sfp = fdopen(sfd, "rb");
	rfp = fdopen(rfd, "rb");
	
	putchar('\n');
	if(sfp == NULL) {
		printf("[%s] was not found. \n", sfname); 
		flag += 1;
	}
	if(rfp == NULL) {
		printf("[%s] was not found. \n", rfname); 
		flag += 2;
	}
	switch(flag) {
		case 3: printf("ErrorCode: 3\n");
			printf("exit\n");
			return -1;

		case 2: fclose(sfp);
			printf("ErrorCode: 2\n");
			printf("exit\n");
			return -1;

		case 1: fclose(rfp);
			printf("ErrorCode: 1\n");
			printf("exit\n");
			return -1;

		default: break;
	}

	
	//両ファイルの大きさが異なる場合に注意する
	if (fstat(sfd, &sstbuf) != 0) { 
		fclose(sfp);
		fclose(rfp);
		printf("ErrorCode: 4\n");
		printf("exit\n");
		return -1;
	}
	sfSize = sstbuf.st_size;
	if (fstat(rfd, &rstbuf) != 0) {
		fclose(sfp);
		fclose(rfp);
		printf("ErrorCode: 5\n");
		printf("exit\n");
		return -1;
	}
	rfSize = rstbuf.st_size;
	if(sfSize != rfSize) {
		printf("warning: SendFileSize != ReceiveFileSize\n");
	}
	//printf("sfSize = %d\n", sfSize);
	//printf("rfSize = %d\n", rfSize);
	

	i=sfSize;
	while(i) {
		//printf("number %d\n", i);

		sch = fgetc(sfp);
		//printf("fgetc(sfp) = %c\n", sch);
		rch = fgetc(rfp);
		//printf("fgetc(rfp) = %c\n", rch);

		to_binString(&sch, sbin);
		to_binString(&rch, rbin);
		//printf("to_binstring(sch) = %s\n", sbin);
		//printf("to_binstring(rch) = %s\n", rbin);

		diffcnt += diff_count(sbin, rbin);
		//printf("diff_count = %d\n\n", diffcnt);

		i--;
	}

	fclose(sfp);
	fclose(rfp);
	
	putchar('\n');

	sfSize = sfSize * 8; //バイト→　ビット
	printf("OriginalFileSize = %d[bit]\n", sfSize);
	printf("Differences between [%s] and [%s]\n: %d [bit]\n", sfname+3, rfname+3, diffcnt);
	printf("Accuracy : %.6lf [%%]", 100*(1.0 - ((double)diffcnt / (double)sfSize)));
	putchar('\n');
	return 0;
}

