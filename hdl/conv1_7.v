module conv1_7(
    // Weight sram, dual port
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg finish,

    input wire [15:0] weight_offset,
    input wire [15:0] act_offset,
    input wire [31:0] sc_CONV1,
    output reg        weight_cen,
    output reg [ 3:0] weight_wea0,
    output reg [15:0] weight_addr0,
    input wire [31:0] weight_rdata0,
    output reg [ 3:0] weight_wea1,
    output reg [15:0] weight_addr1,
    input wire [31:0] weight_rdata1,

    // Activation sram, dual port
    output reg        act_cen,
    output reg [ 3:0] act_wea0,
    output reg [15:0] act_addr0,
    output reg [31:0] act_wdata0,
    input wire [31:0] act_rdata0,
    output reg [ 3:0] act_wea1,
    output reg [15:0] act_addr1,
    output reg [31:0] act_wdata1,
    input wire [31:0] act_rdata1
);
    reg [7:0] state;
    reg [7:0] next_state;
    
    parameter [7:0] Pre         =8'd0;
    parameter [7:0] Outchannel  =8'd1;
    parameter [7:0] LoadWeight  =8'd2;
    parameter [7:0] LoadAct     =8'd3;
    parameter [7:0] Comp        =8'd4;
    parameter [7:0] Quan0       =8'd5;
    parameter [7:0] Quan1       =8'd6;
    parameter [7:0] PoolingQuan =8'd7;


    parameter [7:0] Finish  =8'd9;
    parameter [7:0] Wait0   =8'd20;
    parameter [7:0] Wait1   =8'd21;
    parameter [7:0] Wait3   =8'd22;
    parameter [7:0] Wait4   =8'd23;
    parameter [7:0] Wait5   =8'd24;
    parameter [7:0] Waitend1=8'd25;
    parameter [7:0] Waitend0=8'd26;

// save the rdata for a cyc
    reg [31:0] actde_rdata0, actde_rdata1;
    always @(posedge clk) begin
        if(!rst_n)begin
            actde_rdata0 <= 0;
            actde_rdata1 <= 0;
        end
        else begin
            actde_rdata0 <= act_rdata0;
            actde_rdata1 <= act_rdata1;
        end
    end


    reg [31:0]activation0;
    reg [31:0]activation1;
    reg [31:0]activation2;
    reg [31:0]activation3;
    reg [55:0]wt_row0;
    reg [55:0]wt_row1;
    wire signed [31:0]comp_res[1:0][11:0];//2*12
    innerproduct7 inpro7(
        .act0(actde_rdata0),
        .act1(actde_rdata1),
        .act2(act_rdata0),
        .act3(act_rdata1),
        .wt_row0(wt_row0),
        .wt_row1(wt_row1),
        .out_00 (comp_res[0][0]),
        .out_01 (comp_res[0][1]),
        .out_02 (comp_res[0][2]),
        .out_03 (comp_res[0][3]),
        .out_04 (comp_res[0][4]),
        .out_05 (comp_res[0][5]),
        .out_06 (comp_res[0][6]),
        .out_07 (comp_res[0][7]), 
        .out_08 (comp_res[0][8]),
        .out_09 (comp_res[0][9]),
        .out_010(comp_res[0][10]),
        .out_011(comp_res[0][11]),

        .out_10 (comp_res[1][0]),
        .out_11 (comp_res[1][1]),
        .out_12 (comp_res[1][2]),
        .out_13 (comp_res[1][3]),
        .out_14 (comp_res[1][4]),
        .out_15 (comp_res[1][5]),
        .out_16 (comp_res[1][6]),
        .out_17 (comp_res[1][7]), 
        .out_18 (comp_res[1][8]),
        .out_19 (comp_res[1][9]),
        .out_110(comp_res[1][10]),
        .out_111(comp_res[1][11])
    );
    reg [31:0] prq_in[1:0][3:0];
    wire [31:0] quanout0;
    wire [31:0] quanout1;
    reluQuan8 rq8(
        .scale (sc_CONV1),
        .in0_0 (prq_in[0][0 ]),
        .in0_1 (prq_in[0][1 ]),
        .in0_2 (prq_in[0][2 ]),
        .in0_3 (prq_in[0][3 ]),
        .in1_0 (prq_in[1][0 ]),
        .in1_1 (prq_in[1][1 ]),
        .in1_2 (prq_in[1][2 ]),
        .in1_3 (prq_in[1][3 ]),
        .out0(quanout0),
        .out1(quanout1)
    );


    reg signed[ 7:0]weights2D[6:0][6:0];
    

    //row weight count
    reg [7:0]out_channel;
    reg [7:0]next_out_channel;
    reg [7:0]in_channel;
    always @(posedge clk) begin
        if(!rst_n)begin
            out_channel <= 0;
        end
        else begin
            out_channel <= next_out_channel;
        end
    end
    always @(*) begin
        if(state==Outchannel)begin
            next_out_channel=out_channel + 1;
        end
        else begin
            next_out_channel = out_channel;
        end
    end
    reg [3:0]row_weight_cnt;
    reg [3:0]next_row_weight_cnt;
    always@(posedge clk) begin
        if(!rst_n) begin
            row_weight_cnt <= 4'd0;
        end
        else begin
            row_weight_cnt <= next_row_weight_cnt;
        end
    end
    always@(*)begin
        if (state==LoadWeight)begin
            next_row_weight_cnt =row_weight_cnt+1;
        end  
        else begin
            next_row_weight_cnt = 0;
        end
    end
//loading weight
    reg [3:0]loading_row_weight;
    reg [3:0]next_loading_row_weight;
    always@(posedge clk) begin
        if(!rst_n) begin
            loading_row_weight <= 4'd0;
        end
        else begin
            loading_row_weight <= next_loading_row_weight;
        end
    end
    always@(*)begin
        if (state==LoadWeight && row_weight_cnt>=3)begin
            if(loading_row_weight==6)next_loading_row_weight=4;
            else next_loading_row_weight =loading_row_weight+1;
        end  
        else begin
            next_loading_row_weight = 0;
        end
    end
    //save weight to array
    reg [55:0]next_save_weight;
    always@(*)begin
        if (state==LoadWeight )begin
            next_save_weight = {weight_rdata1[23:0] , weight_rdata0};
        end  
        else begin
            next_save_weight = 0;
        end
    end

    integer i;
    integer j;
    always@(posedge clk) begin
        if(!rst_n) begin
            for (i=0;i<7;i=i+1)begin
                for (j=0;j<7;j=j+1)begin
                    weights2D[i][j]<=0;
                end
            end
        end
        else begin
            if(state==LoadWeight)begin
                weights2D[loading_row_weight][0] <= next_save_weight[ 7: 0];
                weights2D[loading_row_weight][1] <= next_save_weight[15: 8];
                weights2D[loading_row_weight][2] <= next_save_weight[23:16];
                weights2D[loading_row_weight][3] <= next_save_weight[31:24];
                weights2D[loading_row_weight][4] <= next_save_weight[39:32];
                weights2D[loading_row_weight][5] <= next_save_weight[47:40];
                weights2D[loading_row_weight][6] <= next_save_weight[55:48];
            end
            
        end
    end
    //act count
    reg [7:0]col_cnt;
    reg [7:0]next_col_cnt;
    always@(posedge clk)begin
        if(!rst_n) begin
            col_cnt<=8'd0;
        end
        else begin 
            col_cnt <= next_col_cnt;
        end
    end
    always @(*)begin
        if(state==PoolingQuan)begin
            next_col_cnt = 0;
        end
        else begin
            if(state==LoadAct||state==Wait0||state==Wait1||state==Comp||state==Quan0||state==Quan1)begin
                if (col_cnt==8)begin
                    next_col_cnt=0;
                end
                else begin
                    next_col_cnt = col_cnt+8'd8; 
                    
                end
            end
            else next_col_cnt =0;
        end
    end

    reg [7:0]row_act_cnt;
    reg [7:0]next_row_act_cnt;
    
    reg [7:0]rowstart_cnt;
    reg [7:0]next_rowstart_cnt;

    always@(posedge clk)begin
        if(!rst_n) begin
            row_act_cnt<=8'd0;
        end
        else begin 
            row_act_cnt <= next_row_act_cnt;
        end
    end
    always @(*)begin
        if(state==PoolingQuan)begin
            next_row_act_cnt = 0;
        end
        else begin
            if(state==LoadAct||state==Wait0||state==Wait1||state==Comp||state==Quan0||state==Quan1)begin
                if(rowstart_cnt==0||rowstart_cnt==25)begin
                    if (row_act_cnt==6)begin
                        if(col_cnt==8)
                            next_row_act_cnt=0;
                        else
                            next_row_act_cnt=row_act_cnt;
                    end
                    else begin
                        if(col_cnt==8)
                            next_row_act_cnt = row_act_cnt+8'd1; 
                        else
                            next_row_act_cnt=row_act_cnt;
                    end
                end
                else begin
                    if (row_act_cnt==7)begin
                        if(col_cnt==8)
                            next_row_act_cnt=0;
                        else
                            next_row_act_cnt=row_act_cnt;
                    end
                    else begin
                        if(col_cnt==8)
                            next_row_act_cnt = row_act_cnt+8'd1; 
                        else
                            next_row_act_cnt=row_act_cnt;
                    end
                end
                
            end
            else next_row_act_cnt =0;
        end
    end

    

    reg [7:0]col_act_cnt;
    reg [7:0]next_col_act_cnt;
    always@(posedge clk)begin
        if(!rst_n) begin
            col_act_cnt<=8'd0;
        end
        else begin 
            col_act_cnt <= next_col_act_cnt;
        end
    end
    always @(*)begin
        if(state==PoolingQuan)begin
            if (col_act_cnt==16)begin
                next_col_act_cnt=0;
            end
            else begin
                next_col_act_cnt = col_act_cnt + 16'd8;
            end
        end
        else begin
            next_col_act_cnt = col_act_cnt;
        end
    end

    //reg [7:0]rowstart_cnt;
    //reg [7:0]next_rowstart_cnt;
    always@(posedge clk)begin
        if(!rst_n) begin
            rowstart_cnt<=8'd0;
        end
        else begin 
            rowstart_cnt <= next_rowstart_cnt;
        end
    end
    always @(*)begin
        if(state==PoolingQuan)begin
            if (col_act_cnt==16)begin
                if(rowstart_cnt==0)begin
                    next_rowstart_cnt = rowstart_cnt+8'd1;
                end
                else begin
                    next_rowstart_cnt = rowstart_cnt+8'd2;
                end
                
            end
            else begin
                next_rowstart_cnt=rowstart_cnt;
            end
        end
        else begin
            if(state==LoadAct||state==Wait0||state==Wait1||state==Comp||state==Quan0||state==Quan1)begin
                next_rowstart_cnt=rowstart_cnt;
            end
            else next_rowstart_cnt =0;
        end
    end
//computing activation
    reg [7:0]cpcol_cnt;
    reg [7:0]delay1_cpcol_cnt;
    reg [7:0]delay2_cpcol_cnt;
    reg [7:0]delay3_cpcol_cnt;
    reg [7:0]next_cpcol_cnt;
    always@(posedge clk)begin
        if(!rst_n) begin
            delay1_cpcol_cnt <= 8'd0;
            delay2_cpcol_cnt <= 8'd0;
            delay3_cpcol_cnt <= 8'd0;
            cpcol_cnt<=8'd0;
            
        end
        else begin 
            delay1_cpcol_cnt <= next_col_cnt;
            delay2_cpcol_cnt <= delay1_cpcol_cnt;
            delay3_cpcol_cnt <= delay2_cpcol_cnt;
            cpcol_cnt <= delay3_cpcol_cnt;
        end
    end
    
    reg [7:0]cpact_col;
    reg [7:0]delay1_cpact_col;
    reg [7:0]delay2_cpact_col;
    reg [7:0]delay3_cpact_col;
    reg [7:0]next_cpact_col;
    always@(posedge clk)begin
        if(!rst_n) begin
            delay1_cpact_col <= 8'd0;
            delay2_cpact_col <= 8'd0;
            delay3_cpact_col <= 8'd0;
            cpact_col<=8'd0;
            
        end
        else begin 
            delay1_cpact_col <= next_col_act_cnt;
            delay2_cpact_col <= delay1_cpact_col;
            delay3_cpact_col <= delay2_cpact_col;
            cpact_col <= delay3_cpact_col;
        end
    end
//row of cp act
    reg [7:0]cpact_row;
    reg [7:0]delay1_cpact_row;
    reg [7:0]delay2_cpact_row;
    reg [7:0]delay3_cpact_row;
    reg [7:0]next_cpact_row;
    always@(posedge clk)begin
        if(!rst_n) begin
            delay1_cpact_row <= 8'd0;
            delay2_cpact_row <= 8'd0;
            delay3_cpact_row <= 8'd0;
            cpact_row<=8'd0;
        end
        else begin 
            delay1_cpact_row <= next_row_act_cnt;
            delay2_cpact_row <= delay1_cpact_row;
            delay3_cpact_row <= delay2_cpact_row;
            cpact_row <= delay3_cpact_row;
        end
    end

//out activation array
    reg signed [31:0] out_act[1:0][10:0]; //2*11
    reg signed [31:0] next_out_psum[1:0][10:0]; 
    //integer i,j;
    always@(posedge clk)begin
        if(!rst_n) begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<11;j=j+1)begin
                    out_act[i][j]<=0;
                end
            end
        end//debug
        else begin 
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<11;j=j+1)begin
                    out_act[i][j] <= next_out_psum[i][j];
                end
            end
        end
        
    end
    //combinational saving and adding the psum 
    always @(*)begin
        if(state==Comp)begin
            if(cpcol_cnt==8)begin
                if(col_act_cnt==0)begin
                    for (i=0;i<2;i=i+1)begin
                        for(j=0;j<11;j=j+1)begin
                            next_out_psum[i][j] = out_act[i][j]+comp_res[i][j];
                        end
                    end
                end
                else if(col_act_cnt==8)begin
                    for (i=0;i<2;i=i+1)begin
                        for(j=0;j<11;j=j+1)begin
                            next_out_psum[i][j] = out_act[i][j]+comp_res[i][j];
                        end
                    end
                end
                else begin //=16
                    for (i=0;i<2;i=i+1)begin
                        for(j=0;j<11;j=j+1)begin
                            next_out_psum[i][j] = out_act[i][j]+comp_res[i][j+1];
                        end
                    end
                end
            end
            else begin
                for (i=0;i<2;i=i+1)begin
                    for(j=0;j<11;j=j+1)begin
                        next_out_psum[i][j] = out_act[i][j];
                    end
                end
            end
            
                
        end
        else if(state==Quan0||state==Quan1||state==PoolingQuan)begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<11;j=j+1)begin
                    next_out_psum[i][j] = out_act[i][j];
                end
            end
        end
        else begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<11;j=j+1)begin
                    next_out_psum[i][j] = 0;
                end

            end
        end
    end
//wt row
    wire [55:0] wr[6:0];
    assign wr[0] = {weights2D[0][6],weights2D[0][5],weights2D[0][4],weights2D[0][3],weights2D[0][2],weights2D[0][1],weights2D[0][0]};
    assign wr[1] = {weights2D[1][6],weights2D[1][5],weights2D[1][4],weights2D[1][3],weights2D[1][2],weights2D[1][1],weights2D[1][0]};
    assign wr[2] = {weights2D[2][6],weights2D[2][5],weights2D[2][4],weights2D[2][3],weights2D[2][2],weights2D[2][1],weights2D[2][0]};
    assign wr[3] = {weights2D[3][6],weights2D[3][5],weights2D[3][4],weights2D[3][3],weights2D[3][2],weights2D[3][1],weights2D[3][0]};
    assign wr[4] = {weights2D[4][6],weights2D[4][5],weights2D[4][4],weights2D[4][3],weights2D[4][2],weights2D[4][1],weights2D[4][0]};
    assign wr[5] = {weights2D[5][6],weights2D[5][5],weights2D[5][4],weights2D[5][3],weights2D[5][2],weights2D[5][1],weights2D[5][0]};
    assign wr[6] = {weights2D[6][6],weights2D[6][5],weights2D[6][4],weights2D[6][3],weights2D[6][2],weights2D[6][1],weights2D[6][0]};

    always @(*)begin
        if(state==Comp||state==PoolingQuan)begin
            //data for computing
            if(rowstart_cnt==0)begin
                case(cpact_row)
                    8'd0:begin
                        wt_row0 = wr[1];
                        wt_row1 = wr[0];
                    end
                    8'd6:begin
                        wt_row0 = 0;
                        wt_row1 = wr[6];
                    end
                    default:begin
                        wt_row0 = wr[cpact_row+1];
                        wt_row1 = wr[cpact_row];
                    end
                endcase
            end
            else if(rowstart_cnt==25)begin
                case(cpact_row)
                    8'd0:begin
                        wt_row0 = wr[0];
                        wt_row1 = 0;
                    end
                    8'd6:begin
                        wt_row0 = wr[6];
                        wt_row1 = wr[5];
                    end
                    default:begin
                        wt_row0 = wr[cpact_row];
                        wt_row1 = wr[cpact_row-1];
                    end
                endcase
            end
            else begin
                case(cpact_row)
                    8'd0:begin
                        wt_row0 = wr[0];
                        wt_row1 = 0;
                    end
                    8'd7:begin
                        wt_row0 = 0;
                        wt_row1 = wr[6];
                    end
                    default:begin
                        wt_row0 = wr[cpact_row];
                        wt_row1 = wr[cpact_row-1];
                    end
                endcase
            end
            
        end
        else begin
            wt_row0 = 0;
            wt_row1 = 0;
        end
    end

    always @(*)begin
        
        if(cpact_col==8'd0)begin
            if(state==Quan0)begin
                for(i=0;i<2;i=i+1)begin
                    for(j=0;j<4 ;j=j+1)begin
                        prq_in[i][j] = out_act[i][j];
                    end
                end
            end
            else if(state==Quan1)begin
                for(i=0;i<2;i=i+1)begin
                    for(j=0;j<4;j=j+1)begin
                        prq_in[i][j] = out_act[i][j+4];
                    end
                end
            end
            else if(state==PoolingQuan)begin
                for(i=0;i<2;i=i+1)begin
                    for(j=0;j<3;j=j+1)begin
                        prq_in[i][j] = out_act[i][j+8];
                    end
                end
                prq_in[0][3]=0;
                prq_in[1][3]=0;
            end
        end
        else if(cpact_col==8'd8)begin
            if(state==Quan0)begin
                for(i=0;i<2;i=i+1)begin
                    for(j=1;j<3 ;j=j+1)begin
                        prq_in[i][j] = 0;
                    end
                end
                prq_in[0][3]=out_act[0][3];
                prq_in[1][3]=out_act[1][3];
            end
            else if(state==Quan1)begin
                for(i=0;i<2;i=i+1)begin
                    for(j=0;j<4;j=j+1)begin
                        prq_in[i][j] = out_act[i][j+4];
                    end
                end
            end
            else if(state==PoolingQuan)begin
                for(i=0;i<2;i=i+1)begin
                    for(j=1;j<4;j=j+1)begin
                        prq_in[i][j] = 0;
                    end
                end
                prq_in[0][0]=out_act[0][8];
                prq_in[1][0]=out_act[1][8];
                
            end
        end
        else begin //=16
            if(state==Quan0)begin
                for(i=0;i<2;i=i+1)begin
                    for(j=1;j<4 ;j=j+1)begin
                        prq_in[i][j] = out_act[i][j-1];
                    end
                end
                prq_in[0][0]=0;
                prq_in[1][0]=0;
            end
            else if(state==Quan1)begin
                for(i=0;i<2;i=i+1)begin
                    for(j=0;j<4;j=j+1)begin
                        prq_in[i][j] = out_act[i][j+3];
                    end
                end
            end
            else if(state==PoolingQuan)begin
                for(i=0;i<2;i=i+1)begin
                    for(j=0;j<4;j=j+1)begin
                        prq_in[i][j] = out_act[i][j+7];
                    end
                end
                
            end
        end
            
    end
wire [7:0]fix_rowstart_cnt;
assign fix_rowstart_cnt = (rowstart_cnt==0) ? 0 : rowstart_cnt+1;
wire [7:0]fix_cpactcol;
assign fix_cpactcol = (cpact_col==0) ? 0 : ( (cpact_col==8)? 2:4 );
//FSM
    always@(posedge clk) begin
        if(!rst_n) begin
            state <= Pre;
        end
        else begin
            state <= next_state;
        end
    end

    always @*begin
        next_state=Pre;
        weight_cen  =1'b1;
        act_cen     =1'b1;
        weight_addr0 = 16'd0;
        weight_addr1 = 16'd0;
        weight_wea0 = 4'b0000;
        weight_wea1 = 4'b0000;
        act_addr0 = 16'd0;
        act_addr1 = 16'd0;
        act_wdata0 = 32'd0;
        act_wdata1 = 32'd0;
        act_wea0 = 4'b0000;
        act_wea1 = 4'b0000;
        finish = 0;

        case(state)
            Pre:begin
                if(start==1'b1)begin
                    next_state=LoadWeight;
                end
                else begin
                    next_state=Pre;
                end
                weight_cen  =1;
                act_cen     =1;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 16'd0;
                act_addr1 = 16'd0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
            end
            Outchannel:begin
                next_state=LoadWeight;
                weight_cen  =1;
                act_cen     =1;

                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 16'd0;
                act_addr1 = 16'd0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
            end
            LoadWeight:begin
                weight_cen  =1'b0;
                act_cen     =1'b1;
                weight_addr0=weight_offset + out_channel*14 + row_weight_cnt*2;
                weight_addr1=weight_offset + out_channel*14 + row_weight_cnt*2 + 1;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 16'd0;
                act_addr1 = 16'd0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                if(row_weight_cnt==9)begin
                    next_state=LoadAct;
                end
                else begin
                    next_state=LoadWeight;
                end
                finish = 0;
            end
            
            LoadAct:begin
                next_state=Wait0;
                weight_cen  =1'b1;
                act_cen     =1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]} + col_cnt[7:2];
                act_addr1 = act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]} + col_cnt[7:2]+1;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
            end
            Wait0:begin
                weight_cen  =1'b1;
                act_cen     =1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]} + col_cnt[7:2];
                act_addr1=act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]} + col_cnt[7:2]+1;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state=Wait1;
                finish = 0;
            end
            Wait1:begin
                weight_cen  =1'b1;
                act_cen     =1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]} + col_cnt[7:2];
                act_addr1=act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]} + col_cnt[7:2]+1;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state=Comp;
                finish = 0;
            end
            Comp:begin
                /*if(cpact_row>=6||(cpact_row==5 && cpcol_cnt==8))begin
                    weight_cen  =1'b1;
                    act_cen     =1'b1;
                end
                else begin*/
                    weight_cen  =1'b1;
                    act_cen     =1'b0;
                //end

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                //load data (3 cycle later)
                act_addr0=act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]} + col_cnt[7:2];
                act_addr1=act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]} + col_cnt[7:2] + 1;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                if(rowstart_cnt==0||rowstart_cnt==25)begin
                    if(cpact_row==8'd6&&cpcol_cnt==8'd8 )begin//debug padding may cause this different
                        next_state=Quan0;
                    end
                    else begin
                        next_state=Comp;
                    end
                end
                else begin
                    if(cpact_row==8'd7&&cpcol_cnt==8'd8 )begin//debug padding may cause this different
                        next_state=Quan0;
                    end
                    else begin
                        next_state=Comp;
                    end
                end
                
                finish = 0;
            end 
            Quan0:begin//left part
                weight_cen  =1'b1;
                act_cen     =1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = 16'd1024 + out_channel*196 + fix_rowstart_cnt*7 + fix_cpactcol;//7=14/2
                act_addr1 = 16'd1024 + out_channel*196 + (fix_rowstart_cnt+1)*7 + fix_cpactcol;
                
                if(cpact_col==8'd0)begin
                    act_wdata0  = quanout0;//debug
                    act_wea0    = 4'b1111;
                    act_wdata1  = quanout1;
                    act_wea1    = 4'b1111;
                end
                else if(cpact_col==8'd8)begin
                    act_wdata0  = quanout0;//debug
                    act_wea0    = 4'b1000;
                    act_wdata1  = quanout1;
                    act_wea1    = 4'b1000;
                end
                else begin
                    act_wdata0  = quanout0;//debug
                    act_wea0    = 4'b1110;
                    act_wdata1  = quanout1;
                    act_wea1    = 4'b1110;
                end
                
                next_state=Quan1;
            end
            Quan1:begin//mddle
                weight_cen  =1'b1;
                act_cen     =1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = 16'd1024 + out_channel*196 + fix_rowstart_cnt*7 + fix_cpactcol+1;//7=14/2
                act_addr1 = 16'd1024 + out_channel*196 + (fix_rowstart_cnt+1)*7 + fix_cpactcol+1;
                if(cpact_col==8'd0)begin
                    act_wdata0  = quanout0;//debug
                    act_wea0    = 4'b1111;
                    act_wdata1  = quanout1;
                    act_wea1    = 4'b1111;
                end
                else if(cpact_col==8'd8)begin
                    act_wdata0  = quanout0;//debug
                    act_wea0    = 4'b1111;
                    act_wdata1  = quanout1;
                    act_wea1    = 4'b1111;
                end
                else begin
                    act_wdata0  = quanout0;//debug
                    act_wea0    = 4'b1111;
                    act_wdata1  = quanout1;
                    act_wea1    = 4'b1111;
                end
                
                next_state=PoolingQuan;
            end
            PoolingQuan:begin//right part
                weight_cen  =1'b1;
                act_cen     =1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = 16'd1024 + out_channel*196 + fix_rowstart_cnt*7 + fix_cpactcol+2;//7=14/2
                act_addr1 = 16'd1024 + out_channel*196 + (fix_rowstart_cnt+1)*7 + fix_cpactcol+2;
                if(cpact_col==8'd0)begin
                    act_wdata0  = quanout0;//debug
                    act_wea0    = 4'b0111;
                    act_wdata1  = quanout1;
                    act_wea1    = 4'b0111;
                end
                else if(cpact_col==8'd8)begin
                    act_wdata0  = quanout0;//debug
                    act_wea0    = 4'b0001;
                    act_wdata1  = quanout1;
                    act_wea1    = 4'b0001;
                end
                else begin
                    act_wdata0  = quanout0;//debug
                    act_wea0    = 4'b1111;
                    act_wdata1  = quanout1;
                    act_wea1    = 4'b1111;
                end
                

                if(rowstart_cnt==25&&cpact_col==16)begin
                    if(out_channel==5) next_state=Waitend0;
                    else next_state=Outchannel;
                end
                else begin
                    next_state=LoadAct;
                end
                finish = 0;
            end
            Waitend0:begin
                
                weight_cen  =1'b1;
                act_cen     =1'b1;

                next_state=Waitend1;
                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = 16'd0;
                act_addr1 = 16'd0;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                finish = 0;
            end
            Waitend1:begin
                weight_cen  =1'b1;
                act_cen     =1'b1;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = 16'd0;
                act_addr1 = 16'd0;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                finish = 0;
                next_state=Finish;
            end
            Finish:begin
                weight_cen  =1'b1;
                act_cen     =1'b1;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = 16'd0;
                act_addr1 = 16'd0;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                next_state = Pre;
                finish = 1;
            end
            
            default:  begin
                next_state=Pre;
                weight_cen  =1'b1;
                act_cen     =1'b1;
                
                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = 16'd0;
                act_addr1 = 16'd0;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                finish = 0;
            end 
        endcase
    end
endmodule
module innerproduct7 (
    input wire [31:0] act0,
    input wire [31:0] act1,
    input wire [31:0] act2,
    input wire [31:0] act3,
    input wire [55:0] wt_row0,
    input wire [55:0] wt_row1,
    output [31:0] out_00,
    output [31:0] out_01,
    output [31:0] out_02,
    output [31:0] out_03,
    output [31:0] out_04,
    output [31:0] out_05,
    output [31:0] out_06,
    output [31:0] out_07, 
    output [31:0] out_08,
    output [31:0] out_09,
    output [31:0] out_010,
    output [31:0] out_011,

    output [31:0] out_10,
    output [31:0] out_11,
    output [31:0] out_12,
    output [31:0] out_13,
    output [31:0] out_14,
    output [31:0] out_15,
    output [31:0] out_16,
    output [31:0] out_17, 
    output [31:0] out_18,
    output [31:0] out_19,
    output [31:0] out_110,
    output [31:0] out_111
);
    wire signed [7:0] a0;
    wire signed [7:0] a1;
    wire signed [7:0] a2;
    wire signed [7:0] a3;
    wire signed [7:0] a4;
    wire signed [7:0] a5;
    wire signed [7:0] a6;
    wire signed [7:0] a7;
    wire signed [7:0] a8;
    wire signed [7:0] a9;
    wire signed [7:0] a10;
    wire signed [7:0] a11;
    wire signed [7:0] a12;
    wire signed [7:0] a13;
    wire signed [7:0] a14;
    wire signed [7:0] a15;
    wire signed [7:0] a16;
    wire signed [7:0] a17;

    assign a0 = 0;
    assign a1 = act0[ 7: 0];
    assign a2 = act0[15: 8];
    assign a3 = act0[23:16];
    assign a4 = act0[31:24];
    assign a5 = act1[ 7: 0];
    assign a6 = act1[15: 8];
    assign a7 = act1[23:16];
    assign a8 = act1[31:24];

    assign a9  = act2[ 7: 0];
    assign a10 = act2[15: 8];
    assign a11 = act2[23:16];
    assign a12 = act2[31:24];
    assign a13 = act3[ 7: 0];
    assign a14 = act3[15: 8];
    assign a15 = act3[23:16];
    assign a16 = act3[31:24];
    assign a17 = 0;

    wire signed [7:0] weight[1:0][6:0];

    assign weight[0][0] = wt_row0[ 7: 0];
    assign weight[0][1] = wt_row0[15: 8];
    assign weight[0][2] = wt_row0[23:16];
    assign weight[0][3] = wt_row0[31:24];
    assign weight[0][4] = wt_row0[39:32];
    assign weight[0][5] = wt_row0[47:40];
    assign weight[0][6] = wt_row0[55:48];

    assign weight[1][0] = wt_row1[ 7: 0];
    assign weight[1][1] = wt_row1[15: 8];
    assign weight[1][2] = wt_row1[23:16];
    assign weight[1][3] = wt_row1[31:24];
    assign weight[1][4] = wt_row1[39:32];
    assign weight[1][5] = wt_row1[47:40];
    assign weight[1][6] = wt_row1[55:48];
    
    assign out_00  = weight[0][0]*a0  + weight[0][1]*a1  + weight[0][2]*a2  + weight[0][3]*a3  + weight[0][4]*a4  + weight[0][5]*a5  + weight[0][6]*a6;
    assign out_01  = weight[0][0]*a1  + weight[0][1]*a2  + weight[0][2]*a3  + weight[0][3]*a4  + weight[0][4]*a5  + weight[0][5]*a6  + weight[0][6]*a7;
    assign out_02  = weight[0][0]*a2  + weight[0][1]*a3  + weight[0][2]*a4  + weight[0][3]*a5  + weight[0][4]*a6  + weight[0][5]*a7  + weight[0][6]*a8;
    assign out_03  = weight[0][0]*a3  + weight[0][1]*a4  + weight[0][2]*a5  + weight[0][3]*a6  + weight[0][4]*a7  + weight[0][5]*a8  + weight[0][6]*a9;
    assign out_04  = weight[0][0]*a4  + weight[0][1]*a5  + weight[0][2]*a6  + weight[0][3]*a7  + weight[0][4]*a8  + weight[0][5]*a9  + weight[0][6]*a10;
    assign out_05  = weight[0][0]*a5  + weight[0][1]*a6  + weight[0][2]*a7  + weight[0][3]*a8  + weight[0][4]*a9  + weight[0][5]*a10 + weight[0][6]*a11;
    assign out_06  = weight[0][0]*a6  + weight[0][1]*a7  + weight[0][2]*a8  + weight[0][3]*a9  + weight[0][4]*a10 + weight[0][5]*a11 + weight[0][6]*a12;
    assign out_07  = weight[0][0]*a7  + weight[0][1]*a8  + weight[0][2]*a9  + weight[0][3]*a10 + weight[0][4]*a11 + weight[0][5]*a12 + weight[0][6]*a13;
    assign out_08  = weight[0][0]*a8  + weight[0][1]*a9  + weight[0][2]*a10 + weight[0][3]*a11 + weight[0][4]*a12 + weight[0][5]*a13 + weight[0][6]*a14;
    assign out_09  = weight[0][0]*a9  + weight[0][1]*a10 + weight[0][2]*a11 + weight[0][3]*a12 + weight[0][4]*a13 + weight[0][5]*a14 + weight[0][6]*a15;
    assign out_010 = weight[0][0]*a10 + weight[0][1]*a11 + weight[0][2]*a12 + weight[0][3]*a13 + weight[0][4]*a14 + weight[0][5]*a15 + weight[0][6]*a16;
    assign out_011 = weight[0][0]*a11 + weight[0][1]*a12 + weight[0][2]*a13 + weight[0][3]*a14 + weight[0][4]*a15 + weight[0][5]*a16 + weight[0][6]*a17;

    assign out_10  = weight[1][0]*a0  + weight[1][1]*a1  + weight[1][2]*a2  + weight[1][3]*a3  + weight[1][4]*a4  + weight[1][5]*a5  + weight[1][6]*a6;
    assign out_11  = weight[1][0]*a1  + weight[1][1]*a2  + weight[1][2]*a3  + weight[1][3]*a4  + weight[1][4]*a5  + weight[1][5]*a6  + weight[1][6]*a7;
    assign out_12  = weight[1][0]*a2  + weight[1][1]*a3  + weight[1][2]*a4  + weight[1][3]*a5  + weight[1][4]*a6  + weight[1][5]*a7  + weight[1][6]*a8;
    assign out_13  = weight[1][0]*a3  + weight[1][1]*a4  + weight[1][2]*a5  + weight[1][3]*a6  + weight[1][4]*a7  + weight[1][5]*a8  + weight[1][6]*a9;
    assign out_14  = weight[1][0]*a4  + weight[1][1]*a5  + weight[1][2]*a6  + weight[1][3]*a7  + weight[1][4]*a8  + weight[1][5]*a9  + weight[1][6]*a10;
    assign out_15  = weight[1][0]*a5  + weight[1][1]*a6  + weight[1][2]*a7  + weight[1][3]*a8  + weight[1][4]*a9  + weight[1][5]*a10 + weight[1][6]*a11;
    assign out_16  = weight[1][0]*a6  + weight[1][1]*a7  + weight[1][2]*a8  + weight[1][3]*a9  + weight[1][4]*a10 + weight[1][5]*a11 + weight[1][6]*a12;
    assign out_17  = weight[1][0]*a7  + weight[1][1]*a8  + weight[1][2]*a9  + weight[1][3]*a10 + weight[1][4]*a11 + weight[1][5]*a12 + weight[1][6]*a13;
    assign out_18  = weight[1][0]*a8  + weight[1][1]*a9  + weight[1][2]*a10 + weight[1][3]*a11 + weight[1][4]*a12 + weight[1][5]*a13 + weight[1][6]*a14;
    assign out_19  = weight[1][0]*a9  + weight[1][1]*a10 + weight[1][2]*a11 + weight[1][3]*a12 + weight[1][4]*a13 + weight[1][5]*a14 + weight[1][6]*a15;
    assign out_110 = weight[1][0]*a10 + weight[1][1]*a11 + weight[1][2]*a12 + weight[1][3]*a13 + weight[1][4]*a14 + weight[1][5]*a15 + weight[1][6]*a16;
    assign out_111 = weight[1][0]*a11 + weight[1][1]*a12 + weight[1][2]*a13 + weight[1][3]*a14 + weight[1][4]*a15 + weight[1][5]*a16 + weight[1][6]*a17;

endmodule