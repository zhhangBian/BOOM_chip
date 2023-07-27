module YDecoder(
    input yc, yb, ya, //c -> i+1; b -> i; a -> i-1
    output negx, x, neg2x, _2x
    );

assign negx = (yc & yb & ~ya) | (yc & ~yb & ya);
assign x = (~yc & ~yb & ya) | (~yc & yb & ~ya);
assign neg2x = (yc & ~yb & ~ya);
assign _2x = (~yc & yb & ya);

endmodule


module BoothBase(
    input negx, x, neg2x, _2x,
    input InX,
    input PosLastX, NegLastX,
    output PosNextX, NegNextX,
    output OutX
    );

assign OutX = (negx & ~InX) | (x & InX) | (neg2x & NegLastX) | (_2x & PosLastX);
assign PosNextX = InX;
assign NegNextX = ~InX;

endmodule


module BoothInterBase(
    input [2:0] y,
    input [63:0] InX,
    output [63:0] OutX,
    output Carry
);

wire negx, x, neg2x, _2x;
wire [1:0] CarrySig [64:0];

YDecoder uu(.yc(y[2]), .yb(y[1]), .ya(y[0]), .negx(negx), .x(x), .neg2x(neg2x), ._2x(_2x));

BoothBase fir(.negx(negx), .x(x), .neg2x(neg2x), ._2x(_2x), .InX(InX[0]), .PosLastX(1'b0), .NegLastX(1'b1), .PosNextX(CarrySig[1][0]), .NegNextX(CarrySig[1][1]), .OutX(OutX[0]));

generate
    genvar i;
    for (i=1; i<64; i=i+1) begin: gfor
        BoothBase ui(
            .negx(negx),
            .x(x),
            .neg2x(neg2x),
            ._2x(_2x),
            .InX(InX[i]),
            .PosLastX(CarrySig[i][0]),
            .NegLastX(CarrySig[i][1]),
            .PosNextX(CarrySig[i+1][0]),
            .NegNextX(CarrySig[i+1][1]),
            .OutX(OutX[i])
        );
    end
endgenerate

assign Carry = negx || neg2x;

endmodule


module addr(
    input A, B, C,
    output Carry, S
    );

assign S = ~A & ~B & C | ~A & B & ~C | A & ~B & ~C | A & B & C;
assign Carry = A & B | A & C | B & C;

endmodule


module WallaceTreeBase(
    input [16:0] InData,
    input [13:0] CIn,
    output [13:0] COut,
    output C, S
    );

//first stage
wire [4:0] FirSig;
addr first1(.A(InData[4]), .B(InData[3]), .C(InData[2]), .Carry(COut[0]), .S(FirSig[0]));
addr first2(.A(InData[7]), .B(InData[6]), .C(InData[5]), .Carry(COut[1]), .S(FirSig[1]));
addr first3(.A(InData[10]), .B(InData[9]), .C(InData[8]), .Carry(COut[2]), .S(FirSig[2]));
addr first4(.A(InData[13]), .B(InData[12]), .C(InData[11]), .Carry(COut[3]), .S(FirSig[3]));
addr first5(.A(InData[16]), .B(InData[15]), .C(InData[14]), .Carry(COut[4]), .S(FirSig[4]));

//second stage
wire [3:0] SecSig;
addr second1(.A(CIn[2]), .B(CIn[1]), .C(CIn[0]), .Carry(COut[5]), .S(SecSig[0]));
addr second2(.A(InData[0]), .B(CIn[4]), .C(CIn[3]), .Carry(COut[6]), .S(SecSig[1]));
addr second3(.A(FirSig[1]), .B(FirSig[0]), .C(InData[1]), .Carry(COut[7]), .S(SecSig[2]));
addr second4(.A(FirSig[4]), .B(FirSig[3]), .C(FirSig[2]), .Carry(COut[8]), .S(SecSig[3]));

//third stage
wire [1:0] ThiSig;
addr third1(.A(SecSig[0]), .B(CIn[6]), .C(CIn[5]), .Carry(COut[9]), .S(ThiSig[0]));
addr third2(.A(SecSig[3]), .B(SecSig[2]), .C(SecSig[1]), .Carry(COut[10]), .S(ThiSig[1]));

//fourth stage
wire [1:0] ForSig;
addr fourth1(.A(CIn[9]), .B(CIn[8]), .C(CIn[7]), .Carry(COut[11]), .S(ForSig[0]));
addr fourth2(.A(ThiSig[1]), .B(ThiSig[0]), .C(CIn[10]), .Carry(COut[12]), .S(ForSig[1]));

//fifth stage
wire FifSig;
addr fifth1(.A(ForSig[1]), .B(ForSig[0]), .C(CIn[11]), .Carry(COut[13]), .S(FifSig));

//sixth stage
addr sixth1(.A(FifSig), .B(CIn[13]), .C(CIn[12]), .Carry(C), .S(S));

endmodule

//-------------------------------------------------------------------------------------------------------------------

module mul(
    input mul_clk, reset,
    input mul_signed,
    input [31:0] x, y, //x扩展至64位 y扩展至33位 区别有无符号
    output [63:0] result
    );

wire [63:0] CalX;
wire [32:0] CalY;

assign CalX = mul_signed ? {{32{x[31]}}, x} : {32'b0, x};
assign CalY = mul_signed ? {y[31], y} : {1'b0, y};

//booth
wire [16:0] Carry; //booth计算得到的进位
wire [63:0] BoothRes [16:0]; //booth的计算结果
BoothInterBase fir(.y({CalY[1], CalY[0], 1'b0}), .InX(CalX), .OutX(BoothRes[0]), .Carry(Carry[0]));

generate
    genvar i;
    for (i=2; i<32; i=i+2) begin: boothfor
        BoothInterBase ai(
            .y(CalY[i+1:i-1]),
            .InX(CalX<<i),
            .OutX(BoothRes[i>>1]),
            .Carry(Carry[i>>1])
        );
    end
endgenerate

BoothInterBase las(.y({CalY[32], CalY[32], CalY[31]}), .InX(CalX<<32), .OutX(BoothRes[16]), .Carry(Carry[16]));

reg [16:0] SecStageCarry;
reg [63:0] SecStageBoothRes [16:0];
integer p;
 
always @(posedge mul_clk) begin
    if (~reset) begin
        SecStageCarry <= Carry;
        for(p=0; p<17; p=p+1) begin
            SecStageBoothRes[p] <= BoothRes[p];
        end 
    end
end

//wallace
wire [13:0] WallaceInter [64:0];
wire [63:0] COut, SOut;

WallaceTreeBase firs(
            .InData({SecStageBoothRes[0][0], SecStageBoothRes[1][0], SecStageBoothRes[2][0], SecStageBoothRes[3][0], SecStageBoothRes[4][0], SecStageBoothRes[5][0], SecStageBoothRes[6][0],
            SecStageBoothRes[7][0], SecStageBoothRes[8][0], SecStageBoothRes[9][0], SecStageBoothRes[10][0], SecStageBoothRes[11][0], SecStageBoothRes[12][0], SecStageBoothRes[13][0], SecStageBoothRes[14][0],
            SecStageBoothRes[15][0], SecStageBoothRes[16][0]}),
            .CIn(SecStageCarry[13:0]),
            .COut(WallaceInter[1]),
            .C(COut[0]),
            .S(SOut[0])
        );

generate
    genvar n;
    for (n=1; n<64; n=n+1) begin: wallacefor
        WallaceTreeBase bi(
            .InData({SecStageBoothRes[0][n], SecStageBoothRes[1][n], SecStageBoothRes[2][n], SecStageBoothRes[3][n], SecStageBoothRes[4][n], SecStageBoothRes[5][n], SecStageBoothRes[6][n],
            SecStageBoothRes[7][n], SecStageBoothRes[8][n], SecStageBoothRes[9][n], SecStageBoothRes[10][n], SecStageBoothRes[11][n], SecStageBoothRes[12][n], SecStageBoothRes[13][n], SecStageBoothRes[14][n],
            SecStageBoothRes[15][n], SecStageBoothRes[16][n]}),
            .CIn(WallaceInter[n]),
            .COut(WallaceInter[n+1]),
            .C(COut[n]),
            .S(SOut[n])
        );
    end
endgenerate

//64bit add
assign result = SOut + {COut[62:0], SecStageCarry[14]} + SecStageCarry[15];

endmodule
