module max2 (
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg finish,

    input wire [15:0] act_offset,
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
    reg [3:0]state,next_state;
    parameter [3:0] Pre =4'd0;
    parameter [3:0] LoadAct=4'd1;
    parameter [3:0] Comp=4'd2;
    
    parameter [3:0] Out0=4'd3;
    parameter [3:0] Out1=4'd4;
    parameter [3:0] Channel=4'd5;
    parameter [3:0] Waitend0=4'd6;
    parameter [3:0] Waitend1=4'd7;
    parameter [3:0] Waitend2=4'd8;

    parameter [3:0] Wait0=4'd10;
    parameter [3:0] Wait1=4'd11;
    parameter [3:0] Wait2=4'd12;
    parameter [3:0] Wait3=4'd13;
    parameter [3:0] Wait4=4'd14;
    parameter [3:0] Finish=4'd15;

    wire [7:0]plout0,plout1;
    maxpool8_2 mp82(
        .in0_0(act_rdata0[ 7: 0]) ,
        .in0_1(act_rdata0[15: 8]) ,
        .in0_2(act_rdata0[23:16]) ,
        .in0_3(act_rdata0[31:24]) ,
        .in1_0(act_rdata1[ 7: 0]) ,
        .in1_1(act_rdata1[15: 8]) ,
        .in1_2(act_rdata1[23:16]) ,
        .in1_3(act_rdata1[31:24]) ,
        .out0(plout0),
        .out1(plout1) 
    );
    
    reg [15:0] act_cnt,next_act_cnt;
    always @(posedge clk)begin
        if(!rst_n)
            act_cnt <= 0;
        else
            act_cnt <= next_act_cnt;    
    end
    always @(*)begin
        if(state==LoadAct||state==Wait0||state==Wait1||state==Comp)begin
            if(act_cnt<16'd6)
                next_act_cnt = act_cnt + 1;
            else
                next_act_cnt = 0; 
        end
        else begin
            next_act_cnt = 0; 
        end
        
    end

    reg [15:0] row_act_cnt,next_row_act_cnt;
    always @(posedge clk)begin
        if(!rst_n)
            row_act_cnt <= 0;
        else
            row_act_cnt <= next_row_act_cnt;    
    end
    always @(*)begin
        if(state==Out0)begin
            next_row_act_cnt = row_act_cnt + 2;
            
        end
        else if(state==Channel)begin
            next_row_act_cnt = 0;
        end
        else begin
            next_row_act_cnt = row_act_cnt;
        end
        
    end
    reg [15:0] cpact_cnt,next_cpact_cnt;
    always @(posedge clk)begin
        if(!rst_n)begin
            cpact_cnt <= 0;
        end
        else begin
            cpact_cnt <= next_cpact_cnt;
        end
    end
    always @(*)begin
        if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin 
            next_cpact_cnt = cpact_cnt + 2;
        end
        else
            next_cpact_cnt = 0;
    end
//outact
    integer i;
    reg [7:0]outact [4:0];
    reg [7:0]next_outact [4:0];
    
    always @(posedge clk)begin
        if(!rst_n)begin
            for(i = 0; i <5;i=i+1)begin
                outact[i]<=0;
            end
        end
        else begin
            for(i = 0; i <5;i=i+1)begin
                outact[i]<=next_outact[i];
            end
        end
    end
    always @(*)begin
        for(i = 0; i <5;i=i+1)begin
            next_outact[i]=outact[i];
        end
        if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
            next_outact[cpact_cnt]  =plout0;
            next_outact[cpact_cnt+1]=plout1;
        end
        else if(state==LoadAct)begin
            for(i = 0; i <5;i=i+1)begin
                next_outact[i]=0;
            end
        end

        else begin
            for(i = 0; i <5;i=i+1)begin
                next_outact[i]=outact[i];
            end
        end
    end
    //channel
    reg [7:0]channel,next_channel;
    always @(posedge clk)begin
        if(!rst_n)begin
            channel <= 0;
        end
        else
            channel <= next_channel;
    end
    always @(*)begin
        if(state==Channel)begin
            next_channel = channel+1;
        end
        else if(state==Pre)begin
            next_channel =0;
        end
        else begin
            next_channel = channel;
        end
    end

    always @(posedge clk)begin
        if(!rst_n)
            state <= 0;
        else
            state <= next_state;    
    end
    always @(*)begin
        case(state)
            Pre:begin
                weight_cen  =1;
                act_cen     =1;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 0;
                act_addr1 = 0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                if(start==1'b1)begin
                    next_state=LoadAct;
                end
                else begin
                    next_state=Pre;
                end
            end
            Channel:begin
                weight_cen  =1;
                act_cen     =1;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 0;
                act_addr1 = 0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                next_state=LoadAct;
            end
            LoadAct:begin
                weight_cen  =1;
                act_cen     =0;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 16'd2200 + channel*30 + row_act_cnt      * 3 + act_cnt;
                act_addr1 = 16'd2200 + channel*30 + (row_act_cnt+1)  * 3 + act_cnt;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                next_state=Wait0;
            end
            Wait0:begin
                weight_cen  =1;
                act_cen     =0;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 16'd2200 + channel*30 + row_act_cnt      * 3 + act_cnt;
                act_addr1 = 16'd2200 + channel*30 + (row_act_cnt+1)  * 3 + act_cnt;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                next_state=Wait1;
            end
            Wait1:begin
                weight_cen  =1;
                act_cen     =0;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 16'd2200 + channel*30 + row_act_cnt      * 3 + act_cnt;
                act_addr1 = 16'd2200 + channel*30 + (row_act_cnt+1)  * 3 + act_cnt;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                next_state=Wait2;
            end
            Wait2:begin
                weight_cen  =1;
                act_cen     =1;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 0;
                act_addr1 = 0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                next_state=Wait3;
            end
            Wait3:begin
                weight_cen  =1;
                act_cen     =1;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 0;
                act_addr1 = 0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                next_state=Wait4;
            end
            Wait4:begin
                weight_cen  =1;
                act_cen     =1;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 0;
                act_addr1 = 0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                next_state=Out0;
            end
            Out0:begin
                weight_cen  =1;
                act_cen     =0;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = act_offset + (( channel*5+row_act_cnt[7:1] )>>2 )*5 +  ( channel*5+row_act_cnt[7:1] )%4; //4 row cost 5 words
                act_addr1 = act_offset + (( channel*5+row_act_cnt[7:1] )>>2 )*5 +  ( channel*5+row_act_cnt[7:1] )%4 +1;
                
                
                case(( channel*5+row_act_cnt[7:1] )%4)
                    0:begin
                        act_wdata0 = {outact[3], outact[2], outact[1], outact[0]};
                        act_wdata1 = { 24'd0,outact[4] };
                        act_wea0 = 4'b1111;
                        act_wea1 = 4'b0001;
                    end
                    1:begin
                        act_wdata0 = {outact[2], outact[1], outact[0], 8'd0 };
                        act_wdata1 = { 16'd0,outact[4], outact[3] };
                        act_wea0 = 4'b1110;
                        act_wea1 = 4'b0011;
                    end
                    2:begin
                        act_wdata0 = { outact[1], outact[0],16'd0 };
                        act_wdata1 = { 8'd0,outact[4], outact[3], outact[2] };
                        act_wea0 = 4'b1100;
                        act_wea1 = 4'b0111;
                    end
                    3:begin
                        act_wdata0 = { outact[0],24'd0 };
                        act_wdata1 = { outact[4], outact[3], outact[2], outact[1] };
                        act_wea0 = 4'b1000;
                        act_wea1 = 4'b1111;
                    end
                    default:begin
                        act_wdata0 = 0;
                        act_wdata1 = 0;
                        act_wea0 = 4'b0000;
                        act_wea1 = 4'b0000;
                    end
                endcase
                finish = 0;
                if(channel==15)begin
                    if(row_act_cnt==8)
                        next_state=Waitend0;
                    else
                        next_state=LoadAct;
                end
                else begin
                    if(row_act_cnt==8)
                        next_state=Channel;
                    else
                        next_state=LoadAct;
                end
            end
            Waitend0:begin
                weight_cen  =1;
                act_cen     =1;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 0;
                act_addr1 = 0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                next_state = Waitend1;
            end
            Waitend1:begin
                weight_cen  =1;
                act_cen     =1;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 0;
                act_addr1 = 0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                next_state = Waitend2;
            end
            Waitend2:begin
                weight_cen  =1;
                act_cen     =1;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 0;
                act_addr1 = 0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                next_state = Finish;
            end
            Finish:begin
                weight_cen  =1;
                act_cen     =1;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 0;
                act_addr1 = 0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state = Pre;
                finish=1;
            end
            default:begin
                weight_cen  =1;
                act_cen     =1;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 0;
                act_addr1 = 0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                next_state = Pre;
            end
        endcase
    end

endmodule
