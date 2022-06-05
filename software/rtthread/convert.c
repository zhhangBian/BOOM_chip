#include <stdio.h>
#include <stdlib.h>
void binary_out(FILE* out,unsigned char* mem)
{
    char tmp;
    unsigned char num[8];
    num[0] = 1;
    num[1] = 2;
    num[2] = 4;
    num[3] = 8;
    num[4] = 16;
    num[5] = 32;
    num[6] = 64;
    num[7] = 128;
    for(int i=3;i>=0;i--)
    {
        for(int j=7;j>=0;j--)
        {
            if( (mem[i] & num[j] ) != 0)
                tmp = '1';
            else
                tmp = '0';
            fprintf(out,"%c",tmp);
        }
    }
    fprintf(out,"\n");
    return;
}

int main(void)
{
	FILE *in;
	FILE *out;

	unsigned char mem[32];

    FILE *in_data;
    out = fopen("rom.vlog","w");

    in  = fopen("rtthread.bin","rb");
    fprintf(out,"@300000\n");
    while(!feof(in)) {
        if (fread(mem,1,1,in) != 1) {
            fprintf(out,"%02x\n", mem[0]);
            break;
        }
        fprintf(out,"%02x\n", mem[0]);
    }
    //fclose(in); 
 
    //FILE *in_init_8f;
    FILE *in_init_5f;
    in_init_5f = fopen("init_5f.txt", "r");
    fprintf(out, "@5f00000\n");
    while(!feof(in_init_5f)) {
        if (fread(mem,3,1,in_init_5f) != 1) {
            //fprintf(out,"%c%c\n", mem[0], mem[1]);
            //fprintf(out,"\n");
            break;
        }
        fprintf(out,"%c%c%c", mem[0], mem[1], mem[2]);
    }

/*
    in_init_8f = fopen("init_8f.txt", "r");
    fprintf(out, "@8f00000\n");
    while(!feof(in_init_8f)) {
        if (fread(mem,3,1,in_init_8f) != 1) {
            //fprintf(out,"%c%c\n", mem[0], mem[1]);
            fprintf(out,"\n");
            break;
        }
        fprintf(out,"%c%c%c", mem[0], mem[1], mem[2]);
    }
*/

    in_data = fopen("start.bin", "rb");
    fprintf(out, "@1c000000\n");
    while(!feof(in_data)) {
        if (fread(mem,1,1,in_data) != 1) {
            fprintf(out,"%02x\n", mem[0]);
            break;
        }
        fprintf(out,"%02x\n", mem[0]);
    } 
    
    
    //fclose(in_init_8f);
    fclose(in_init_5f); 


   // in  = fopen("rtthread.bin","rb");
   // fprintf(out,"@9c000000\n");
   // while(!feof(in)) {
   //     if (fread(mem,1,1,in) != 1) {
   //         fprintf(out,"%02x\n", mem[0]);
   //         break;
   //     }
   //     fprintf(out,"%02x\n", mem[0]);
   // }
    fclose(in_data);
    fclose(in);
    fclose(out);


    return 0;
}
