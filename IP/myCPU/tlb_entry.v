module tlb_entry
#(
    parameter TLBNUM = 32
)
(
    input        clk,
    // search port 0
    input                       s0_fetch    ,
    input  [18:0]               s0_vppn     ,
    input                       s0_odd_page ,
    input  [ 9:0]               s0_asid     ,
    output                      s0_found    ,
    output [$clog2(TLBNUM)-1:0] s0_index    ,
    output [ 5:0]               s0_ps       ,
    output [19:0]               s0_ppn      ,
    output                      s0_v        ,
    output                      s0_d        ,
    output [ 1:0]               s0_mat      ,
    output [ 1:0]               s0_plv      ,
    //search port 1
    input                       s1_fetch    ,
    input  [18:0]               s1_vppn     ,
    input                       s1_odd_page ,
    input  [ 9:0]               s1_asid     ,
    output                      s1_found    ,
    output [$clog2(TLBNUM)-1:0] s1_index    ,
    output [ 5:0]               s1_ps       ,
    output [19:0]               s1_ppn      ,
    output                      s1_v        ,
    output                      s1_d        ,
    output [ 1:0]               s1_mat      ,
    output [ 1:0]               s1_plv      ,
    // write port 
    input                       we          ,
    input  [$clog2(TLBNUM)-1:0] w_index     ,
    input  [18:0]               w_vppn      ,
    input  [ 9:0]               w_asid      ,
    input                       w_g         ,
    input  [ 5:0]               w_ps        ,
    input                       w_e         ,
    input                       w_v0        ,
    input                       w_d0        ,
    input  [ 1:0]               w_mat0      ,
    input  [ 1:0]               w_plv0      ,
    input  [19:0]               w_ppn0      ,
    input                       w_v1        ,
    input                       w_d1        ,
    input  [ 1:0]               w_mat1      ,
    input  [ 1:0]               w_plv1      ,
    input  [19:0]               w_ppn1      ,
    // read port
    input  [$clog2(TLBNUM)-1:0] r_index     ,
    output [18:0]               r_vppn      ,
    output [ 9:0]               r_asid      ,
    output                      r_g         ,
    output [ 5:0]               r_ps        ,
    output                      r_e         ,
    output                      r_v0        ,
    output                      r_d0        ,
    output [ 1:0]               r_mat0      ,
    output [ 1:0]               r_plv0      ,
    output [19:0]               r_ppn0      ,
    output                      r_v1        ,
    output                      r_d1        ,
    output [ 1:0]               r_mat1      ,
    output [ 1:0]               r_plv1      ,
    output [19:0]               r_ppn1      ,
    // invalid port 
    input                       inv_en      ,
    input  [ 4:0]               inv_op      ,
    input  [ 9:0]               inv_asid    ,
    input  [18:0]               inv_vpn
);

reg [18:0] tlb_vppn     [TLBNUM-1:0];
reg        tlb_e        [TLBNUM-1:0];
reg [ 9:0] tlb_asid     [TLBNUM-1:0];
reg        tlb_g        [TLBNUM-1:0];
reg [ 5:0] tlb_ps       [TLBNUM-1:0];
reg [19:0] tlb_ppn0     [TLBNUM-1:0];
reg [ 1:0] tlb_plv0     [TLBNUM-1:0];
reg [ 1:0] tlb_mat0     [TLBNUM-1:0];
reg        tlb_d0       [TLBNUM-1:0];
reg        tlb_v0       [TLBNUM-1:0];
reg [19:0] tlb_ppn1     [TLBNUM-1:0];
reg [ 1:0] tlb_plv1     [TLBNUM-1:0];
reg [ 1:0] tlb_mat1     [TLBNUM-1:0];
reg        tlb_d1       [TLBNUM-1:0];
reg        tlb_v1       [TLBNUM-1:0];

reg [TLBNUM-1:0] match0;
reg [TLBNUM-1:0] match1;

reg [TLBNUM-1:0] s0_odd_page_buffer;
reg [TLBNUM-1:0] s1_odd_page_buffer;

genvar i;
generate
    for (i = 0; i < TLBNUM; i = i + 1)
        begin: match
            always @(posedge clk) begin
                if (s0_fetch) begin
                    s0_odd_page_buffer[i] <= (tlb_ps[i] == 6'd12) ? s0_odd_page : s0_vppn[8];
                    match0[i] <= (tlb_e[i] == 1'b1) && ((tlb_ps[i] == 6'd12) ? s0_vppn == tlb_vppn[i] : s0_vppn[18: 9] == tlb_vppn[i][18: 9]) && ((s0_asid == tlb_asid[i]) || tlb_g[i]);
                end
                if (s1_fetch) begin
                    s1_odd_page_buffer[i] <= (tlb_ps[i] == 6'd12) ? s1_odd_page : s1_vppn[8];
                    match1[i] <= (tlb_e[i] == 1'b1) && ((tlb_ps[i] == 6'd12) ? s1_vppn == tlb_vppn[i] : s1_vppn[18: 9] == tlb_vppn[i][18: 9]) && ((s1_asid == tlb_asid[i]) || tlb_g[i]);
                end
            end
        end
endgenerate

assign s0_found = !(!match0);
assign s1_found = !(!match1);

assign {s0_index, s0_ps, s0_ppn, s0_v, s0_d, s0_mat, s0_plv} = {37{match0[0] & s0_odd_page_buffer[0] }} & {5'd0, tlb_ps[0], tlb_ppn1[0], tlb_v1[0], tlb_d1[0], tlb_mat1[0], tlb_plv1[0]} |
                                                               {37{match0[1] & s0_odd_page_buffer[1] }} & {5'd1, tlb_ps[1], tlb_ppn1[1], tlb_v1[1], tlb_d1[1], tlb_mat1[1], tlb_plv1[1]} |
                                                               {37{match0[2] & s0_odd_page_buffer[2] }} & {5'd2, tlb_ps[2], tlb_ppn1[2], tlb_v1[2], tlb_d1[2], tlb_mat1[2], tlb_plv1[2]} |
                                                               {37{match0[3] & s0_odd_page_buffer[3] }} & {5'd3, tlb_ps[3], tlb_ppn1[3], tlb_v1[3], tlb_d1[3], tlb_mat1[3], tlb_plv1[3]} |
                                                               {37{match0[4] & s0_odd_page_buffer[4] }} & {5'd4, tlb_ps[4], tlb_ppn1[4], tlb_v1[4], tlb_d1[4], tlb_mat1[4], tlb_plv1[4]} |
                                                               {37{match0[5] & s0_odd_page_buffer[5] }} & {5'd5, tlb_ps[5], tlb_ppn1[5], tlb_v1[5], tlb_d1[5], tlb_mat1[5], tlb_plv1[5]} |
                                                               {37{match0[6] & s0_odd_page_buffer[6] }} & {5'd6, tlb_ps[6], tlb_ppn1[6], tlb_v1[6], tlb_d1[6], tlb_mat1[6], tlb_plv1[6]} |
                                                               {37{match0[7] & s0_odd_page_buffer[7] }} & {5'd7, tlb_ps[7], tlb_ppn1[7], tlb_v1[7], tlb_d1[7], tlb_mat1[7], tlb_plv1[7]} |
                                                               {37{match0[8] & s0_odd_page_buffer[8] }} & {5'd8, tlb_ps[8], tlb_ppn1[8], tlb_v1[8], tlb_d1[8], tlb_mat1[8], tlb_plv1[8]} |
                                                               {37{match0[9] & s0_odd_page_buffer[9] }} & {5'd9, tlb_ps[9], tlb_ppn1[9], tlb_v1[9], tlb_d1[9], tlb_mat1[9], tlb_plv1[9]} |
                                                               {37{match0[10] & s0_odd_page_buffer[10]}} & {5'd10, tlb_ps[10], tlb_ppn1[10], tlb_v1[10], tlb_d1[10], tlb_mat1[10], tlb_plv1[10]} |
                                                               {37{match0[11] & s0_odd_page_buffer[11]}} & {5'd11, tlb_ps[11], tlb_ppn1[11], tlb_v1[11], tlb_d1[11], tlb_mat1[11], tlb_plv1[11]} |
                                                               {37{match0[12] & s0_odd_page_buffer[12]}} & {5'd12, tlb_ps[12], tlb_ppn1[12], tlb_v1[12], tlb_d1[12], tlb_mat1[12], tlb_plv1[12]} |
                                                               {37{match0[13] & s0_odd_page_buffer[13]}} & {5'd13, tlb_ps[13], tlb_ppn1[13], tlb_v1[13], tlb_d1[13], tlb_mat1[13], tlb_plv1[13]} |
                                                               {37{match0[14] & s0_odd_page_buffer[14]}} & {5'd14, tlb_ps[14], tlb_ppn1[14], tlb_v1[14], tlb_d1[14], tlb_mat1[14], tlb_plv1[14]} |
                                                               {37{match0[15] & s0_odd_page_buffer[15]}} & {5'd15, tlb_ps[15], tlb_ppn1[15], tlb_v1[15], tlb_d1[15], tlb_mat1[15], tlb_plv1[15]} |
                                                               {37{match0[16] & s0_odd_page_buffer[16]}} & {5'd16, tlb_ps[16], tlb_ppn1[16], tlb_v1[16], tlb_d1[16], tlb_mat1[16], tlb_plv1[16]} |
                                                               {37{match0[17] & s0_odd_page_buffer[17]}} & {5'd17, tlb_ps[17], tlb_ppn1[17], tlb_v1[17], tlb_d1[17], tlb_mat1[17], tlb_plv1[17]} |
                                                               {37{match0[18] & s0_odd_page_buffer[18]}} & {5'd18, tlb_ps[18], tlb_ppn1[18], tlb_v1[18], tlb_d1[18], tlb_mat1[18], tlb_plv1[18]} |
                                                               {37{match0[19] & s0_odd_page_buffer[19]}} & {5'd19, tlb_ps[19], tlb_ppn1[19], tlb_v1[19], tlb_d1[19], tlb_mat1[19], tlb_plv1[19]} |
                                                               {37{match0[20] & s0_odd_page_buffer[20]}} & {5'd20, tlb_ps[20], tlb_ppn1[20], tlb_v1[20], tlb_d1[20], tlb_mat1[20], tlb_plv1[20]} |
                                                               {37{match0[21] & s0_odd_page_buffer[21]}} & {5'd21, tlb_ps[21], tlb_ppn1[21], tlb_v1[21], tlb_d1[21], tlb_mat1[21], tlb_plv1[21]} |
                                                               {37{match0[22] & s0_odd_page_buffer[22]}} & {5'd22, tlb_ps[22], tlb_ppn1[22], tlb_v1[22], tlb_d1[22], tlb_mat1[22], tlb_plv1[22]} |
                                                               {37{match0[23] & s0_odd_page_buffer[23]}} & {5'd23, tlb_ps[23], tlb_ppn1[23], tlb_v1[23], tlb_d1[23], tlb_mat1[23], tlb_plv1[23]} |
                                                               {37{match0[24] & s0_odd_page_buffer[24]}} & {5'd24, tlb_ps[24], tlb_ppn1[24], tlb_v1[24], tlb_d1[24], tlb_mat1[24], tlb_plv1[24]} |
                                                               {37{match0[25] & s0_odd_page_buffer[25]}} & {5'd25, tlb_ps[25], tlb_ppn1[25], tlb_v1[25], tlb_d1[25], tlb_mat1[25], tlb_plv1[25]} |
                                                               {37{match0[26] & s0_odd_page_buffer[26]}} & {5'd26, tlb_ps[26], tlb_ppn1[26], tlb_v1[26], tlb_d1[26], tlb_mat1[26], tlb_plv1[26]} |
                                                               {37{match0[27] & s0_odd_page_buffer[27]}} & {5'd27, tlb_ps[27], tlb_ppn1[27], tlb_v1[27], tlb_d1[27], tlb_mat1[27], tlb_plv1[27]} |
                                                               {37{match0[28] & s0_odd_page_buffer[28]}} & {5'd28, tlb_ps[28], tlb_ppn1[28], tlb_v1[28], tlb_d1[28], tlb_mat1[28], tlb_plv1[28]} |
                                                               {37{match0[29] & s0_odd_page_buffer[29]}} & {5'd29, tlb_ps[29], tlb_ppn1[29], tlb_v1[29], tlb_d1[29], tlb_mat1[29], tlb_plv1[29]} |
                                                               {37{match0[30] & s0_odd_page_buffer[30]}} & {5'd30, tlb_ps[30], tlb_ppn1[30], tlb_v1[30], tlb_d1[30], tlb_mat1[30], tlb_plv1[30]} |
                                                               {37{match0[31] & s0_odd_page_buffer[31]}} & {5'd31, tlb_ps[31], tlb_ppn1[31], tlb_v1[31], tlb_d1[31], tlb_mat1[31], tlb_plv1[31]} |
                                                               {37{match0[0] & ~s0_odd_page_buffer[0] }} & {5'd0, tlb_ps[0], tlb_ppn0[0], tlb_v0[0], tlb_d0[0], tlb_mat0[0], tlb_plv0[0]} |
                                                               {37{match0[1] & ~s0_odd_page_buffer[1] }} & {5'd1, tlb_ps[1], tlb_ppn0[1], tlb_v0[1], tlb_d0[1], tlb_mat0[1], tlb_plv0[1]} |
                                                               {37{match0[2] & ~s0_odd_page_buffer[2] }} & {5'd2, tlb_ps[2], tlb_ppn0[2], tlb_v0[2], tlb_d0[2], tlb_mat0[2], tlb_plv0[2]} |
                                                               {37{match0[3] & ~s0_odd_page_buffer[3] }} & {5'd3, tlb_ps[3], tlb_ppn0[3], tlb_v0[3], tlb_d0[3], tlb_mat0[3], tlb_plv0[3]} |
                                                               {37{match0[4] & ~s0_odd_page_buffer[4] }} & {5'd4, tlb_ps[4], tlb_ppn0[4], tlb_v0[4], tlb_d0[4], tlb_mat0[4], tlb_plv0[4]} |
                                                               {37{match0[5] & ~s0_odd_page_buffer[5] }} & {5'd5, tlb_ps[5], tlb_ppn0[5], tlb_v0[5], tlb_d0[5], tlb_mat0[5], tlb_plv0[5]} |
                                                               {37{match0[6] & ~s0_odd_page_buffer[6] }} & {5'd6, tlb_ps[6], tlb_ppn0[6], tlb_v0[6], tlb_d0[6], tlb_mat0[6], tlb_plv0[6]} |
                                                               {37{match0[7] & ~s0_odd_page_buffer[7] }} & {5'd7, tlb_ps[7], tlb_ppn0[7], tlb_v0[7], tlb_d0[7], tlb_mat0[7], tlb_plv0[7]} |
                                                               {37{match0[8] & ~s0_odd_page_buffer[8] }} & {5'd8, tlb_ps[8], tlb_ppn0[8], tlb_v0[8], tlb_d0[8], tlb_mat0[8], tlb_plv0[8]} |
                                                               {37{match0[9] & ~s0_odd_page_buffer[9] }} & {5'd9, tlb_ps[9], tlb_ppn0[9], tlb_v0[9], tlb_d0[9], tlb_mat0[9], tlb_plv0[9]} |
                                                               {37{match0[10] & ~s0_odd_page_buffer[10]}} & {5'd10, tlb_ps[10], tlb_ppn0[10], tlb_v0[10], tlb_d0[10], tlb_mat0[10], tlb_plv0[10]} |
                                                               {37{match0[11] & ~s0_odd_page_buffer[11]}} & {5'd11, tlb_ps[11], tlb_ppn0[11], tlb_v0[11], tlb_d0[11], tlb_mat0[11], tlb_plv0[11]} |
                                                               {37{match0[12] & ~s0_odd_page_buffer[12]}} & {5'd12, tlb_ps[12], tlb_ppn0[12], tlb_v0[12], tlb_d0[12], tlb_mat0[12], tlb_plv0[12]} |
                                                               {37{match0[13] & ~s0_odd_page_buffer[13]}} & {5'd13, tlb_ps[13], tlb_ppn0[13], tlb_v0[13], tlb_d0[13], tlb_mat0[13], tlb_plv0[13]} |
                                                               {37{match0[14] & ~s0_odd_page_buffer[14]}} & {5'd14, tlb_ps[14], tlb_ppn0[14], tlb_v0[14], tlb_d0[14], tlb_mat0[14], tlb_plv0[14]} |
                                                               {37{match0[15] & ~s0_odd_page_buffer[15]}} & {5'd15, tlb_ps[15], tlb_ppn0[15], tlb_v0[15], tlb_d0[15], tlb_mat0[15], tlb_plv0[15]} |
                                                               {37{match0[16] & ~s0_odd_page_buffer[16]}} & {5'd16, tlb_ps[16], tlb_ppn0[16], tlb_v0[16], tlb_d0[16], tlb_mat0[16], tlb_plv0[16]} |
                                                               {37{match0[17] & ~s0_odd_page_buffer[17]}} & {5'd17, tlb_ps[17], tlb_ppn0[17], tlb_v0[17], tlb_d0[17], tlb_mat0[17], tlb_plv0[17]} |
                                                               {37{match0[18] & ~s0_odd_page_buffer[18]}} & {5'd18, tlb_ps[18], tlb_ppn0[18], tlb_v0[18], tlb_d0[18], tlb_mat0[18], tlb_plv0[18]} |
                                                               {37{match0[19] & ~s0_odd_page_buffer[19]}} & {5'd19, tlb_ps[19], tlb_ppn0[19], tlb_v0[19], tlb_d0[19], tlb_mat0[19], tlb_plv0[19]} |
                                                               {37{match0[20] & ~s0_odd_page_buffer[20]}} & {5'd20, tlb_ps[20], tlb_ppn0[20], tlb_v0[20], tlb_d0[20], tlb_mat0[20], tlb_plv0[20]} |
                                                               {37{match0[21] & ~s0_odd_page_buffer[21]}} & {5'd21, tlb_ps[21], tlb_ppn0[21], tlb_v0[21], tlb_d0[21], tlb_mat0[21], tlb_plv0[21]} |
                                                               {37{match0[22] & ~s0_odd_page_buffer[22]}} & {5'd22, tlb_ps[22], tlb_ppn0[22], tlb_v0[22], tlb_d0[22], tlb_mat0[22], tlb_plv0[22]} |
                                                               {37{match0[23] & ~s0_odd_page_buffer[23]}} & {5'd23, tlb_ps[23], tlb_ppn0[23], tlb_v0[23], tlb_d0[23], tlb_mat0[23], tlb_plv0[23]} |
                                                               {37{match0[24] & ~s0_odd_page_buffer[24]}} & {5'd24, tlb_ps[24], tlb_ppn0[24], tlb_v0[24], tlb_d0[24], tlb_mat0[24], tlb_plv0[24]} |
                                                               {37{match0[25] & ~s0_odd_page_buffer[25]}} & {5'd25, tlb_ps[25], tlb_ppn0[25], tlb_v0[25], tlb_d0[25], tlb_mat0[25], tlb_plv0[25]} |
                                                               {37{match0[26] & ~s0_odd_page_buffer[26]}} & {5'd26, tlb_ps[26], tlb_ppn0[26], tlb_v0[26], tlb_d0[26], tlb_mat0[26], tlb_plv0[26]} |
                                                               {37{match0[27] & ~s0_odd_page_buffer[27]}} & {5'd27, tlb_ps[27], tlb_ppn0[27], tlb_v0[27], tlb_d0[27], tlb_mat0[27], tlb_plv0[27]} |
                                                               {37{match0[28] & ~s0_odd_page_buffer[28]}} & {5'd28, tlb_ps[28], tlb_ppn0[28], tlb_v0[28], tlb_d0[28], tlb_mat0[28], tlb_plv0[28]} |
                                                               {37{match0[29] & ~s0_odd_page_buffer[29]}} & {5'd29, tlb_ps[29], tlb_ppn0[29], tlb_v0[29], tlb_d0[29], tlb_mat0[29], tlb_plv0[29]} |
                                                               {37{match0[30] & ~s0_odd_page_buffer[30]}} & {5'd30, tlb_ps[30], tlb_ppn0[30], tlb_v0[30], tlb_d0[30], tlb_mat0[30], tlb_plv0[30]} |
                                                               {37{match0[31] & ~s0_odd_page_buffer[31]}} & {5'd31, tlb_ps[31], tlb_ppn0[31], tlb_v0[31], tlb_d0[31], tlb_mat0[31], tlb_plv0[31]} ;

assign {s1_index, s1_ps, s1_ppn, s1_v, s1_d, s1_mat, s1_plv} = {37{match1[0] & s1_odd_page_buffer[0] }} & {5'd0, tlb_ps[0], tlb_ppn1[0], tlb_v1[0], tlb_d1[0], tlb_mat1[0], tlb_plv1[0]} |
                                                               {37{match1[1] & s1_odd_page_buffer[1] }} & {5'd1, tlb_ps[1], tlb_ppn1[1], tlb_v1[1], tlb_d1[1], tlb_mat1[1], tlb_plv1[1]} |
                                                               {37{match1[2] & s1_odd_page_buffer[2] }} & {5'd2, tlb_ps[2], tlb_ppn1[2], tlb_v1[2], tlb_d1[2], tlb_mat1[2], tlb_plv1[2]} |
                                                               {37{match1[3] & s1_odd_page_buffer[3] }} & {5'd3, tlb_ps[3], tlb_ppn1[3], tlb_v1[3], tlb_d1[3], tlb_mat1[3], tlb_plv1[3]} |
                                                               {37{match1[4] & s1_odd_page_buffer[4] }} & {5'd4, tlb_ps[4], tlb_ppn1[4], tlb_v1[4], tlb_d1[4], tlb_mat1[4], tlb_plv1[4]} |
                                                               {37{match1[5] & s1_odd_page_buffer[5] }} & {5'd5, tlb_ps[5], tlb_ppn1[5], tlb_v1[5], tlb_d1[5], tlb_mat1[5], tlb_plv1[5]} |
                                                               {37{match1[6] & s1_odd_page_buffer[6] }} & {5'd6, tlb_ps[6], tlb_ppn1[6], tlb_v1[6], tlb_d1[6], tlb_mat1[6], tlb_plv1[6]} |
                                                               {37{match1[7] & s1_odd_page_buffer[7] }} & {5'd7, tlb_ps[7], tlb_ppn1[7], tlb_v1[7], tlb_d1[7], tlb_mat1[7], tlb_plv1[7]} |
                                                               {37{match1[8] & s1_odd_page_buffer[8] }} & {5'd8, tlb_ps[8], tlb_ppn1[8], tlb_v1[8], tlb_d1[8], tlb_mat1[8], tlb_plv1[8]} |
                                                               {37{match1[9] & s1_odd_page_buffer[9] }} & {5'd9, tlb_ps[9], tlb_ppn1[9], tlb_v1[9], tlb_d1[9], tlb_mat1[9], tlb_plv1[9]} |
                                                               {37{match1[10] & s1_odd_page_buffer[10]}} & {5'd10, tlb_ps[10], tlb_ppn1[10], tlb_v1[10], tlb_d1[10], tlb_mat1[10], tlb_plv1[10]} |
                                                               {37{match1[11] & s1_odd_page_buffer[11]}} & {5'd11, tlb_ps[11], tlb_ppn1[11], tlb_v1[11], tlb_d1[11], tlb_mat1[11], tlb_plv1[11]} |
                                                               {37{match1[12] & s1_odd_page_buffer[12]}} & {5'd12, tlb_ps[12], tlb_ppn1[12], tlb_v1[12], tlb_d1[12], tlb_mat1[12], tlb_plv1[12]} |
                                                               {37{match1[13] & s1_odd_page_buffer[13]}} & {5'd13, tlb_ps[13], tlb_ppn1[13], tlb_v1[13], tlb_d1[13], tlb_mat1[13], tlb_plv1[13]} |
                                                               {37{match1[14] & s1_odd_page_buffer[14]}} & {5'd14, tlb_ps[14], tlb_ppn1[14], tlb_v1[14], tlb_d1[14], tlb_mat1[14], tlb_plv1[14]} |
                                                               {37{match1[15] & s1_odd_page_buffer[15]}} & {5'd15, tlb_ps[15], tlb_ppn1[15], tlb_v1[15], tlb_d1[15], tlb_mat1[15], tlb_plv1[15]} |
                                                               {37{match1[16] & s1_odd_page_buffer[16]}} & {5'd16, tlb_ps[16], tlb_ppn1[16], tlb_v1[16], tlb_d1[16], tlb_mat1[16], tlb_plv1[16]} |
                                                               {37{match1[17] & s1_odd_page_buffer[17]}} & {5'd17, tlb_ps[17], tlb_ppn1[17], tlb_v1[17], tlb_d1[17], tlb_mat1[17], tlb_plv1[17]} |
                                                               {37{match1[18] & s1_odd_page_buffer[18]}} & {5'd18, tlb_ps[18], tlb_ppn1[18], tlb_v1[18], tlb_d1[18], tlb_mat1[18], tlb_plv1[18]} |
                                                               {37{match1[19] & s1_odd_page_buffer[19]}} & {5'd19, tlb_ps[19], tlb_ppn1[19], tlb_v1[19], tlb_d1[19], tlb_mat1[19], tlb_plv1[19]} |
                                                               {37{match1[20] & s1_odd_page_buffer[20]}} & {5'd20, tlb_ps[20], tlb_ppn1[20], tlb_v1[20], tlb_d1[20], tlb_mat1[20], tlb_plv1[20]} |
                                                               {37{match1[21] & s1_odd_page_buffer[21]}} & {5'd21, tlb_ps[21], tlb_ppn1[21], tlb_v1[21], tlb_d1[21], tlb_mat1[21], tlb_plv1[21]} |
                                                               {37{match1[22] & s1_odd_page_buffer[22]}} & {5'd22, tlb_ps[22], tlb_ppn1[22], tlb_v1[22], tlb_d1[22], tlb_mat1[22], tlb_plv1[22]} |
                                                               {37{match1[23] & s1_odd_page_buffer[23]}} & {5'd23, tlb_ps[23], tlb_ppn1[23], tlb_v1[23], tlb_d1[23], tlb_mat1[23], tlb_plv1[23]} |
                                                               {37{match1[24] & s1_odd_page_buffer[24]}} & {5'd24, tlb_ps[24], tlb_ppn1[24], tlb_v1[24], tlb_d1[24], tlb_mat1[24], tlb_plv1[24]} |
                                                               {37{match1[25] & s1_odd_page_buffer[25]}} & {5'd25, tlb_ps[25], tlb_ppn1[25], tlb_v1[25], tlb_d1[25], tlb_mat1[25], tlb_plv1[25]} |
                                                               {37{match1[26] & s1_odd_page_buffer[26]}} & {5'd26, tlb_ps[26], tlb_ppn1[26], tlb_v1[26], tlb_d1[26], tlb_mat1[26], tlb_plv1[26]} |
                                                               {37{match1[27] & s1_odd_page_buffer[27]}} & {5'd27, tlb_ps[27], tlb_ppn1[27], tlb_v1[27], tlb_d1[27], tlb_mat1[27], tlb_plv1[27]} |
                                                               {37{match1[28] & s1_odd_page_buffer[28]}} & {5'd28, tlb_ps[28], tlb_ppn1[28], tlb_v1[28], tlb_d1[28], tlb_mat1[28], tlb_plv1[28]} |
                                                               {37{match1[29] & s1_odd_page_buffer[29]}} & {5'd29, tlb_ps[29], tlb_ppn1[29], tlb_v1[29], tlb_d1[29], tlb_mat1[29], tlb_plv1[29]} |
                                                               {37{match1[30] & s1_odd_page_buffer[30]}} & {5'd30, tlb_ps[30], tlb_ppn1[30], tlb_v1[30], tlb_d1[30], tlb_mat1[30], tlb_plv1[30]} |
                                                               {37{match1[31] & s1_odd_page_buffer[31]}} & {5'd31, tlb_ps[31], tlb_ppn1[31], tlb_v1[31], tlb_d1[31], tlb_mat1[31], tlb_plv1[31]} |
                                                               {37{match1[0] & ~s1_odd_page_buffer[0] }} & {5'd0, tlb_ps[0], tlb_ppn0[0], tlb_v0[0], tlb_d0[0], tlb_mat0[0], tlb_plv0[0]} |
                                                               {37{match1[1] & ~s1_odd_page_buffer[1] }} & {5'd1, tlb_ps[1], tlb_ppn0[1], tlb_v0[1], tlb_d0[1], tlb_mat0[1], tlb_plv0[1]} |
                                                               {37{match1[2] & ~s1_odd_page_buffer[2] }} & {5'd2, tlb_ps[2], tlb_ppn0[2], tlb_v0[2], tlb_d0[2], tlb_mat0[2], tlb_plv0[2]} |
                                                               {37{match1[3] & ~s1_odd_page_buffer[3] }} & {5'd3, tlb_ps[3], tlb_ppn0[3], tlb_v0[3], tlb_d0[3], tlb_mat0[3], tlb_plv0[3]} |
                                                               {37{match1[4] & ~s1_odd_page_buffer[4] }} & {5'd4, tlb_ps[4], tlb_ppn0[4], tlb_v0[4], tlb_d0[4], tlb_mat0[4], tlb_plv0[4]} |
                                                               {37{match1[5] & ~s1_odd_page_buffer[5] }} & {5'd5, tlb_ps[5], tlb_ppn0[5], tlb_v0[5], tlb_d0[5], tlb_mat0[5], tlb_plv0[5]} |
                                                               {37{match1[6] & ~s1_odd_page_buffer[6] }} & {5'd6, tlb_ps[6], tlb_ppn0[6], tlb_v0[6], tlb_d0[6], tlb_mat0[6], tlb_plv0[6]} |
                                                               {37{match1[7] & ~s1_odd_page_buffer[7] }} & {5'd7, tlb_ps[7], tlb_ppn0[7], tlb_v0[7], tlb_d0[7], tlb_mat0[7], tlb_plv0[7]} |
                                                               {37{match1[8] & ~s1_odd_page_buffer[8] }} & {5'd8, tlb_ps[8], tlb_ppn0[8], tlb_v0[8], tlb_d0[8], tlb_mat0[8], tlb_plv0[8]} |
                                                               {37{match1[9] & ~s1_odd_page_buffer[9] }} & {5'd9, tlb_ps[9], tlb_ppn0[9], tlb_v0[9], tlb_d0[9], tlb_mat0[9], tlb_plv0[9]} |
                                                               {37{match1[10] & ~s1_odd_page_buffer[10]}} & {5'd10, tlb_ps[10], tlb_ppn0[10], tlb_v0[10], tlb_d0[10], tlb_mat0[10], tlb_plv0[10]} |
                                                               {37{match1[11] & ~s1_odd_page_buffer[11]}} & {5'd11, tlb_ps[11], tlb_ppn0[11], tlb_v0[11], tlb_d0[11], tlb_mat0[11], tlb_plv0[11]} |
                                                               {37{match1[12] & ~s1_odd_page_buffer[12]}} & {5'd12, tlb_ps[12], tlb_ppn0[12], tlb_v0[12], tlb_d0[12], tlb_mat0[12], tlb_plv0[12]} |
                                                               {37{match1[13] & ~s1_odd_page_buffer[13]}} & {5'd13, tlb_ps[13], tlb_ppn0[13], tlb_v0[13], tlb_d0[13], tlb_mat0[13], tlb_plv0[13]} |
                                                               {37{match1[14] & ~s1_odd_page_buffer[14]}} & {5'd14, tlb_ps[14], tlb_ppn0[14], tlb_v0[14], tlb_d0[14], tlb_mat0[14], tlb_plv0[14]} |
                                                               {37{match1[15] & ~s1_odd_page_buffer[15]}} & {5'd15, tlb_ps[15], tlb_ppn0[15], tlb_v0[15], tlb_d0[15], tlb_mat0[15], tlb_plv0[15]} |
                                                               {37{match1[16] & ~s1_odd_page_buffer[16]}} & {5'd16, tlb_ps[16], tlb_ppn0[16], tlb_v0[16], tlb_d0[16], tlb_mat0[16], tlb_plv0[16]} |
                                                               {37{match1[17] & ~s1_odd_page_buffer[17]}} & {5'd17, tlb_ps[17], tlb_ppn0[17], tlb_v0[17], tlb_d0[17], tlb_mat0[17], tlb_plv0[17]} |
                                                               {37{match1[18] & ~s1_odd_page_buffer[18]}} & {5'd18, tlb_ps[18], tlb_ppn0[18], tlb_v0[18], tlb_d0[18], tlb_mat0[18], tlb_plv0[18]} |
                                                               {37{match1[19] & ~s1_odd_page_buffer[19]}} & {5'd19, tlb_ps[19], tlb_ppn0[19], tlb_v0[19], tlb_d0[19], tlb_mat0[19], tlb_plv0[19]} |
                                                               {37{match1[20] & ~s1_odd_page_buffer[20]}} & {5'd20, tlb_ps[20], tlb_ppn0[20], tlb_v0[20], tlb_d0[20], tlb_mat0[20], tlb_plv0[20]} |
                                                               {37{match1[21] & ~s1_odd_page_buffer[21]}} & {5'd21, tlb_ps[21], tlb_ppn0[21], tlb_v0[21], tlb_d0[21], tlb_mat0[21], tlb_plv0[21]} |
                                                               {37{match1[22] & ~s1_odd_page_buffer[22]}} & {5'd22, tlb_ps[22], tlb_ppn0[22], tlb_v0[22], tlb_d0[22], tlb_mat0[22], tlb_plv0[22]} |
                                                               {37{match1[23] & ~s1_odd_page_buffer[23]}} & {5'd23, tlb_ps[23], tlb_ppn0[23], tlb_v0[23], tlb_d0[23], tlb_mat0[23], tlb_plv0[23]} |
                                                               {37{match1[24] & ~s1_odd_page_buffer[24]}} & {5'd24, tlb_ps[24], tlb_ppn0[24], tlb_v0[24], tlb_d0[24], tlb_mat0[24], tlb_plv0[24]} |
                                                               {37{match1[25] & ~s1_odd_page_buffer[25]}} & {5'd25, tlb_ps[25], tlb_ppn0[25], tlb_v0[25], tlb_d0[25], tlb_mat0[25], tlb_plv0[25]} |
                                                               {37{match1[26] & ~s1_odd_page_buffer[26]}} & {5'd26, tlb_ps[26], tlb_ppn0[26], tlb_v0[26], tlb_d0[26], tlb_mat0[26], tlb_plv0[26]} |
                                                               {37{match1[27] & ~s1_odd_page_buffer[27]}} & {5'd27, tlb_ps[27], tlb_ppn0[27], tlb_v0[27], tlb_d0[27], tlb_mat0[27], tlb_plv0[27]} |
                                                               {37{match1[28] & ~s1_odd_page_buffer[28]}} & {5'd28, tlb_ps[28], tlb_ppn0[28], tlb_v0[28], tlb_d0[28], tlb_mat0[28], tlb_plv0[28]} |
                                                               {37{match1[29] & ~s1_odd_page_buffer[29]}} & {5'd29, tlb_ps[29], tlb_ppn0[29], tlb_v0[29], tlb_d0[29], tlb_mat0[29], tlb_plv0[29]} |
                                                               {37{match1[30] & ~s1_odd_page_buffer[30]}} & {5'd30, tlb_ps[30], tlb_ppn0[30], tlb_v0[30], tlb_d0[30], tlb_mat0[30], tlb_plv0[30]} |
                                                               {37{match1[31] & ~s1_odd_page_buffer[31]}} & {5'd31, tlb_ps[31], tlb_ppn0[31], tlb_v0[31], tlb_d0[31], tlb_mat0[31], tlb_plv0[31]} ;

always @(posedge clk) begin
    if (we) begin
        tlb_vppn [w_index] <= w_vppn;
        tlb_asid [w_index] <= w_asid;
        tlb_g    [w_index] <= w_g; 
        tlb_ps   [w_index] <= w_ps;  
        tlb_ppn0 [w_index] <= w_ppn0;
        tlb_plv0 [w_index] <= w_plv0;
        tlb_mat0 [w_index] <= w_mat0;
        tlb_d0   [w_index] <= w_d0;
        tlb_v0   [w_index] <= w_v0; 
        tlb_ppn1 [w_index] <= w_ppn1;
        tlb_plv1 [w_index] <= w_plv1;
        tlb_mat1 [w_index] <= w_mat1;
        tlb_d1   [w_index] <= w_d1;
        tlb_v1   [w_index] <= w_v1; 
    end
end

assign r_vppn  =  tlb_vppn [r_index]; 
assign r_asid  =  tlb_asid [r_index]; 
assign r_g     =  tlb_g    [r_index]; 
assign r_ps    =  tlb_ps   [r_index]; 
assign r_e     =  tlb_e    [r_index]; 
assign r_v0    =  tlb_v0   [r_index]; 
assign r_d0    =  tlb_d0   [r_index]; 
assign r_mat0  =  tlb_mat0 [r_index]; 
assign r_plv0  =  tlb_plv0 [r_index]; 
assign r_ppn0  =  tlb_ppn0 [r_index]; 
assign r_v1    =  tlb_v1   [r_index]; 
assign r_d1    =  tlb_d1   [r_index]; 
assign r_mat1  =  tlb_mat1 [r_index]; 
assign r_plv1  =  tlb_plv1 [r_index]; 
assign r_ppn1  =  tlb_ppn1 [r_index]; 

//tlb entry invalid 
generate 
    for (i = 0; i < TLBNUM; i = i + 1) 
        begin: invalid_tlb_entry 
            always @(posedge clk) begin
                if (we && (w_index == i)) begin
                    tlb_e[i] <= w_e;
                end
                else if (inv_en) begin
                    if (inv_op == 5'd0 || inv_op == 5'd1) begin
                        tlb_e[i] <= 1'b0;
                    end
                    else if (inv_op == 5'd2) begin
                        if (tlb_g[i]) begin
                            tlb_e[i] <= 1'b0;
                        end
                    end
                    else if (inv_op == 5'd3) begin
                        if (!tlb_g[i]) begin
                            tlb_e[i] <= 1'b0;
                        end
                    end
                    else if (inv_op == 5'd4) begin
                        if (!tlb_g[i] && (tlb_asid[i] == inv_asid)) begin
                            tlb_e[i] <= 1'b0;
                        end
                    end
                    else if (inv_op == 5'd5) begin
                        if (!tlb_g[i] && (tlb_asid[i] == inv_asid) && 
                           ((tlb_ps[i] == 6'd12) ? (tlb_vppn[i] == inv_vpn) : (tlb_vppn[i][18:10] == inv_vpn[18:10]))) begin
                            tlb_e[i] <= 1'b0;
                        end
                    end
                    else if (inv_op == 5'd6) begin
                        if ((tlb_g[i] || (tlb_asid[i] == inv_asid)) && 
                           ((tlb_ps[i] == 6'd12) ? (tlb_vppn[i] == inv_vpn) : (tlb_vppn[i][18:10] == inv_vpn[18:10]))) begin
                            tlb_e[i] <= 1'b0;
                        end
                    end
                end
            end
        end 
endgenerate

endmodule
