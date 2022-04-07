#include "rand64.h"
#define RAND_TEST

Rand64::Rand64(const char *path, const char *result_flag_path) {
#ifdef RAND_TEST
    strcpy(testpath, path);
    strcpy(flagpath, result_flag_path);
    result_flag = fopen(flagpath, "a+");
    printf("Start load random res\n");
    result_type  = new BinaryType(path, "result_type");
    vpn          = new BinaryType(path, "page");
    pfn          = new BinaryType(path, "pfn");
    pcs          = new HexType   (path, "pc");
    result_addrs = new HexType   (path, "address");
    value1       = new HexType   (path, "value1");
    instructions = new HexType   (path, "instruction");
    init_regs    = new HexType   (path, "init.reg");
    comments     = new StrType   (path, "comment");
    tlb          = new Tlb();
    cpu_ex       = 1;
    tlb_ex       = 0;
    last_split   = 0;
    for (int i=0;i<32;i++) {
        gr_ref[i] = 0;
    }
    #ifdef RAND32
    printf("This is Rand32 test\n");
    #else
    printf("This is Rand64 test\n");
    #endif
#endif
}

Rand64::~Rand64() {
    fclose(result_flag);
}