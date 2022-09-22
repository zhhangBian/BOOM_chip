module ethernet_rmii (
    input wire ref_clk,     //for mii_to_rmii module, 50MHz
    input wire rst_n,
    output wire mac_int,

    input wire s_axi_aclk,      //sys clk
    input wire s_axi_aresetn,
    //axi slave
    input   [  3:0]   sawid_i               ,
    input   [ 31:0]   sawaddr_i             ,
    input   [  3:0]   sawlen_i              ,
    input   [  2:0]   sawsize_i             ,
    input   [  1:0]   sawburst_i            ,
    input   [  1:0]   sawlock_i             ,
    input   [  3:0]   sawcache_i            ,
    input   [  2:0]   sawprot_i             ,
    input             sawvalid_i            ,
    output            sawready_o            ,
    input   [  3:0]   swid_i                ,
    input   [ 31:0]   swdata_i              ,
    input   [  3:0]   swstrb_i              ,
    input             swlast_i              ,
    input             swvalid_i             ,
    output            swready_o             ,
    output  [  3:0]   sbid_o                ,
    output  [  1:0]   sbresp_o              ,
    output            sbvalid_o             ,
    input             sbready_i             ,
    input   [  3:0]   sarid_i               ,
    input   [ 31:0]   saraddr_i             ,
    input   [  3:0]   sarlen_i              ,
    input   [  2:0]   sarsize_i             ,
    input   [  1:0]   sarburst_i            ,
    input   [  1:0]   sarlock_i             ,
    input   [  3:0]   sarcache_i            ,
    input   [  2:0]   sarprot_i             ,
    input             sarvalid_i            ,
    output            sarready_o            ,
    output  [  3:0]   srid_o                ,
    output  [ 31:0]   srdata_o              ,
    output  [  1:0]   srresp_o              ,
    output            srlast_o              ,
    output            srvalid_o             ,
    input             srready_i             , 
    //dma axi master
    output  [  3:0] mawid_o                 ,
    output  [ 31:0] mawaddr_o               ,
    output  [  3:0] mawlen_o                ,
    output  [  2:0] mawsize_o               ,
    output  [  1:0] mawburst_o              ,
    output  [  1:0] mawlock_o               ,
    output  [  3:0] mawcache_o              ,
    output  [  2:0] mawprot_o               ,
    output          mawvalid_o              ,
    input           mawready_i              ,
    output  [  3:0] mwid_o                  ,
    output  [ 31:0] mwdata_o                ,
    output  [  3:0] mwstrb_o                ,
    output          mwlast_o                ,
    output          mwvalid_o               ,
    input           mwready_i               ,
    input   [  3:0] mbid_i                  ,
    input   [  1:0] mbresp_i                ,
    input           mbvalid_i               ,
    output          mbready_o               ,
    output  [  3:0] marid_o                 ,
    output  [ 31:0] maraddr_o               ,
    output  [  3:0] marlen_o                ,
    output  [  2:0] marsize_o               ,
    output  [  1:0] marburst_o              ,
    output  [  1:0] marlock_o               ,
    output  [  3:0] marcache_o              ,
    output  [  2:0] marprot_o               ,
    output          marvalid_o              ,
    input           marready_i              ,
    input   [  3:0] mrid_i                  ,
    input   [ 31:0] mrdata_i                ,
    input   [  1:0] mrresp_i                ,
    input           mrlast_i                ,
    input           mrvalid_i               ,
    output          mrready_o               , 

    //-----ethernet-------
    //CLK, RST
    output wire ETH_CLK,   //50MHz
    output wire ETH_RST_N,

    //MDIO
    inout wire ETH_MDIO,
    output wire ETH_MDC,

    //RMII_PHY
    input wire ETH_CRS_DV,
    input wire [1:0] ETH_RXD,
    input wire ETH_RXERR,
    output wire [1:0] ETH_TXD,
    output wire ETH_TXEN
);
    //CLK, RST
    assign ETH_CLK = ref_clk;
    assign ETH_RST_N = s_axi_aresetn;
    //MDIO
    wire md_i_0;      
    wire mdc_0;     
    wire md_o_0;      
    wire md_oe_0; 
    // assign md_i_0 = ETH_MDIO;
    // assign  = md_oe_0 ? 1'bz : md_o_0;
    IOBUF mac_mdio(.IO(ETH_MDIO),.I(md_o_0),.T(~md_oe_0),.O(md_i_0));
    assign ETH_MDC = mdc_0;

    //MII
    wire         mtxclk_0;  
    wire [3:0]   mtxd_0;    
    wire         mtxen_0;   
    wire         mtxerr_0;  

    wire         mrxclk_0;  
    wire [3:0]   mrxd_0;    
    wire         mrxdv_0;   
    wire         mrxerr_0;  

    wire         mcoll_0;   
    wire         mcrs_0;
    //MAC top
    ethernet_top ETHERNET_TOP(
        .hclk       (s_axi_aclk   ),
        .hrst_      (s_axi_aresetn),      
        //axi master
        .mawid_o    (mawid_o    ),
        .mawaddr_o  (mawaddr_o  ),
        .mawlen_o   (mawlen_o   ),
        .mawsize_o  (mawsize_o  ),
        .mawburst_o (mawburst_o ),
        .mawlock_o  (mawlock_o  ),
        .mawcache_o (mawcache_o ),
        .mawprot_o  (mawprot_o  ),
        .mawvalid_o (mawvalid_o ),
        .mawready_i (mawready_i ),
        .mwid_o     (mwid_o     ),
        .mwdata_o   (mwdata_o   ),
        .mwstrb_o   (mwstrb_o   ),
        .mwlast_o   (mwlast_o   ),
        .mwvalid_o  (mwvalid_o  ),
        .mwready_i  (mwready_i  ),
        .mbid_i     (mbid_i     ),
        .mbresp_i   (mbresp_i   ),
        .mbvalid_i  (mbvalid_i  ),
        .mbready_o  (mbready_o  ),
        .marid_o    (marid_o    ),
        .maraddr_o  (maraddr_o  ),
        .marlen_o   (marlen_o   ),
        .marsize_o  (marsize_o  ),
        .marburst_o (marburst_o ),
        .marlock_o  (marlock_o  ),
        .marcache_o (marcache_o ),
        .marprot_o  (marprot_o  ),
        .marvalid_o (marvalid_o ),
        .marready_i (marready_i ),
        .mrid_i     (mrid_i     ),
        .mrdata_i   (mrdata_i   ),
        .mrresp_i   (mrresp_i   ),
        .mrlast_i   (mrlast_i   ),
        .mrvalid_i  (mrvalid_i  ),
        .mrready_o  (mrready_o  ),
        //axi slaver
        .sawid_i    (sawid_i    ),
        .sawaddr_i  (sawaddr_i  ),
        .sawlen_i   (sawlen_i   ),
        .sawsize_i  (sawsize_i  ),
        .sawburst_i (sawburst_i ),
        .sawlock_i  (sawlock_i  ),
        .sawcache_i (sawcache_i ),
        .sawprot_i  (sawprot_i  ),
        .sawvalid_i (sawvalid_i ),
        .sawready_o (sawready_o ),   
        .swid_i     (swid_i     ),
        .swdata_i   (swdata_i   ),
        .swstrb_i   (swstrb_i   ),
        .swlast_i   (swlast_i   ),
        .swvalid_i  (swvalid_i  ),
        .swready_o  (swready_o  ),
        .sbid_o     (sbid_o     ),
        .sbresp_o   (sbresp_o   ),
        .sbvalid_o  (sbvalid_o  ),
        .sbready_i  (sbready_i  ),
        .sarid_i    (sarid_i    ),
        .saraddr_i  (saraddr_i  ),
        .sarlen_i   (sarlen_i   ),
        .sarsize_i  (sarsize_i  ),
        .sarburst_i (sarburst_i ),
        .sarlock_i  (sarlock_i  ),
        .sarcache_i (sarcache_i ),
        .sarprot_i  (sarprot_i  ),
        .sarvalid_i (sarvalid_i ),
        .sarready_o (sarready_o ),
        .srid_o     (srid_o     ),
        .srdata_o   (srdata_o   ),
        .srresp_o   (srresp_o   ),
        .srlast_o   (srlast_o   ),
        .srvalid_o  (srvalid_o  ),
        .srready_i  (srready_i  ),                 

        .interrupt_0 (mac_int),
    
        // I/O pad interface signals
        //TX
        .mtxclk_0    (mtxclk_0 ),     
        .mtxen_0     (mtxen_0  ),      
        .mtxd_0      (mtxd_0   ),       
        .mtxerr_0    (mtxerr_0 ),
        //RX
        .mrxclk_0    (mrxclk_0 ),      
        .mrxdv_0     (mrxdv_0  ),     
        .mrxd_0      (mrxd_0   ),        
        .mrxerr_0    (mrxerr_0 ),
        .mcoll_0     (mcoll_0  ),
        .mcrs_0      (mcrs_0   ),
        // MIIM
        .mdc_0       (mdc_0    ),
        .md_i_0      (md_i_0   ),
        .md_o_0      (md_o_0   ),       
        .md_oe_0     (md_oe_0  )

    );

    mii_to_rmii_0 mii_to_rmii_0 (
        .rst_n(rst_n),                      // input wire rst_n
        .ref_clk(ref_clk),                  // input wire ref_clk

        .mac2rmii_tx_en(mtxen_0),    // input wire mac2rmii_tx_en
        .mac2rmii_txd(mtxd_0),        // input wire [3 : 0] mac2rmii_txd
        .mac2rmii_tx_er(mtxerr_0),    // input wire mac2rmii_tx_er
        .rmii2mac_tx_clk(mtxclk_0),  // output wire rmii2mac_tx_clk
        .rmii2mac_rx_clk(mrxclk_0),  // output wire rmii2mac_rx_clk
        .rmii2mac_col(mcoll_0),        // output wire rmii2mac_col
        .rmii2mac_crs(mcrs_0),        // output wire rmii2mac_crs
        .rmii2mac_rx_dv(mrxdv_0),    // output wire rmii2mac_rx_dv
        .rmii2mac_rx_er(mrxerr_0),    // output wire rmii2mac_rx_er
        .rmii2mac_rxd(mrxd_0),        // output wire [3 : 0] rmii2mac_rxd

        .phy2rmii_crs_dv(ETH_CRS_DV),  // input wire phy2rmii_crs_dv
        .phy2rmii_rx_er(ETH_RXERR),    // input wire phy2rmii_rx_er
        .phy2rmii_rxd(ETH_RXD),        // input wire [1 : 0] phy2rmii_rxd
        .rmii2phy_txd(ETH_TXD),        // output wire [1 : 0] rmii2phy_txd
        .rmii2phy_tx_en(ETH_TXEN)    // output wire rmii2phy_tx_en
    );

endmodule