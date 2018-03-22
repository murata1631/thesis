////////////////////////////////////////////////////////
//乱数で文字列を生成し新規テキストファイルを作成するプログラム
//
//
//fname[] : 作成するファイルの場所と名称
//fsize : 作成するファイルの大きさ[bit]
//
////////////////////////////////////////////////////////

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

int main(void){
	FILE *fp; //FILE型構造体
	char fname[] = "../SendFile/RandomString.txt";
	int fsize = 4096;
	char c;
	char str;
	int i;
	
	setvbuf(stdout, 0, _IONBF, 0); //アンバッファモード
	
	printf("a binary = %b%c\n", 'a');

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
		printf("[%s] file was found out!\n", fname);
		fclose(fp);
		printf("overwrite ? (y / n)\n");
		scanf("%c", &c);
		if(c == 'y') {
			fp = fopen(fname, "wb");
			if(fp == NULL) return -1;
			printf("mode: overwite\n");
		} else {
			printf("exit\n");
			return -1;

		}
	}
	
	srand((unsigned)time(NULL));
	for(i = 0;i < fsize;i++) {
		str=rand()%94+33;
		fwrite(&str, sizeof(char), 1, fp);
	}

	printf("written to [%s]", fname);
	fclose(fp);

	return 0;
}


