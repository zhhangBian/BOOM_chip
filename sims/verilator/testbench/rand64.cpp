#include "rand64.h"

Rand64::Rand64(const char *path) {
#ifdef RAND_TEST
    strcpy(testpath, path);
    printf("Start load random res\n");
    result_type = new BinaryType(path, "result_type");
    vpn = new BinaryType(path, "page");
    pfn = new BinaryType(path, "pfn");
    cca = new BinaryType(path,"cca");
    page_size = new BinaryType(path,"page_size");
    pcs = new HexType(path, "pc");
    result_addrs = new HexType(path, "address");
    value1 = new HexType(path, "value1");
    instructions = new HexType(path, "instruction");
    init_regs = new HexType(path, "init.reg");
    comments = new StrType(path, "comment");
    parameters = new HexNormalType(path,"parameter");
    parameters->read_next();
    tlb_entry_num = parameters->data;
    tlb = new Tlb(tlb_entry_num);
    cpu_ex = 1;
    tlb_ex = 0;
    last_split = 0;
    for (int i = 0; i < 32; i++) {
        gr_ref[i] = 0;
    }
#ifdef LA32
    printf("This is Rand32 test\n");
#else
    printf("This is Rand64 test\n");
#endif
#endif
}

int Rand64::init_all() {
    int error = 0;
    error |= init_gr_ref();
    error |= tlb_init();
    return error;
}

int Rand64::init_gr_ref() {
    for (int i = 0; i < 32; i++) {
        if (!init_regs->read_next()) {
            gr_ref[i] = init_regs->data;
        } else {
            return 1;
        }
    }
    return 0;
}

int Rand64::tlb_init() {
        int error=0;
        int i,j;
        printf("TLB INIT\n");
        printf("Max entry = %d\n",tlb_entry_num);
        srand(CACHE_SEED);
        for (i=0;i<tlb_entry_num;i++) {
            error |= vpn->read_next();
            error |= pfn->read_next();
            error |= cca->read_next();
            error |= page_size->read_next();
            tlb->vpn_table[i] = vpn->data;
            tlb->pfn_table[i] = pfn->data;
            tlb->cca[i] = cca->data;
            tlb->page_size[i] = page_size->data;
        }
        
        if (error) {
            printf("TLB INIT Might be wrong\n"); 
            return 1;
        } else {
            error |= vpn->read_next();
        }
        printf("READ TLB ENTRY FINISHED\n");
        return 0;
}

int Rand64::read_next_compare() {
    int error = 0;
    error |= result_type->read_next();
    error |= pcs->read_next();
    error |= result_addrs->read_next();
    error |= value1->read_next();
    error |= instructions->read_next();
    error |= comments->read_next();
    return error;
}

int Rand64::print() {
    printf("%llx\n", result_type->data);
    printf("%llx\n", vpn->data);
    printf("%llx\n", pfn->data);
    printf("%llx\n", pcs->data);
    printf("%llx\n", result_addrs->data);
    printf("%llx\n", value1->data);
    printf("%llx\n", instructions->data);
    return 0;
}

void Rand64::print_ref() {
    for (int i = 0; i < 32; i++) {
#ifdef LA32
        printf("gr_ref[%02d] = %08llx\n",i,gr_ref[i]&0xffffffffll);
#else
        printf("gr_ref[%02d] = %016llx\n", i, gr_ref[i]);
#endif
    }
    //fr
    return;
}

void Rand64::print_ref(long long *gr_rtl) {
    for (int i = 0; i < 32; i++) {
#ifdef LA32
        printf("gr_ref[%02d] = %08llx%010sgr_rtl[%02d] = %08llx\n",i,gr_ref[i]&0xffffffffll,"",i,gr_rtl[i]&0xffffffffll);
#else
        printf("gr_ref[%02d] = %016llx%010sgr_rtl[%02d] = %016llx\n", i, gr_ref[i], "", i, gr_rtl[i]);
#endif
    }

}

int Rand64::compare(long long *gr_rtl) {
    for (int i = 1; i < 32; i++) {
#ifdef LA32
        if ((int)gr_rtl[i]!=(int)gr_ref[i]) {
#else
        if (gr_rtl[i] != gr_ref[i]) {
#endif
            printf("gr_ref[%02d] = %016llx%010sgr_rtl[%02d] = %016llx\n", i, gr_ref[i], "", i, gr_rtl[i]);
            printf("Compare Fail\n");
            return 1;
        }
    }
    return 0;
}

int Rand64::update(int commit_num, vluint64_t main_time) {
    if (!commit_num) {
        return 0;
    }
    printf("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
    //printf("++++++++++++++++++++++++++++++++++++++++++++++++++++++\n");
    for (int i = 0; i < commit_num; i++) {
        if (read_next_compare()) {
            printf("Update Fail\n");
            return 1;
        }
        update_once(main_time);
    }
    printf(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
    printf("\n\n");
    return 0;
}

void Rand64::update_once(vluint64_t main_time) {
    if (result_addrs->data == 0)
        return;
    printf("[%dns] Updating ref reg, instruction is %08x, pc is 0x%016x, result_type is 0x%0x\n", main_time,
           instructions->data, pcs->data, result_type->data);
    printf("Inst assembly is %s\n", comments->data);
    switch (result_type->data) {
        case 0:
            break;
        case 1:
            gr_ref[result_addrs->data] = value1->data;
            printf("Update Value = %016llx\n\n", value1->data);
            break;
        case 2:
            break;
        default:
            printf("other case\n");
            printf("result type=%llx\n\n", result_type->data);
            break;
    }
}

int Rand64::tlb_refill_once(long long bad_vaddr) {
    return tlb->find_entry(bad_vaddr);
}


Rand64::~Rand64() {
    return;
}
