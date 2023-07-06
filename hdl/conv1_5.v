module conv1_5(
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

    reg [3:0] state;
    reg [3:0] next_state;
    
    parameter [3:0] Pre=4'd0;
    parameter [3:0] Outchannel=4'd1;
    parameter [3:0] LoadWeight=4'd2;
    parameter [3:0] LoadAct=4'd3;
    parameter [3:0] Comp=4'd4;
    parameter [3:0] PoolingQuan=4'd5;


    parameter [3:0] Finish=4'd9;
    parameter [3:0] Wait0=4'd10;
    parameter [3:0] Wait1=4'd11;
    parameter [3:0] Setback=4'd12;
    parameter [3:0] Wait3=4'd13;
    parameter [3:0] Wait4=4'd14;
    parameter [3:0] Wait5=4'd15;
    parameter [3:0] Waitend1=4'd6;
    parameter [3:0] Waitend0=4'd7;


    reg [31:0]activation0;
    reg [31:0]activation1;
    reg [39:0]wt_row0;
    reg [39:0]wt_row1;
    wire signed [31:0]comp_res[1:0][3:0];
    innerproduct8_2 inpro8_2(
        .act0(activation0),
        .act1(activation1),
        .wt_row0(wt_row0),
        .wt_row1(wt_row1),
        .out_00(comp_res[0][0]),
        .out_01(comp_res[0][1]),
        .out_02(comp_res[0][2]),
        .out_03(comp_res[0][3]),    
        .out_10(comp_res[1][0]),
        .out_11(comp_res[1][1]),
        .out_12(comp_res[1][2]),
        .out_13(comp_res[1][3])
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

    reg signed[ 7:0]weights2D[4:0][4:0];
    

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
            if(loading_row_weight==4)next_loading_row_weight=4;
            else next_loading_row_weight =loading_row_weight+1;
        end  
        else begin
            next_loading_row_weight = 0;
        end
    end
    //save weight to array
    reg [39:0]next_save_weight;
    always@(*)begin
        if (state==LoadWeight )begin
            next_save_weight = {weight_rdata1[7:0] , weight_rdata0};
        end  
        else begin
            next_save_weight = 0;
        end
    end

    integer i;
    integer j;
    always@(posedge clk) begin
        if(!rst_n) begin
            for (i=0;i<5;i=i+1)begin
                for (j=0;j<5;j=j+1)begin
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
            end
            
        end
    end
    
    //row act
    reg [7:0]row_act_cnt;
    reg [7:0]next_row_act_cnt;
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
            if(state==LoadAct||state==Wait0||state==Wait1||state==Comp)begin
                if (row_act_cnt==5)begin
                    next_row_act_cnt=0;
                end
                else begin
                    next_row_act_cnt = row_act_cnt+8'd1; 
                    
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
            if (col_act_cnt==24)begin
                next_col_act_cnt=0;
            end
            else begin
                next_col_act_cnt = col_act_cnt + 16'd4;
            end
        end
        else begin
            next_col_act_cnt = col_act_cnt;
        end
    end

    reg [7:0]rowstart_cnt;
    reg [7:0]next_rowstart_cnt;
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
            if (col_act_cnt==24)begin
                next_rowstart_cnt = rowstart_cnt+8'd2;
            end
            else begin
                next_rowstart_cnt=rowstart_cnt;
            end
        end
        else begin
            if(state==LoadAct||state==Wait0||state==Wait1||state==Comp)begin
                next_rowstart_cnt=rowstart_cnt;
            end
            else next_rowstart_cnt =0;
        end
    end

    //computing activation
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

    //save the psum
    //output array for a channel
    reg signed [31:0] out_act[1:0][3:0];
    reg signed [31:0] next_out_psum[4:0][3:0]; 
    //integer i,j;
    always@(posedge clk)begin
        if(!rst_n) begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    out_act[i][j]<=0;
                end
            end
        end
        else begin 
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    out_act[i][j] <= next_out_psum[i][j];
                end
            end
            
        end
        
    end
    //combinational saving and adding the psum 
    always @(*)begin
        if(state==Comp)begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    next_out_psum[i][j] = out_act[i][j]+comp_res[i][j];
                end
            end
        end
        else begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    next_out_psum[i][j] = 0;
                end

            end
        end
    end
    //combinational for asserting the intput for conv
    always @(*)begin
        if(state==Comp/*||state==PoolingQuan*/)begin
            //data for computing
            case(cpact_row)
                8'd0:begin
                    wt_row0 = {weights2D[0][4],weights2D[0][3],weights2D[0][2],weights2D[0][1],weights2D[0][0]};
                    wt_row1 = 0;
                end
                8'd5:begin
                    wt_row0 = 0;
                    wt_row1 = {weights2D[4][4],weights2D[4][3],weights2D[4][2],weights2D[4][1],weights2D[4][0]};
                end
                default:begin
                    wt_row0 = {weights2D[cpact_row][4],weights2D[cpact_row][3],weights2D[cpact_row][2],weights2D[cpact_row][1],weights2D[cpact_row][0]};
                    wt_row1 = {weights2D[cpact_row-1][4],weights2D[cpact_row-1][3],weights2D[cpact_row-1][2],weights2D[cpact_row-1][1],weights2D[cpact_row-1][0]};
                end
            endcase
            activation0 = act_rdata0;
            activation1 = act_rdata1;
        end
        else begin
            wt_row0 = 0;
            wt_row1 = 0;
            activation0=0;
            activation1=0;
        end
    end

 

    always @(*)begin
        if(state==PoolingQuan)begin
            for(i=0;i<2;i=i+1)begin
                for(j=0;j<4 ;j=j+1)begin
                    prq_in[i][j] = out_act[i][j];
                end
            end
        end
        else begin
            for(i=0;i<2;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    prq_in[i][j] = 0;
                end
            end
        end
    end

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
                weight_addr0=weight_offset + out_channel*10 + row_weight_cnt*2;
                weight_addr1=weight_offset + out_channel*10 + row_weight_cnt*2 + 1;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 16'd0;
                act_addr1 = 16'd0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                if(row_weight_cnt==7)begin
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
                act_addr0 = act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]};
                act_addr1 = act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]}+1;
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
                act_addr0= act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]};
                act_addr1= act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]}+1;
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
                act_addr0= act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]};
                act_addr1= act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]}+1;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state=Comp;
                finish = 0;
            end
            Comp:begin
                if(cpact_row>=3)begin
                    weight_cen  =1'b1;
                    act_cen     =1'b1;
                end
                else begin
                    weight_cen  =1'b1;
                    act_cen     =1'b0;
                end
                

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                //load data (3 cycle later)
                act_addr0=  act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]};
                act_addr1=  act_offset + rowstart_cnt*8 + row_act_cnt*16'd8 + {10'b0,col_act_cnt [7:2]} + 1;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                if(cpact_row==8'd5 )begin
                    next_state=PoolingQuan;

                end
                else begin
                    next_state=Comp;
                end
                finish = 0;
            end 
            PoolingQuan:begin
                weight_cen  =1'b1;
                act_cen     =1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = 16'd1024 + out_channel*196 + rowstart_cnt*7 + cpact_col[7:2];//7=14/2
                act_addr1 = 16'd1024 + out_channel*196 + (rowstart_cnt+1)*7 + cpact_col[7:2];
                
                act_wdata0  = quanout0;//debug
                act_wea0    = 4'b1111;
                act_wdata1  = quanout1;
                act_wea1    = 4'b1111;
                

                if(rowstart_cnt==26&&cpact_col==24)begin
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
                weight_cen  =1'b0;
                act_cen     =1'b0;
                
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


//innerproduct module
module innerproduct8_2(
    
    input wire [31:0] act0,
    input wire [31:0] act1,
    input wire signed [39:0] wt_row0,
    input wire signed [39:0] wt_row1,

    output signed [31:0] out_00,
    output signed [31:0] out_01,
    output signed [31:0] out_02,
    output signed [31:0] out_03,
    output signed [31:0] out_10,
    output signed [31:0] out_11,
    output signed [31:0] out_12,
    output signed [31:0] out_13
);

    wire signed [7:0] a0;
    wire signed [7:0] a1;
    wire signed [7:0] a2;
    wire signed [7:0] a3;
    wire signed [7:0] a4;
    wire signed [7:0] a5;
    wire signed [7:0] a6;
    wire signed [7:0] a7;
    assign a0 = act0[ 7: 0];
    assign a1 = act0[15: 8];
    assign a2 = act0[23:16];
    assign a3 = act0[31:24];
    assign a4 = act1[ 7: 0];
    assign a5 = act1[15: 8];
    assign a6 = act1[23:16];
    assign a7 = act1[31:24];

    wire signed [7:0] weight[1:0][4:0];

    assign weight[0][0] = wt_row0[ 7: 0];
    assign weight[0][1] = wt_row0[15: 8];
    assign weight[0][2] = wt_row0[23:16];
    assign weight[0][3] = wt_row0[31:24];
    assign weight[0][4] = wt_row0[39:32];
    assign weight[1][0] = wt_row1[ 7: 0];
    assign weight[1][1] = wt_row1[15: 8];
    assign weight[1][2] = wt_row1[23:16];
    assign weight[1][3] = wt_row1[31:24];
    assign weight[1][4] = wt_row1[39:32];
    
    //calculating
    assign out_00 = weight[0][0]*a0 + weight[0][1]*a1 + weight[0][2]*a2 + weight[0][3]*a3 + weight[0][4]*a4;
    assign out_01 = weight[0][0]*a1 + weight[0][1]*a2 + weight[0][2]*a3 + weight[0][3]*a4 + weight[0][4]*a5;
    assign out_02 = weight[0][0]*a2 + weight[0][1]*a3 + weight[0][2]*a4 + weight[0][3]*a5 + weight[0][4]*a6;
    assign out_03 = weight[0][0]*a3 + weight[0][1]*a4 + weight[0][2]*a5 + weight[0][3]*a6 + weight[0][4]*a7;
    assign out_10 = weight[1][0]*a0 + weight[1][1]*a1 + weight[1][2]*a2 + weight[1][3]*a3 + weight[1][4]*a4;
    assign out_11 = weight[1][0]*a1 + weight[1][1]*a2 + weight[1][2]*a3 + weight[1][3]*a4 + weight[1][4]*a5;
    assign out_12 = weight[1][0]*a2 + weight[1][1]*a3 + weight[1][2]*a4 + weight[1][3]*a5 + weight[1][4]*a6;
    assign out_13 = weight[1][0]*a3 + weight[1][1]*a4 + weight[1][2]*a5 + weight[1][3]*a6 + weight[1][4]*a7;

   
endmodule

/*
//pooling Relu module
module reluQuan8(
    input wire signed [31:0] scale,

    input wire signed [31:0] in0_0 ,
    input wire signed [31:0] in0_1 ,
    input wire signed [31:0] in0_2 ,
    input wire signed [31:0] in0_3 ,
    input wire signed [31:0] in1_0 ,
    input wire signed [31:0] in1_1 ,
    input wire signed [31:0] in1_2 ,
    input wire signed [31:0] in1_3 ,
    output [31:0] out0 ,
    output [31:0] out1

);

//ReLu
    wire signed [31:0] relu0_0 ;
    wire signed [31:0] relu0_1 ;
    wire signed [31:0] relu0_2 ;
    wire signed [31:0] relu0_3 ;
    wire signed [31:0] relu1_0 ;
    wire signed [31:0] relu1_1 ;
    wire signed [31:0] relu1_2 ;
    wire signed [31:0] relu1_3 ;

    assign relu0_0  = (!in0_0 [31]) ? in0_0  : 0;
    assign relu0_1  = (!in0_1 [31]) ? in0_1  : 0;
    assign relu0_2  = (!in0_2 [31]) ? in0_2  : 0;
    assign relu0_3  = (!in0_3 [31]) ? in0_3  : 0;
    assign relu1_0  = (!in1_0 [31]) ? in1_0  : 0;
    assign relu1_1  = (!in1_1 [31]) ? in1_1  : 0;
    assign relu1_2  = (!in1_2 [31]) ? in1_2  : 0;
    assign relu1_3  = (!in1_3 [31]) ? in1_3  : 0;


//quantize
    wire signed [63:0] sc0_0;
    wire signed [63:0] sc0_1;
    wire signed [63:0] sc0_2;
    wire signed [63:0] sc0_3;
    wire signed [63:0] sc1_0;
    wire signed [63:0] sc1_1;
    wire signed [63:0] sc1_2;
    wire signed [63:0] sc1_3;

    assign sc0_0 = relu0_0 * scale;
    assign sc0_1 = relu0_1 * scale;
    assign sc0_2 = relu0_2 * scale;
    assign sc0_3 = relu0_3 * scale;
    assign sc1_0 = relu1_0 * scale;
    assign sc1_1 = relu1_1 * scale;
    assign sc1_2 = relu1_2 * scale;
    assign sc1_3 = relu1_3 * scale;

    wire signed [7:0] clamp0_0;
    wire signed [7:0] clamp0_1;
    wire signed [7:0] clamp0_2;
    wire signed [7:0] clamp0_3;
    wire signed [7:0] clamp1_0;
    wire signed [7:0] clamp1_1;
    wire signed [7:0] clamp1_2;
    wire signed [7:0] clamp1_3;

    assign clamp0_0 = (sc0_0[63:23]==0) ? sc0_0[23:16] : 8'd127;
    assign clamp0_1 = (sc0_1[63:23]==0) ? sc0_1[23:16] : 8'd127;
    assign clamp0_2 = (sc0_2[63:23]==0) ? sc0_2[23:16] : 8'd127;
    assign clamp0_3 = (sc0_3[63:23]==0) ? sc0_3[23:16] : 8'd127;
    assign clamp1_0 = (sc1_0[63:23]==0) ? sc1_0[23:16] : 8'd127;
    assign clamp1_1 = (sc1_1[63:23]==0) ? sc1_1[23:16] : 8'd127;
    assign clamp1_2 = (sc1_2[63:23]==0) ? sc1_2[23:16] : 8'd127;
    assign clamp1_3 = (sc1_3[63:23]==0) ? sc1_3[23:16] : 8'd127;

    assign out0 = { clamp0_3,clamp0_2,clamp0_1,clamp0_0 };
    assign out1 = { clamp1_3,clamp1_2,clamp1_1,clamp1_0 };

endmodule
*/