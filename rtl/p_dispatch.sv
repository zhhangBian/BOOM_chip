`include "a_defines.svh"

module p_dispatch #(    
) (
    input clk,
    input rst_n,
    input flush_i,
    input cdb_dispatch_pkg_t    [1 : 0] cdb_dispatch_i,
    input rob_dispatch_pkg_t    [1 : 0] rob_dispatch_i,
    
    output dispatch_rob_pkg_t   [1 : 0] dispatch_rob_o,

    handshake_if.receiver r_p_receiver,

    handshake_if.sender              p_alu_sender_0, // 2 alu queues
    handshake_if.sender              p_alu_sender_1,
    handshake_if.sender              p_lsu_sender,
    handshake_if.sender              p_mdu_sender,
)

// handshake signal
logic  lsu_ready, mdu_ready;
logic  [1 : 0]    alu_ready;
assign alu_ready = {p_alu_sender_1.ready, p_alu_sender_0.ready};
assign lsu_ready = p_lsu_sender.ready;
assign mdu_ready = p_mdu_sender.ready;

assign r_p_receiver.ready = (&alu_ready) & lsu_ready & mdu_ready;
assign r_p_pkg            = r_p_receiver.data;
r_p_pkg_t   r_p_pkg;
always_comb begin
    for (integer i = 0; i < 2; i++) begin
        dispatch_rob_o[i].areg      = r_p_pkg.areg[i];
        dispatch_rob_o[i].preg      = r_p_pkg.preg[i];
        dispatch_rob_o[i].src_preg  = {r_p_pkg.src_preg[i * 2 + 1],r_p_pkg.src_preg[i * 2]};
        dispatch_rob_o[i].pc        = r_p_pkg.pc[i];
        dispatch_rob_o[i].issue     = r_p_pkg.r_valid[i];
        dispatch_rob_o[i].w_reg     = r_p_pkg.w_reg[i];
        dispatch_rob_o[i].w_mem     = r_p_pkg.w_mem[i];
        dispatch_rob_o[i].check   = r_p_pkg.check[i];
    end
end


// data src:
// rob
// arf
// cdb
// imm
// 做一个多路选择mux
logic [3 : 0][31 : 0] cdb_data_issue;
logic [3 : 0]         cdb_data_hit;
logic [3 : 0][31 : 0] rob_data_issue;
logic [3 : 0]         rob_data_hit;
// data from cdb, rob;
assign rob_data_issue = {rob_dispatch_i[1].rob_data, rob_dispatch_i[0].rob_data};
assign rob_data_hit   = {rob_dispatch_i[1].rob_complete, rob_dispatch_i[0].rob_complete};
always_comb begin
    for (integer i = 0; i < 4; i++) begin
        cdb_data_issue[i] = '0;
        cdb_data_hit[i]   = '0;
        for (integer j = 0; j < 2; j++) begin
            if (cdb_dispatch_i[j].w_preg == r_p_pkg.src_preg[i] 
                && cdb_dispatch_i[j].w_reg == '1) begin
                cdb_data_issue[i] |= cdb_dispatch_i[j].w_data;
                cdb_data_hit[i]   |= '1;
            end
        end
    end
end
// mux 选择 arf-imm, cdb-rob
logic [3 : 0][31: 0] gen_data; 
logic [3 : 0][31: 0] rob_data;
logic [3 : 0][31: 0] sel_data;
logic [3 : 0]        data_valid; 
always_comb begin
    for (integer i = 0; i < 4; i++) begin
        gen_data[i] = r_p_pkg.use_imm[i]? r_p_pkg.data_imm[i[1]] : r_p_pkg.arf_data[i];
        rob_data[i] = cdb_data_hit[i]   ? cdb_data_issue[i] : rob_data_issue[i];
        sel_data[i] = r_p_pkg.data_valid[i] ? gen_data[i] : rob_data[i];
        data_valid[i] = cdb_data_hit[i] | r_p_pkg.data_valid[i] | rob_data_hit[i];
    end
end


// alu0: preg 为 偶
// alu1: preg 为 奇
// mdu : 可同时发两条
// lsu : 可同时发两条
logic [1 : 0][1 : 0] choose_alu;
always_comb begin
    for (integer i = 0; i < 2; i++) begin
        choose_alu[i] = '0;
        for (integer j = 0; j < 2; j++) begin
            if ((r_p_pkg.alu_type) & (r_p_pkg.preg[j][0] == i[0]) & (r_p_pkg.r_valid[j])) begin
                choose_alu[i][j[0]] |= '1;
            end
        end
    end
end

logic [1 : 0] choose_mdu;
logic [1 : 0] choose_lsu;
always_comb begin
    choose_mdu = '0;
    choose_lsu = '0;
    for (integer j = 0; j < 2; j++) begin
        if ((r_p_pkg.mdu_type) & (r_p_pkg.r_valid[j])) begin
            choose_mdu[j[0]] |= '1;
        end
        if ((r_p_pkg.lsu_type) & (r_p_pkg.r_valid[j])) begin
            choose_lsu[j[0]] |= '1;
        end
    end
end

// choose 
// 0 1 :  
// 1 0 :
// 1 1 : 
// 0 0 :

assign p_alu_sender_0.valid = '1;
assign p_alu_sender_1.valid = '1;
assign p_mdu_sender.valid   = '1;
assign p_lsu_sender.valid   = '1;


p_i_pkg_t [3 : 0] p_i_pkg; // 对应四个发射队列：[3:0]对应lsu,mdu,alu1,alu0
p_i_pkg_t [3 : 0] p_i_pkg_q; // 握手缓存


always_comb begin
    for (integer i = 0; i < 4; i++) begin
        p_i_pkg[i].data = sel_data;
        p_i_pkg[i].preg = r_p_pkg.src_preg;
        p_i_pkg[i].data_valid = data_valid;
        // 控制信号TODO
    end
    p_i_pkg[0].inst_choose = choose_alu[0];
    p_i_pkg[1].inst_choose = choose_alu[1];
    p_i_pkg[2].inst_choose = choose_mdu;
    p_i_pkg[3].inst_choose = choose_lsu;
end

always_ff @(posedge clk) begin
    // alu_sender0
    if (p_alu_sender_0.valid & p_alu_sender_0.ready) begin
        p_i_pkg_q[0] <= p_i_pkg[0];
    end else begin
        p_i_pkg_q[0] <= '0;
    end
    // alu_sender1
    if (p_alu_sender_1.valid & p_alu_sender_1.ready) begin
        p_i_pkg_q[1] <= p_i_pkg[1];
    end else begin
        p_i_pkg_q[1] <= '0;
    end
    // mdu_sender
    if (p_mdu_sender.valid & p_mdu_sender.ready) begin
        p_i_pkg_q[2] <= p_i_pkg[2];
    end else begin
        p_i_pkg_q[2] <= '0;
    end
    // lsu_sender
    if (p_lsu_sender.valid & p_lsu_sender.ready) begin
        p_i_pkg_q[3] <= p_i_pkg[3];
    end else begin
        p_i_pkg_q[3] <= '0;
    end
end

assign p_alu_sender_0.data = p_i_pkg_q[0];
assign p_alu_sender_1.data = p_i_pkg_q[1];
assign p_mdu_sender.data   = p_i_pkg_q[2];
assign p_lsu_sender.data   = p_i_pkg_q[3];




endmodule

