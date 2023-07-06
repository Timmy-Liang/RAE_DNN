//`define L1_BUFFER

module RAE(
    input               clk,
    input               rst_n,
    input       [23:0]  conf,
    input               valid,
    output reg          ready,
    output reg  [1:0]   status,

    // Dual-port weight ports
    output reg          sram_weight_cen,
    output reg  [ 3:0]  sram_weight_wea0,
    output reg  [15:0]  sram_weight_addr0,
    output reg  [31:0]  sram_weight_wdata0,
    input       [31:0]  sram_weight_rdata0,
    output reg  [ 3:0]  sram_weight_wea1,
    output reg  [15:0]  sram_weight_addr1,
    output reg  [31:0]  sram_weight_wdata1,
    input       [31:0]  sram_weight_rdata1,

    // Dual-port activation ports
    output reg         sram_act_cen,
    output reg  [ 3:0] sram_act_wea0,
    output reg  [15:0] sram_act_addr0,
    output reg  [31:0] sram_act_wdata0,
    input       [31:0] sram_act_rdata0,
    output reg  [ 3:0] sram_act_wea1,
    output reg  [15:0] sram_act_addr1,
    output reg  [31:0] sram_act_wdata1,
    input       [31:0] sram_act_rdata1
);

// Add your design here
    reg [23:0] conf_buf  ;
    reg        valid_buf ;
    reg        ready_buf ;
    reg  [1:0] status_buf;
    // Weight sram; dual port
    reg L2_weight_cen;
    reg [ 3:0] L2_weight_wea0;
    reg [15:0] L2_weight_addr0;
    reg [31:0] L2_weight_wdata0;
    reg [31:0] L2_weight_rdata0;
    reg [ 3:0] L2_weight_wea1;
    reg [15:0] L2_weight_addr1;
    reg [31:0] L2_weight_wdata1;
    reg [31:0] L2_weight_rdata1;

    // Activation sram; dual port
    reg L2_act_cen;
    reg [ 3:0] L2_act_wea0;
    reg [15:0] L2_act_addr0;
    reg [31:0] L2_act_wdata0;
    reg [31:0] L2_act_rdata0;
    reg [ 3:0] L2_act_wea1;
    reg [15:0] L2_act_addr1;
    reg [31:0] L2_act_wdata1;
    reg [31:0] L2_act_rdata1;
    
    //buffering
    always @(posedge clk)begin
        if(!rst_n)begin
            conf_buf        <= 0;
            valid_buf       <= 0;
            ready           <= 0;
            status          <= 0;

            L2_weight_rdata0   <= 0;
            L2_weight_rdata1   <= 0;
            L2_act_rdata1      <= 0;//in
            L2_act_rdata0      <= 0;//in

            sram_weight_cen     <= 0;
            sram_weight_wea0    <= 0;
            sram_weight_addr0   <= 0;
            sram_weight_wdata0  <= 0;
            sram_weight_wea1    <= 0;
            sram_weight_addr1   <= 0;
            sram_weight_wdata1  <= 0;

            sram_act_cen        <= 0;    
            sram_act_wea0       <= 0;
            sram_act_addr0      <= 0;
            sram_act_wdata0     <= 0;
            sram_act_wea1       <= 0;
            sram_act_addr1      <= 0;
            sram_act_wdata1     <= 0;
        end
        else begin
            conf_buf        <= conf;
            valid_buf       <= valid;
            ready           <= ready_buf;
            status          <= status_buf;
            L2_weight_rdata0   <= sram_weight_rdata0;
            L2_weight_rdata1   <= sram_weight_rdata1;
            L2_act_rdata0      <= sram_act_rdata0;//in
            L2_act_rdata1      <= sram_act_rdata1;//in

            // Weight sram; dual port
            sram_weight_cen     <= L2_weight_cen;
            sram_weight_wea0    <= L2_weight_wea0;
            sram_weight_addr0   <= L2_weight_addr0;
            sram_weight_wdata0  <= L2_weight_wdata0;
            sram_weight_wea1    <= L2_weight_wea1;
            sram_weight_addr1   <= L2_weight_addr1;
            sram_weight_wdata1  <= L2_weight_wdata1;
            // Activation sram; dual port
            sram_act_cen        <= L2_act_cen;
            sram_act_wea0       <= L2_act_wea0;
            sram_act_addr0      <= L2_act_addr0;
            sram_act_wdata0     <= L2_act_wdata0;
            sram_act_wea1       <= L2_act_wea1;
            sram_act_addr1      <= L2_act_addr1;
            sram_act_wdata1     <= L2_act_wdata1;
        end
    end


    





    reg [7:0] state;
    reg [7:0] next_state;
    parameter [7:0] Pre         =8'd0;
    parameter [7:0] C1_Load     =8'd10;
    parameter [7:0] StConv1_3   =8'd12;
    parameter [7:0] Conv1_3     =8'd13;
    parameter [7:0] StConv1_5   =8'd14;
    parameter [7:0] Conv1_5     =8'd15;
    parameter [7:0] StConv1_7   =8'd16;
    parameter [7:0] Conv1_7     =8'd17;
    parameter [7:0] C1_Loadback =8'd19;

    parameter [7:0] StMax1      =8'd80;
    parameter [7:0] Max1        =8'd81;
    parameter [7:0] StMax2      =8'd84;
    parameter [7:0] Max2        =8'd85;

    parameter [7:0] StConv2_5   =8'd24;
    parameter [7:0] Conv2_5     =8'd25;
    parameter [7:0] StConv2_7   =8'd26;
    parameter [7:0] Conv2_7     =8'd27;
    parameter [7:0] StConv3     =8'd34;
    parameter [7:0] Conv3       =8'd35;
    parameter [7:0] StFc6       =8'd64;
    parameter [7:0] Fc6         =8'd65;
    parameter [7:0] StFc7       =8'd74;
    parameter [7:0] Fc7         =8'd75;

    parameter [7:0] Finish   =8'd100;
    parameter [7:0] Test     =8'hFF;

    reg [1:0]   TYPE,TYPE_reg; 
    reg         RELU,RELU_reg; 
    reg [2:0]   H,H_reg;  
    reg [1:0]   R,R_reg;  
    reg [2:0]   C,C_reg;   
    reg [2:0]   K,K_reg;    
    reg         P,P_reg;    
    reg [8:0]   SCALE,SCALE_reg; 
//decode conf bits
    always @(*)begin
        if(state==Pre && valid_buf==1)begin
            TYPE = conf_buf[23:22];
            RELU = conf_buf[   21];
            H    = conf_buf[20:18];  
            R    = conf_buf[17:16];  
            C    = conf_buf[15:13];   
            K    = conf_buf[12:10];   
            P    = conf_buf[    9];   
            SCALE= conf_buf[ 8: 0]; 
        end
        else begin //valid ==0
            TYPE = TYPE_reg ;
            RELU = RELU_reg ;
            H    = H_reg    ;  
            R    = R_reg    ;  
            C    = C_reg    ;   
            K    = K_reg    ;   
            P    = P_reg    ;   
            SCALE= SCALE_reg;
        end
    end
    always @(posedge clk)begin
        if(!rst_n)begin
            TYPE_reg <= 0;
            RELU_reg <= 0;
            H_reg    <= 0;  
            R_reg    <= 0;  
            C_reg    <= 0;   
            K_reg    <= 0;   
            P_reg    <= 0;   
            SCALE_reg<= 0; 
        end  
        else begin
            TYPE_reg <= TYPE ;
            RELU_reg <= RELU ;
            H_reg    <= H    ;  
            R_reg    <= R    ;  
            C_reg    <= C    ;   
            K_reg    <= K    ;   
            P_reg    <= P    ;   
            SCALE_reg<= SCALE; 
        end  
    end
    
    wire [31:0] scale;
    assign scale = {23'b0,SCALE_reg};

    reg [15:0] weight_offset;
    reg [15:0] next_weight_offset;
    always @(posedge clk)begin
        if(!rst_n)begin
            weight_offset <= 0;
        end
        else begin
            weight_offset <= next_weight_offset;
        end
    end
    
    reg [15:0] act_offset;
    reg [15:0] next_act_offset;
    always @(posedge clk)begin
        if(!rst_n)begin
            act_offset <= 0;
        end
        else begin
            act_offset <= next_act_offset;
        end
    end

//child module
    //Conv 1_3
    reg c13_start;
    reg next_c13_start;
    wire c13_finish;
    always @(posedge clk)begin
        if(!rst_n)begin
            c13_start <= 0;
        end
        else begin
            c13_start <= next_c13_start;
        end
    end
    always @*begin
        if(state==StConv1_3)begin
            next_c13_start = 1;
        end
        else begin
            next_c13_start = 0;
        end
    end
    wire        c13_weight_cen;
    wire [ 3:0] c13_weight_wea0;
    wire [ 3:0] c13_weight_wea1;
    wire [15:0] c13_weight_addr0;
    wire [15:0] c13_weight_addr1;
    wire        c13_act_cen;
    wire [ 3:0] c13_act_wea0;
    wire [15:0] c13_act_addr0;
    wire [31:0] c13_act_wdata0;
    wire [ 3:0] c13_act_wea1;
    wire [15:0] c13_act_addr1;
    wire [31:0] c13_act_wdata1;

    conv1_3 c13( 
        .clk(clk),
        .rst_n(rst_n),
        .start(c13_start),
        .finish(c13_finish),
        //weight
        .weight_offset(weight_offset),
        .act_offset(act_offset),
        .sc_CONV1(scale),
        .weight_cen(c13_weight_cen),
        .weight_wea0(c13_weight_wea0),
        .weight_addr0(c13_weight_addr0),
        .weight_rdata0(L2_weight_rdata0),
        .weight_wea1(c13_weight_wea1),
        .weight_addr1(c13_weight_addr1),
        .weight_rdata1(L2_weight_rdata1),

        // Activation sram, dual port
        .act_cen(c13_act_cen),
        .act_wea0  (c13_act_wea0  ),
        .act_addr0 (c13_act_addr0 ),
        .act_wdata0(c13_act_wdata0),
        .act_rdata0(L2_act_rdata0   ),
        .act_wea1  (c13_act_wea1  ),
        .act_addr1 (c13_act_addr1 ),
        .act_wdata1(c13_act_wdata1),
        .act_rdata1(L2_act_rdata1   )
    );

    //Conv 1_5
    reg c15_start;
    reg next_c15_start;
    wire c15_finish;
    always @(posedge clk)begin
        if(!rst_n)begin
            c15_start <= 0;
        end
        else begin
            c15_start <= next_c15_start;
        end
    end
    always @*begin
        if(state==StConv1_5)begin
            next_c15_start = 1;
        end
        else begin
            next_c15_start = 0;
        end
    end
    wire        c15_weight_cen;
    wire [ 3:0] c15_weight_wea0;
    wire [ 3:0] c15_weight_wea1;
    wire [15:0] c15_weight_addr0;
    wire [15:0] c15_weight_addr1;
    wire        c15_act_cen;
    wire [ 3:0] c15_act_wea0;
    wire [15:0] c15_act_addr0;
    wire [31:0] c15_act_wdata0;
    wire [ 3:0] c15_act_wea1;
    wire [15:0] c15_act_addr1;
    wire [31:0] c15_act_wdata1;

    conv1_5 c15( 
        .clk(clk),
        .rst_n(rst_n),
        .start(c15_start),
        .finish(c15_finish),
        //weight
        .weight_offset(weight_offset),
        .act_offset(act_offset),
        .sc_CONV1(scale),
        .weight_cen(c15_weight_cen),
        .weight_wea0(c15_weight_wea0),
        .weight_addr0(c15_weight_addr0),
        .weight_rdata0(L2_weight_rdata0),
        .weight_wea1(c15_weight_wea1),
        .weight_addr1(c15_weight_addr1),
        .weight_rdata1(L2_weight_rdata1),

        // Activation sram, dual port
        .act_cen(c15_act_cen),
        .act_wea0  (c15_act_wea0  ),
        .act_addr0 (c15_act_addr0 ),
        .act_wdata0(c15_act_wdata0),
        .act_rdata0(L2_act_rdata0   ),
        .act_wea1  (c15_act_wea1  ),
        .act_addr1 (c15_act_addr1 ),
        .act_wdata1(c15_act_wdata1),
        .act_rdata1(L2_act_rdata1   )
    );

    //conv1_7
    reg c17_start;
    reg next_c17_start;
    wire c17_finish;
    always @(posedge clk)begin
        if(!rst_n)begin
            c17_start <= 0;
        end
        else begin
            c17_start <= next_c17_start;
        end
    end
    always @*begin
        if(state==StConv1_7)begin
            next_c17_start = 1;
        end
        else begin
            next_c17_start = 0;
        end
    end
    wire        c17_weight_cen;
    wire [ 3:0] c17_weight_wea0;
    wire [ 3:0] c17_weight_wea1;
    wire [15:0] c17_weight_addr0;
    wire [15:0] c17_weight_addr1;
    wire        c17_act_cen;
    wire [ 3:0] c17_act_wea0;
    wire [15:0] c17_act_addr0;
    wire [31:0] c17_act_wdata0;
    wire [ 3:0] c17_act_wea1;
    wire [15:0] c17_act_addr1;
    wire [31:0] c17_act_wdata1;

    conv1_7 c17( 
        .clk(clk),
        .rst_n(rst_n),
        .start(c17_start),
        .finish(c17_finish),
        //weight
        .weight_offset(weight_offset),
        .act_offset(act_offset),
        .sc_CONV1(scale),
        .weight_cen(c17_weight_cen),
        .weight_wea0(c17_weight_wea0),
        .weight_addr0(c17_weight_addr0),
        .weight_rdata0(L2_weight_rdata0),
        .weight_wea1(c17_weight_wea1),
        .weight_addr1(c17_weight_addr1),
        .weight_rdata1(L2_weight_rdata1),

        // Activation sram, dual port
        .act_cen(c17_act_cen),
        .act_wea0  (c17_act_wea0  ),
        .act_addr0 (c17_act_addr0 ),
        .act_wdata0(c17_act_wdata0),
        .act_rdata0(L2_act_rdata0   ),
        .act_wea1  (c17_act_wea1  ),
        .act_addr1 (c17_act_addr1 ),
        .act_wdata1(c17_act_wdata1),
        .act_rdata1(L2_act_rdata1   )
    );
    //Max1
    reg m1_start;
    reg next_m1_start;
    wire m1_finish;
    always @(posedge clk)begin
        if(!rst_n)begin
            m1_start <= 0;
        end
        else begin
            m1_start <= next_m1_start;
        end
    end
    always @*begin
        if(state==StMax1 )begin
            next_m1_start = 1;
        end
        else begin
            next_m1_start = 0;
        end
    end
    wire        m1_weight_cen;
    wire [ 3:0] m1_weight_wea0;
    wire [ 3:0] m1_weight_wea1;
    wire [15:0] m1_weight_addr0;
    wire [15:0] m1_weight_addr1;
    wire        m1_act_cen;
    wire [ 3:0] m1_act_wea0;
    wire [15:0] m1_act_addr0;
    wire [31:0] m1_act_wdata0;
    wire [ 3:0] m1_act_wea1;
    wire [15:0] m1_act_addr1;
    wire [31:0] m1_act_wdata1;
    max1 m1(
        .clk(clk),
        .rst_n(rst_n),
        .start(m1_start),
        .finish(m1_finish),
        .act_offset(act_offset),
        //weight
        .weight_cen(m1_weight_cen),
        .weight_wea0(m1_weight_wea0),
        .weight_addr0(m1_weight_addr0),
        .weight_rdata0(L2_weight_rdata0),
        .weight_wea1(m1_weight_wea1),
        .weight_addr1(m1_weight_addr1),
        .weight_rdata1(L2_weight_rdata1),

        // Activation sram, dual port
        .act_cen(m1_act_cen),
        .act_wea0  (m1_act_wea0  ),
        .act_addr0 (m1_act_addr0 ),
        .act_wdata0(m1_act_wdata0),
        .act_rdata0(L2_act_rdata0   ),
        .act_wea1  (m1_act_wea1  ),
        .act_addr1 (m1_act_addr1 ),
        .act_wdata1(m1_act_wdata1),
        .act_rdata1(L2_act_rdata1   )
    );
    //Conv 2_5
    reg c25_start;
    reg next_c25_start;
    wire c25_finish;
    always @(posedge clk)begin
        if(!rst_n)begin
            c25_start <= 0;
        end
        else begin
            c25_start <= next_c25_start;
        end
    end
    always @*begin
        if(state==StConv2_5 )begin
            next_c25_start = 1;
        end
        else begin
            next_c25_start = 0;
        end
    end
    
    wire        c25_weight_cen;
    wire [ 3:0] c25_weight_wea0;
    wire [ 3:0] c25_weight_wea1;
    wire [15:0] c25_weight_addr0;
    wire [15:0] c25_weight_addr1;
    wire        c25_act_cen;
    wire [ 3:0] c25_act_wea0;
    wire [15:0] c25_act_addr0;
    wire [31:0] c25_act_wdata0;
    wire [ 3:0] c25_act_wea1;
    wire [15:0] c25_act_addr1;
    wire [31:0] c25_act_wdata1;


    conv2_5 c25(
        .clk(clk),
        .rst_n(rst_n),
        .start(c25_start),
        .finish(c25_finish),
        .weight_offset(weight_offset),
        .act_offset(act_offset),
        
        //weight
        .scale(scale),
        .weight_cen(c25_weight_cen),
        .weight_wea0(c25_weight_wea0),
        .weight_addr0(c25_weight_addr0),
        .weight_rdata0(L2_weight_rdata0),
        .weight_wea1(c25_weight_wea1),
        .weight_addr1(c25_weight_addr1),
        .weight_rdata1(L2_weight_rdata1),

        // Activation sram, dual port
        .act_cen(c25_act_cen),
        .act_wea0  (c25_act_wea0  ),
        .act_addr0 (c25_act_addr0 ),
        .act_wdata0(c25_act_wdata0),
        .act_rdata0(L2_act_rdata0   ),
        .act_wea1  (c25_act_wea1  ),
        .act_addr1 (c25_act_addr1 ),
        .act_wdata1(c25_act_wdata1),
        .act_rdata1(L2_act_rdata1   )
    );

    //Conv 2_7
    reg c27_start;
    reg next_c27_start;
    wire c27_finish;
    always @(posedge clk)begin
        if(!rst_n)begin
            c27_start <= 0;
        end
        else begin
            c27_start <= next_c27_start;
        end
    end
    always @*begin
        if(state==StConv2_7 )begin
            next_c27_start = 1;
        end
        else begin
            next_c27_start = 0;
        end
    end
    
    wire        c27_weight_cen;
    wire [ 3:0] c27_weight_wea0;
    wire [ 3:0] c27_weight_wea1;
    wire [15:0] c27_weight_addr0;
    wire [15:0] c27_weight_addr1;
    wire        c27_act_cen;
    wire [ 3:0] c27_act_wea0;
    wire [15:0] c27_act_addr0;
    wire [31:0] c27_act_wdata0;
    wire [ 3:0] c27_act_wea1;
    wire [15:0] c27_act_addr1;
    wire [31:0] c27_act_wdata1;

    conv2_7 c27(
        .clk(clk),
        .rst_n(rst_n),
        .start(c27_start),
        .finish(c27_finish),
        .weight_offset(weight_offset),
        .act_offset(act_offset),
        //weight
        .scale(scale),
        .weight_cen(c27_weight_cen),
        .weight_wea0(c27_weight_wea0),
        .weight_addr0(c27_weight_addr0),
        .weight_rdata0(L2_weight_rdata0),
        .weight_wea1(c27_weight_wea1),
        .weight_addr1(c27_weight_addr1),
        .weight_rdata1(L2_weight_rdata1),

        // Activation sram, dual port
        .act_cen(c27_act_cen),
        .act_wea0  (c27_act_wea0  ),
        .act_addr0 (c27_act_addr0 ),
        .act_wdata0(c27_act_wdata0),
        .act_rdata0(L2_act_rdata0   ),
        .act_wea1  (c27_act_wea1  ),
        .act_addr1 (c27_act_addr1 ),
        .act_wdata1(c27_act_wdata1),
        .act_rdata1(L2_act_rdata1   )
    );


    //Max1
    reg m2_start;
    reg next_m2_start;
    wire m2_finish;
    always @(posedge clk)begin
        if(!rst_n)begin
            m2_start <= 0;
        end
        else begin
            m2_start <= next_m2_start;
        end
    end
    always @*begin
        if(state==StMax2 )begin
            next_m2_start = 1;
        end
        else begin
            next_m2_start = 0;
        end
    end
    wire        m2_weight_cen;
    wire [ 3:0] m2_weight_wea0;
    wire [ 3:0] m2_weight_wea1;
    wire [15:0] m2_weight_addr0;
    wire [15:0] m2_weight_addr1;
    wire        m2_act_cen;
    wire [ 3:0] m2_act_wea0;
    wire [15:0] m2_act_addr0;
    wire [31:0] m2_act_wdata0;
    wire [ 3:0] m2_act_wea1;
    wire [15:0] m2_act_addr1;
    wire [31:0] m2_act_wdata1;
    max2 m2(
        .clk(clk),
        .rst_n(rst_n),
        .start(m2_start),
        .finish(m2_finish),
        .act_offset(act_offset),
        //weight
        .weight_cen(m2_weight_cen),
        .weight_wea0(m2_weight_wea0),
        .weight_addr0(m2_weight_addr0),
        .weight_rdata0(L2_weight_rdata0),
        .weight_wea1(m2_weight_wea1),
        .weight_addr1(m2_weight_addr1),
        .weight_rdata1(L2_weight_rdata1),

        // Activation sram, dual port
        .act_cen(m2_act_cen),
        .act_wea0  (m2_act_wea0  ),
        .act_addr0 (m2_act_addr0 ),
        .act_wdata0(m2_act_wdata0),
        .act_rdata0(L2_act_rdata0   ),
        .act_wea1  (m2_act_wea1  ),
        .act_addr1 (m2_act_addr1 ),
        .act_wdata1(m2_act_wdata1),
        .act_rdata1(L2_act_rdata1   )
    );

    //conv3
    reg c3_start;
    reg next_c3_start;
    wire c3_finish;
    always @(posedge clk)begin
        if(!rst_n)begin
            c3_start <= 0;
        end
        else begin
            c3_start <= next_c3_start;
        end
    end
    always @*begin
        if(state==StConv3 )begin
            next_c3_start = 1;
        end
        else begin
            next_c3_start = 0;
        end
    end
    wire        c3_weight_cen;     
    wire [ 3:0] c3_weight_wea0;
    wire [ 3:0] c3_weight_wea1;
    wire [15:0] c3_weight_addr0;
    wire [15:0] c3_weight_addr1;
    wire        c3_act_cen;
    wire [ 3:0] c3_act_wea0;
    wire [15:0] c3_act_addr0;
    wire [31:0] c3_act_wdata0;
    wire [ 3:0] c3_act_wea1;
    wire [15:0] c3_act_addr1;
    wire [31:0] c3_act_wdata1;

    conv3 c3(
        .clk(clk),
        .rst_n(rst_n),
        .start(c3_start),
        .finish(c3_finish),
        //weight
        .weight_offset(weight_offset),
        .act_offset(act_offset),
        .scale(scale),
        .weight_cen(c3_weight_cen),
        .weight_wea0(c3_weight_wea0),
        .weight_addr0(c3_weight_addr0),
        .weight_rdata0(L2_weight_rdata0),
        .weight_wea1(c3_weight_wea1),
        .weight_addr1(c3_weight_addr1),
        .weight_rdata1(L2_weight_rdata1),

        // Activation sram, dual port
        .act_cen(c3_act_cen),
        .act_wea0  (c3_act_wea0  ),
        .act_addr0 (c3_act_addr0 ),
        .act_wdata0(c3_act_wdata0),
        .act_rdata0(L2_act_rdata0   ),
        .act_wea1  (c3_act_wea1  ),
        .act_addr1 (c3_act_addr1 ),
        .act_wdata1(c3_act_wdata1),
        .act_rdata1(L2_act_rdata1   )
    );
    //Fully Cnnected 6
    reg f6_start;
    reg next_f6_start;
    wire f6_finish;
    always @(posedge clk)begin
        if(!rst_n)begin
            f6_start <= 0;
        end
        else begin
            f6_start <= next_f6_start;
        end
    end
    always @*begin
        if(state==StFc6 )begin
            next_f6_start = 1;
        end
        else begin
            next_f6_start = 0;
        end
    end
    wire        f6_weight_cen;
    wire [ 3:0] f6_weight_wea0;
    wire [ 3:0] f6_weight_wea1;
    wire [15:0] f6_weight_addr0;
    wire [15:0] f6_weight_addr1;
    wire        f6_act_cen;
    wire [ 3:0] f6_act_wea0;
    wire [15:0] f6_act_addr0;
    wire [31:0] f6_act_wdata0;
    wire [ 3:0] f6_act_wea1;
    wire [15:0] f6_act_addr1;
    wire [31:0] f6_act_wdata1;

    fc6 f6(
        .clk(clk),
        .rst_n(rst_n),
        .start(f6_start),
        .finish(f6_finish),
        //weight
        .weight_offset(weight_offset),
        .act_offset(act_offset),
        .scale(scale),
        .weight_cen(f6_weight_cen),
        .weight_wea0(f6_weight_wea0),
        .weight_addr0(f6_weight_addr0),
        .weight_rdata0(L2_weight_rdata0),
        .weight_wea1(f6_weight_wea1),
        .weight_addr1(f6_weight_addr1),
        .weight_rdata1(L2_weight_rdata1),

        // Activation sram, dual port
        .act_cen(f6_act_cen),
        .act_wea0  (f6_act_wea0  ),
        .act_addr0 (f6_act_addr0 ),
        .act_wdata0(f6_act_wdata0),
        .act_rdata0(L2_act_rdata0   ),
        .act_wea1  (f6_act_wea1  ),
        .act_addr1 (f6_act_addr1 ),
        .act_wdata1(f6_act_wdata1),
        .act_rdata1(L2_act_rdata1   )
    );

    //Fully Cnnected 7
    reg f7_start;
    reg next_f7_start;
    wire f7_finish;
    always @(posedge clk)begin
        if(!rst_n)
            f7_start <= 0;
        else
            f7_start <= next_f7_start;
    end
    always @*begin
        if(state==StFc7 )
            next_f7_start = 1;
        else 
            next_f7_start = 0;
    end
    
    wire        f7_weight_cen;
    wire [ 3:0] f7_weight_wea0;
    wire [ 3:0] f7_weight_wea1;
    wire [15:0] f7_weight_addr0;
    wire [15:0] f7_weight_addr1;
    wire        f7_act_cen;
    wire [ 3:0] f7_act_wea0;
    wire [15:0] f7_act_addr0;
    wire [31:0] f7_act_wdata0;
    wire [ 3:0] f7_act_wea1;
    wire [15:0] f7_act_addr1;
    wire [31:0] f7_act_wdata1;

    fc7 f7(
        .clk(clk),
        .rst_n(rst_n),
        .start(f7_start),
        .finish(f7_finish),
        //weight
        .weight_offset(weight_offset),
        .act_offset(act_offset),
        .scale(scale),
        .weight_cen(f7_weight_cen),
        .weight_wea0(f7_weight_wea0),
        .weight_addr0(f7_weight_addr0),
        .weight_rdata0(L2_weight_rdata0),
        .weight_wea1(f7_weight_wea1),
        .weight_addr1(f7_weight_addr1),
        .weight_rdata1(L2_weight_rdata1),

        // Activation sram, dual port
        .act_cen(f7_act_cen),
        .act_wea0  (f7_act_wea0  ),
        .act_addr0 (f7_act_addr0 ),
        .act_wdata0(f7_act_wdata0),
        .act_rdata0(L2_act_rdata0   ),
        .act_wea1  (f7_act_wea1  ),
        .act_addr1 (f7_act_addr1 ),
        .act_wdata1(f7_act_wdata1),
        .act_rdata1(L2_act_rdata1   )
    );
//end

    
    always @(posedge clk)begin
        if(!rst_n)
            state <= 0;
        else
            state <= next_state;
    end
    always @(*)begin
        status_buf = 2'b0;
        ready_buf = 1'b0;
        L2_weight_cen      = 1;
        L2_weight_wea0     = 0;
        L2_weight_addr0    = 0;
        L2_weight_wea1     = 0;
        L2_weight_addr1    = 0;
        L2_weight_wdata0   = 0;
        L2_weight_wdata1   = 0;
        L2_act_cen     = 1;
        L2_act_wea0    = 0;
        L2_act_addr0   = 0;
        L2_act_wdata0  = 0;
        L2_act_wea1    = 0;
        L2_act_addr1   = 0;
        L2_act_wdata1  = 0;
        next_state = Pre;
        next_act_offset = act_offset;
        next_weight_offset = weight_offset;
        case(state)
            Pre:begin
                status_buf = 2'b0;
                ready_buf = 1'b1;
                next_act_offset = act_offset;
                next_weight_offset = weight_offset;
                if(valid_buf)begin
                    status_buf = 2'b01;//busy
                    ready_buf = 1'b0;
                    if(TYPE==2'b00)begin //conv
                        if(R==2'b01) //filter 3
                            next_state = StConv1_3;
                        else if(R==2'b10) begin //filter 5
                            if(H==3'b001)//H =5
                                next_state = StConv3;
                            else if(H==3'b011) //H=14
                                next_state = StConv2_5;
                            else if(H==3'b101) //H=32
                                next_state = StConv1_5;
                            else
                                next_state=Pre; 
                        end
                        else if(R==2'b11)begin //filter 7
                            if(H==3'b011) //H=14
                                next_state = StConv2_7;
                            else if(H==3'b101) //H=32
                                next_state = StConv1_7;
                        end
                    end

                    else if(TYPE==2'b01)begin //maxpool
                        if(H==3'b100) 
                            next_state = StMax1;
                        else if(H==3'b010)
                            next_state = StMax2;
                        else 
                            next_state = Pre;
                    end
                    else if(TYPE == 2'b10)begin //fully connected
                        if(C==3'b011) //84
                            next_state = StFc7;
                        else if(C==3'b100) //120
                            next_state = StFc6;
                        else
                            next_state = Pre;
                    end
                    else begin 
                        next_state=Pre;
                    end
                end
                else begin
                    next_state = Pre;
                end
            end
            
            StConv1_3:begin
                status_buf = 2'b01;//busy
                ready_buf = 1'b0;
                next_state = Conv1_3;
                next_weight_offset = weight_offset;
            end
            Conv1_3:begin
                status_buf  = 2'b01;//busy
                ready_buf   = 1'b0;
                

                L2_weight_cen      = c13_weight_cen;
                L2_weight_wea0     = c13_weight_wea0;
                L2_weight_addr0    = c13_weight_addr0;
                L2_weight_wea1     = c13_weight_wea1;
                L2_weight_addr1    = c13_weight_addr1;
                L2_weight_wdata0   = 0;
                L2_weight_wdata1   = 0;
                L2_act_cen     = c13_act_cen;
                L2_act_wea0    = c13_act_wea0;
                L2_act_addr0   = c13_act_addr0;
                L2_act_wdata0  = c13_act_wdata0;
                L2_act_wea1    = c13_act_wea1;
                L2_act_addr1   = c13_act_addr1;
                L2_act_wdata1  = c13_act_wdata1;
                if(c13_finish==1)begin
                    next_act_offset = act_offset + 196;
                    next_weight_offset = weight_offset+18;
                    next_state = Finish;
                    //next_state=Finish;
                end
                else begin
                    next_act_offset = act_offset;
                    next_weight_offset = weight_offset;
                    next_state = Conv1_3;
                end
            end
            StConv1_5:begin
                
                status_buf = 2'b01;//busy
                ready_buf = 1'b0;
                next_state = Conv1_5;
                next_weight_offset = weight_offset;
            end
            Conv1_5:begin
                status_buf  = 2'b01;//busy
                ready_buf   = 1'b0;
                

                L2_weight_cen      = c15_weight_cen;
                L2_weight_wea0     = c15_weight_wea0;
                L2_weight_addr0    = c15_weight_addr0;
                L2_weight_wea1     = c15_weight_wea1;
                L2_weight_addr1    = c15_weight_addr1;
                L2_weight_wdata0   = 0;
                L2_weight_wdata1   = 0;
                L2_act_cen     = c15_act_cen;
                L2_act_wea0    = c15_act_wea0;
                L2_act_addr0   = c15_act_addr0;
                L2_act_wdata0  = c15_act_wdata0;
                L2_act_wea1    = c15_act_wea1;
                L2_act_addr1   = c15_act_addr1;
                L2_act_wdata1  = c15_act_wdata1;
                if(c15_finish==1)begin
                    next_act_offset = act_offset + 256;
                    next_weight_offset = weight_offset+60;
                    next_state = Finish;
                    //next_state=Finish;
                end
                else begin
                    next_act_offset = act_offset;
                    next_weight_offset = weight_offset;
                    next_state = Conv1_5;
                end
            end
            StConv1_7:begin
                status_buf  = 2'b01;//busy
                ready_buf   = 1'b0;
                next_state = Conv1_7;
                next_weight_offset = weight_offset;
            end
            Conv1_7:begin
                status_buf  = 2'b01;//busy
                ready_buf   = 1'b0;
                L2_weight_cen      = c17_weight_cen;
                L2_weight_wea0     = c17_weight_wea0;
                L2_weight_addr0    = c17_weight_addr0;
                L2_weight_wea1     = c17_weight_wea1;
                L2_weight_addr1    = c17_weight_addr1;
                L2_weight_wdata0   = 0;
                L2_weight_wdata1   = 0;
                L2_act_cen     = c17_act_cen;
                L2_act_wea0    = c17_act_wea0;
                L2_act_addr0   = c17_act_addr0;
                L2_act_wdata0  = c17_act_wdata0;
                L2_act_wea1    = c17_act_wea1;
                L2_act_addr1   = c17_act_addr1;
                L2_act_wdata1  = c17_act_wdata1;
                if(c17_finish)begin
                    next_act_offset = act_offset + 256; 
                    next_weight_offset = weight_offset+84;
                    next_state=Finish;
                end
                    
                else begin
                    next_act_offset = act_offset;
                    next_weight_offset = weight_offset;
                    next_state = Conv1_7;
                end
            end
            
            StMax1:begin
                status_buf = 2'b01;//busy
                ready_buf = 1'b0;
                L2_weight_cen      = 1'b1;
                L2_weight_wea0     = 0;
                L2_weight_addr0    = 0;
                L2_weight_wea1     = 0;
                L2_weight_addr1    = 0;
                L2_weight_wdata0   = 0;
                L2_weight_wdata1   = 0;
                L2_act_cen     = 1'b1;
                L2_act_wea0    = 0;
                L2_act_addr0   = 0;
                L2_act_wdata0  = 0;
                L2_act_wea1    = 0;
                L2_act_addr1   = 0;
                L2_act_wdata1  = 0;

                next_state = Max1;
            end
            Max1:begin
                status_buf = 2'b01;//busy
                ready_buf = 1'b0;
                L2_weight_cen      = m1_weight_cen     ;
                L2_weight_wea0     = m1_weight_wea0    ;
                L2_weight_addr0    = m1_weight_addr0   ;
                L2_weight_wea1     = m1_weight_wea1    ;
                L2_weight_addr1    = m1_weight_addr1   ;
                L2_act_cen     = m1_act_cen    ;
                L2_act_wea0    = m1_act_wea0   ;
                L2_act_addr0   = m1_act_addr0  ;
                L2_act_wdata0  = m1_act_wdata0 ;
                L2_act_wea1    = m1_act_wea1   ;
                L2_act_addr1   = m1_act_addr1  ;
                L2_act_wdata1  = m1_act_wdata1 ;
                if(m1_finish==1)begin
                    next_state = Finish;
                    //next_state=Finish;
                end
                else begin
                    next_state = Max1;
                end
            end
            StConv2_5:begin
                status_buf = 2'b01;//busy
                ready_buf = 1'b0;
                next_state = Conv2_5;
            end
            Conv2_5:begin
                status_buf  = 2'b01;//busy
                ready_buf   = 1'b0;
                L2_weight_cen      = c25_weight_cen;
                L2_weight_wea0     = c25_weight_wea0;
                L2_weight_addr0    = c25_weight_addr0;
                L2_weight_wea1     = c25_weight_wea1;
                L2_weight_addr1    = c25_weight_addr1;
                L2_weight_wdata0   = 0;
                L2_weight_wdata1   = 0;
                L2_act_cen     = c25_act_cen    ;
                L2_act_wea0    = c25_act_wea0   ;
                L2_act_addr0   = c25_act_addr0  ;
                L2_act_wdata0  = c25_act_wdata0 ;
                L2_act_wea1    = c25_act_wea1   ;
                L2_act_addr1   = c25_act_addr1  ;
                L2_act_wdata1  = c25_act_wdata1 ;
                if(c25_finish==1)begin//debug
                    next_act_offset = act_offset + 336;
                    next_weight_offset = weight_offset+960;
                    next_state = Finish;
                end
                else begin
                    next_act_offset = act_offset;
                    next_weight_offset = weight_offset;
                    next_state = Conv2_5;
                end
            end
            StConv2_7:begin
                status_buf = 2'b01;//busy
                ready_buf = 1'b0;
                next_state = Conv2_7;
            end    
            Conv2_7:begin
                status_buf  = 2'b01;//busy
                ready_buf   = 1'b0;
                L2_weight_cen      = c27_weight_cen;
                L2_weight_wea0     = c27_weight_wea0;
                L2_weight_addr0    = c27_weight_addr0;
                L2_weight_wea1     = c27_weight_wea1;
                L2_weight_addr1    = c27_weight_addr1;
                L2_weight_wdata0   = 0;
                L2_weight_wdata1   = 0;
                L2_act_cen     = c27_act_cen    ;
                L2_act_wea0    = c27_act_wea0   ;
                L2_act_addr0   = c27_act_addr0  ;
                L2_act_wdata0  = c27_act_wdata0 ;
                L2_act_wea1    = c27_act_wea1   ;
                L2_act_addr1   = c27_act_addr1  ;
                L2_act_wdata1  = c27_act_wdata1 ;
                if(c27_finish==1)begin//debug
                    next_act_offset = act_offset + 336;
                    next_weight_offset = weight_offset+1344;
                    next_state = Finish;
                end
                else begin
                    next_act_offset = act_offset;
                    next_weight_offset = weight_offset;
                    next_state = Conv2_7;
                end
                
            end
            StMax2:begin
                status_buf = 2'b01;//busy
                ready_buf = 1'b0;
                next_state=Max2;
            end
            Max2:begin
                status_buf = 2'b01;//busy
                ready_buf = 1'b0;
                L2_weight_cen      = m2_weight_cen     ;
                L2_weight_wea0     = m2_weight_wea0    ;
                L2_weight_addr0    = m2_weight_addr0   ;
                L2_weight_wea1     = m2_weight_wea1    ;
                L2_weight_addr1    = m2_weight_addr1   ;
                L2_act_cen     = m2_act_cen    ;
                L2_act_wea0    = m2_act_wea0   ;
                L2_act_addr0   = m2_act_addr0  ;
                L2_act_wdata0  = m2_act_wdata0 ;
                L2_act_wea1    = m2_act_wea1   ;
                L2_act_addr1   = m2_act_addr1  ;
                L2_act_wdata1  = m2_act_wdata1 ;
                if(m2_finish==1)begin
                    next_state = Finish;
                    //next_state=Finish;
                end
                else begin
                    next_state = Max2;
                end
            end
            StConv3:begin
                status_buf = 2'b01;//busy
                ready_buf = 1'b0;
                next_state = Conv3;
            end
            Conv3:begin
                status_buf  = 2'b01;//busy
                ready_buf   = 1'b0;
                L2_weight_cen      = c3_weight_cen;
                L2_weight_wea0     = c3_weight_wea0;
                L2_weight_addr0    = c3_weight_addr0;
                L2_weight_wea1     = c3_weight_wea1;
                L2_weight_addr1    = c3_weight_addr1;
                L2_weight_wdata0   = 0;
                L2_weight_wdata1   = 0;
                L2_act_cen     = c3_act_cen;
                L2_act_wea0    = c3_act_wea0;
                L2_act_addr0   = c3_act_addr0;
                L2_act_wdata0  = c3_act_wdata0;
                L2_act_wea1    = c3_act_wea1;
                L2_act_addr1   = c3_act_addr1;
                L2_act_wdata1  = c3_act_wdata1;
                if(c3_finish==1)begin
                    next_act_offset = act_offset+100 ;
                    next_weight_offset = weight_offset+16'd12000;
                    next_state = Finish;
                    //next_state=Finish;
                end
                else begin
                    next_act_offset = act_offset;
                    next_weight_offset = weight_offset;
                    next_state = Conv3;
                end
            end
            StFc6:begin
                status_buf = 2'b01;//busy
                ready_buf = 1'b0;
                next_state = Fc6;
            end
            Fc6:begin
                status_buf  = 2'b01;//busy
                ready_buf   = 1'b0;
                L2_weight_cen      = f6_weight_cen;
                L2_weight_wea0     = f6_weight_wea0;
                L2_weight_addr0    = f6_weight_addr0;
                L2_weight_wea1     = f6_weight_wea1;
                L2_weight_addr1    = f6_weight_addr1;
                L2_weight_wdata0   = 0;
                L2_weight_wdata1   = 0;
                L2_act_cen     = f6_act_cen;
                L2_act_wea0    = f6_act_wea0;
                L2_act_addr0   = f6_act_addr0;
                L2_act_wdata0  = f6_act_wdata0;
                L2_act_wea1    = f6_act_wea1;
                L2_act_addr1   = f6_act_addr1;
                L2_act_wdata1  = f6_act_wdata1;
                if(f6_finish==1)begin
                    next_act_offset = act_offset+30;
                    next_weight_offset = weight_offset+16'd2520;
                    next_state = Finish;
                    //next_state=Finish;
                end
                else begin
                    next_act_offset = act_offset;
                    next_weight_offset = weight_offset;
                    next_state = Fc6;
                end
            end
            StFc7:begin
                status_buf = 2'b01;//busy
                ready_buf = 1'b0;
                next_state = Fc7;
            end
            Fc7:begin
                status_buf  = 2'b01;//busy
                ready_buf   = 1'b0;
                L2_weight_cen      = f7_weight_cen;
                L2_weight_wea0     = f7_weight_wea0;
                L2_weight_addr0    = f7_weight_addr0;
                L2_weight_wea1     = f7_weight_wea1;
                L2_weight_addr1    = f7_weight_addr1;
                L2_weight_wdata0   = 0;
                L2_weight_wdata1   = 0;
                L2_act_cen     = f7_act_cen;
                L2_act_wea0    = f7_act_wea0;
                L2_act_addr0   = f7_act_addr0;
                L2_act_wdata0  = f7_act_wdata0;
                L2_act_wea1    = f7_act_wea1;
                L2_act_addr1   = f7_act_addr1;
                L2_act_wdata1  = f7_act_wdata1;
                if(f7_finish==1)begin
                    next_act_offset = act_offset+10;
                    next_weight_offset = weight_offset+16'd210;
                    next_state = Finish;
                    //next_state=Finish;
                end
                else begin
                    next_act_offset = act_offset;
                    next_weight_offset = weight_offset;
                    next_state = Fc7;
                end
            end
            Finish:begin
                status_buf = 2'b11;//finish
                ready_buf = 1'b0;
                next_state = Pre;
            end

            default:begin
                status_buf = 2'b0;
                ready_buf = 1'b0;
                L2_weight_cen      = 1;
                L2_weight_wea0     = 0;
                L2_weight_addr0    = 0;
                L2_weight_wea1     = 0;
                L2_weight_addr1    = 0;
                L2_act_cen     = 1;
                L2_act_wea0    = 0;
                L2_act_addr0   = 0;
                L2_act_wdata0  = 0;
                L2_act_wea1    = 0;
                L2_act_addr1   = 0;
                L2_act_wdata1  = 0;
                next_state = Pre;
            end
        endcase
    end

endmodule

module conv1_3(
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
    reg [23:0]wt_row0;
    reg [23:0]wt_row1;
    reg [23:0]wt_row2;
    reg [23:0]wt_row3;
    reg [23:0]wt_row4;
    wire signed [31:0]comp_res[1:0][4:0];
    innerproduct8_2_cv13 inpro8_2(
        .act0(activation0),
        .act1(activation1),
        .wt_row0(wt_row0),
        .wt_row1(wt_row1),
        .out_00(comp_res[0][0]),
        .out_01(comp_res[0][1]),
        .out_02(comp_res[0][2]),
        .out_03(comp_res[0][3]),
        .out_04(comp_res[0][4]), 
        .out_10(comp_res[1][0]),
        .out_11(comp_res[1][1]),
        .out_12(comp_res[1][2]),
        .out_13(comp_res[1][3]),
        .out_14(comp_res[1][4])
    );
    reg [31:0] prq_in[1:0][4:0];
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

    reg signed[ 7:0]weights2D[3:0][2:0];
    

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
            next_out_channel = out_channel + 1;
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
            if(loading_row_weight==1)next_loading_row_weight=4;
            else next_loading_row_weight =loading_row_weight+1;
        end  
        else begin
            next_loading_row_weight = 0;
        end
    end
    //save weight to array 6 5
    reg [47:0]next_save_weight;
    always@(*)begin
        if (state==LoadWeight )begin
            next_save_weight = {weight_rdata1[23:0] , weight_rdata0[23:0]};
        end  
        else begin
            next_save_weight = 0;
        end
    end

    integer i;
    integer j;
    always@(posedge clk) begin
        if(!rst_n) begin
            for (i=0;i<4;i=i+1)begin
                for (j=0;j<3;j=j+1)begin
                    weights2D[i][j]<=0;
                end
            end
        end
        else begin
            if(state==LoadWeight)begin
                weights2D[loading_row_weight*2][0] <= next_save_weight[ 7: 0];
                weights2D[loading_row_weight*2][1] <= next_save_weight[15: 8];
                weights2D[loading_row_weight*2][2] <= next_save_weight[23:16];
                weights2D[loading_row_weight*2+1][0] <= next_save_weight[31:24];
                weights2D[loading_row_weight*2+1][1] <= next_save_weight[39:32];
                weights2D[loading_row_weight*2+1][2] <= next_save_weight[47:40];
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
                if (row_act_cnt==3)begin
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
    reg signed [31:0] out_act[1:0][4:0];
    reg signed [31:0] next_out_psum[2:0][4:0]; 
    //integer i,j;
    always@(posedge clk)begin
        if(!rst_n) begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<5;j=j+1)begin
                    out_act[i][j]<=0;
                end
            end
        end
        else begin 
            if(state==Comp||state==PoolingQuan)begin
                if(row_act_cnt==3 && cpact_row==1)begin
                    for (i=0;i<2;i=i+1)begin
                        for(j=0;j<5;j=j+1)begin
                            out_act[i][j]<=out_act[i][j];
                        end
                    end
                end
                else begin
                    case(cpact_row)
                        8'd0:begin
                            for (i=0;i<1;i=i+1)begin
                                for(j=0;j<5;j=j+1)begin
                                    out_act[i][j] <= next_out_psum[i][j];
                                end
                            end
                        end
                        8'd3:begin
                            for (i=1;i<2;i=i+1)begin
                                for(j=0;j<5;j=j+1)begin
                                    out_act[i][j] <= next_out_psum[i][j];
                                end
                            end
                        end
                        default:begin
                            for (i=0;i<2;i=i+1)begin
                                for(j=0;j<5;j=j+1)begin
                                    out_act[i][j] <= next_out_psum[i][j];
                                end
                            end
                        end
                    endcase
                end  
            end
            else begin
                for (i=0;i<2;i=i+1)begin
                    for(j=0;j<5;j=j+1)begin
                        out_act[i][j] <= 0;
                    end
                end
                
            end
        end
        
    end
    //combinational saving and adding the psum 
    always @(*)begin
        if(state==Comp)begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<5;j=j+1)begin
                    next_out_psum[i][j] = out_act[i][j]+comp_res[i][j];
                end
            end
        end
        else begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<5;j=j+1)begin
                    next_out_psum[i][j] = 0;
                end
            end
        end
    end
    //combinational for asserting the intput for conv
    always @(*)begin
        if(state==Comp||state==PoolingQuan)begin
            //data for computing
            case(cpact_row)
                8'd0:begin
                    wt_row0 = {weights2D[0][2],weights2D[0][1],weights2D[0][0]};
                    wt_row1 = 0;
                end
                8'd3:begin
                    wt_row0 = 0;
                    wt_row1 = {weights2D[2][2],weights2D[2][1],weights2D[2][0]};
                end
                default:begin
                    wt_row0 = {weights2D[cpact_row][2],weights2D[cpact_row][1],weights2D[cpact_row][0]};
                    wt_row1 = {weights2D[cpact_row-1][2],weights2D[cpact_row-1][1],weights2D[cpact_row-1][0]};
                end
            endcase
            if(rowstart_cnt==26&&cpact_row==3)begin
                activation0 = 0;
                activation1 = 0;
            end else if(cpact_row==0&&rowstart_cnt==0)begin
                activation0 = 0;
                activation1 = 0;
            end else if(col_act_cnt==24)begin
                activation0 = act_rdata0;
                activation1 = 0;
            end else begin
                activation0 = act_rdata0;
                activation1 = act_rdata1;
            end
        end
        else begin
            wt_row0 = 0;
            wt_row1 = 0;
            activation0=0;
            activation1=0;
        end
    end

    reg [31:0]next_store[1:0];
    reg [31:0]store[1:0];
    always@(posedge clk)begin
        if(!rst_n)begin
            store[1]<=0;
            store[0]<=0;
        end else begin
            store[1]<=next_store[1];
            store[0]<=next_store[0];
        end
    end
    always @(*)begin
        if(state==PoolingQuan)begin
            for(i=0;i<2;i=i+1)begin
                for(j=0;j<5 ;j=j+1)begin
                    if(j==0)begin
                        if(col_act_cnt==0)begin
                            prq_in[i][j] = out_act[i][j];
                        end else begin
                            prq_in[i][j] = store[i];
                        end

                    end else begin
                        prq_in[i][j] = out_act[i][j];
                    end
                end
            end
            next_store[1]=out_act[1][4];
            next_store[0]=out_act[0][4];
        end
        else begin
            for(i=0;i<2;i=i+1)begin
                for(j=0;j<5;j=j+1)begin
                    prq_in[i][j] = 0;
                end
            end
            next_store[1]=store[1];
            next_store[0]=store[0];
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
                if(row_weight_cnt<2)begin
                    next_state=LoadWeight;
                    weight_cen  =1'b0;
                end
                else if(row_weight_cnt==5)begin
                    weight_cen  =1'b1;
                    next_state=LoadAct;
                end
                else begin
                    weight_cen  =1'b1;
                    next_state=LoadWeight;
                end
                act_cen     =1'b1;
                weight_addr0=weight_offset + weight_offset + out_channel*3 + row_weight_cnt * 2;
                weight_addr1=weight_offset + weight_offset + out_channel*3 + row_weight_cnt * 2 + 1;
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
            LoadAct:begin
                next_state=Wait0;
                weight_cen  =1'b1;
                act_cen     =1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                if(rowstart_cnt==0)begin
                    act_addr0 = 0;
                    act_addr1 = 0;
                end else begin
                    act_addr0 = act_offset + rowstart_cnt*7 + row_act_cnt*16'd7 + {10'b0,col_act_cnt [7:2]}   -7;
                    act_addr1 = act_offset + rowstart_cnt*7 + row_act_cnt*16'd7 + {10'b0,col_act_cnt [7:2]}+1   -7;
                end
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
                if(rowstart_cnt==0)begin
                    act_addr0 = 0;
                    act_addr1 = 0;
                end else begin
                    act_addr0 = act_offset + rowstart_cnt*7 + row_act_cnt*16'd7 + {10'b0,col_act_cnt [7:2]}   -7;
                    act_addr1 = act_offset + rowstart_cnt*7 + row_act_cnt*16'd7 + {10'b0,col_act_cnt [7:2]}+1   -7;
                end
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
                if(rowstart_cnt==0)begin
                    act_addr0 = 0;
                    act_addr1 = 0;
                end else begin
                    act_addr0 = act_offset + rowstart_cnt*7 + row_act_cnt*16'd7 + {10'b0,col_act_cnt [7:2]}   -7;
                    act_addr1 = act_offset + rowstart_cnt*7 + row_act_cnt*16'd7 + {10'b0,col_act_cnt [7:2]}+1   -7;
                end
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state=Comp;
                finish = 0;
            end
            Comp:begin
                
                weight_cen  =1'b1;
                act_cen     =1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                //load data (3 cycle later)
                if(rowstart_cnt==0)begin
                    act_addr0 = 0;
                    act_addr1 = 0;
                end else begin
                    act_addr0 = act_offset + rowstart_cnt*7 + row_act_cnt*16'd7 + {10'b0,col_act_cnt [7:2]}   -7;
                    act_addr1 = act_offset + rowstart_cnt*7 + row_act_cnt*16'd7 + {10'b0,col_act_cnt [7:2]}+1   -7;
                end
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                if(cpact_row==8'd3 )begin
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
                next_state = Finish;
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
module innerproduct8_2_cv13(
    input wire [31:0] act0,
    input wire [31:0] act1,
    input wire signed [23:0] wt_row0,
    input wire signed [23:0] wt_row1,
    output signed [31:0] out_04,
    output signed [31:0] out_00,
    output signed [31:0] out_01,
    output signed [31:0] out_02,
    output signed [31:0] out_03,
    output signed [31:0] out_14,
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
    assign a0 = act0[ 7: 0];
    assign a1 = act0[15: 8];
    assign a2 = act0[23:16];
    assign a3 = act0[31:24];
    assign a4 = act1[ 7: 0];
    assign a5 = act1[15: 8];
    
    wire signed [7:0] weight[1:0][2:0];

    assign weight[0][0] = wt_row0[ 7: 0];
    assign weight[0][1] = wt_row0[15: 8];
    assign weight[0][2] = wt_row0[23:16];
    assign weight[1][0] = wt_row1[ 7: 0];
    assign weight[1][1] = wt_row1[15: 8];
    assign weight[1][2] = wt_row1[23:16];
    
    //calculating
    assign out_00 = weight[0][0]*0 + weight[0][1]*a0 + weight[0][2]*a1;
    assign out_01 = weight[0][0]*a0 + weight[0][1]*a1 + weight[0][2]*a2;
    assign out_02 = weight[0][0]*a1 + weight[0][1]*a2 + weight[0][2]*a3;
    assign out_03 = weight[0][0]*a2 + weight[0][1]*a3 + weight[0][2]*a4;
    assign out_04 = weight[0][0]*a3 + weight[0][1]*a4 + weight[0][2]*a5;

    assign out_10 = weight[1][0]*0 + weight[1][1]*a0 + weight[1][2]*a1;
    assign out_11 = weight[1][0]*a0 + weight[1][1]*a1 + weight[1][2]*a2;
    assign out_12 = weight[1][0]*a1 + weight[1][1]*a2 + weight[1][2]*a3;
    assign out_13 = weight[1][0]*a2 + weight[1][1]*a3 + weight[1][2]*a4;
    assign out_14 = weight[1][0]*a3 + weight[1][1]*a4 + weight[1][2]*a5;
   
endmodule


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
        for(i=0;i<2;i=i+1)begin
            for(j=0;j<4 ;j=j+1)begin
                prq_in[i][j] = 0;
            end
        end
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

module conv2_5(
    // Weight sram, dual port
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg finish,
    input wire [15:0] weight_offset,
    input wire [15:0] act_offset,
    input wire [31:0] scale,
    output reg        weight_cen,
    output reg [ 3:0] weight_wea0,
    output reg [15:0] weight_addr0,
    input wire [31:0] weight_rdata0,
    output reg [ 3:0] weight_wea1,
    output reg [15:0] weight_addr1,
    input wire [31:0] weight_rdata1,

    // Activation sram, dual port
    output reg act_cen,
    output reg [ 3:0] act_wea0,
    output reg [15:0] act_addr0,
    output reg [31:0] act_wdata0,
    input wire [31:0] act_rdata0,
    output reg [ 3:0] act_wea1,
    output reg [15:0] act_addr1,
    output reg [31:0] act_wdata1,
    input wire [31:0] act_rdata1
);
    //parameter [15:0]weight_offset=16'd60;
    reg [3:0] state;
    reg [3:0] next_state;
    
    parameter [3:0] Pre=4'd0;
    parameter [3:0] Outchannel=4'd1;
    parameter [3:0] Inchannel=4'd6;
    parameter [3:0] LoadWeight=4'd2;
    parameter [3:0] LoadAct=4'd3;
    parameter [3:0] Comp=4'd4;
    parameter [3:0] PoolingQuan=4'd5;


    parameter [3:0] Finish=4'd9;
    parameter [3:0] Wait0=4'd10;
    parameter [3:0] Wait1=4'd11;
    parameter [3:0] Wait2=4'd12;
    parameter [3:0] Wait3=4'd13;
    parameter [3:0] Wait4=4'd14;
    parameter [3:0] Wait5=4'd15;
    parameter [3:0] Waitend0=4'd7;
    parameter [3:0] Waitend1=4'd8;


    reg [31:0]activation0;
    reg [31:0]activation1;
    reg [39:0]wt_row0;
    reg [39:0]wt_row1;
    reg [39:0]wt_row2;
    reg [39:0]wt_row3;
    reg [39:0]wt_row4;
    wire signed [31:0]comp_res[4:0][3:0];
    innerproduct8_5 inpro8_5(
        .act0(act_rdata0),
        .act1(act_rdata1),
        .wt_row0(wt_row0),
        .wt_row1(wt_row1),
        .wt_row2(wt_row2),
        .wt_row3(wt_row3),
        .wt_row4(wt_row4),
        .out_00(comp_res[0][0]),
        .out_01(comp_res[0][1]),
        .out_02(comp_res[0][2]),
        .out_03(comp_res[0][3]),    
        .out_10(comp_res[1][0]),
        .out_11(comp_res[1][1]),
        .out_12(comp_res[1][2]),
        .out_13(comp_res[1][3]),
        .out_20(comp_res[2][0]),
        .out_21(comp_res[2][1]),
        .out_22(comp_res[2][2]),
        .out_23(comp_res[2][3]),
        .out_30(comp_res[3][0]),
        .out_31(comp_res[3][1]),
        .out_32(comp_res[3][2]),
        .out_33(comp_res[3][3]),
        .out_40(comp_res[4][0]),
        .out_41(comp_res[4][1]),
        .out_42(comp_res[4][2]),
        .out_43(comp_res[4][3])
    );
    reg [31:0] prq_in[1:0][3:0];
    wire [31:0] quanout0;
    wire [31:0] quanout1;
    reluQuan8 prq(
        .scale (scale),
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
    
//output channel
    reg [7:0]out_channel;
    reg [7:0]next_out_channel;
    
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
    //input channel
    reg [7:0]in_channel;
    reg [7:0]next_in_channel;
    always @(posedge clk) begin
        if(!rst_n)begin
            in_channel <= 0;
        end
        else begin
            in_channel <= next_in_channel;
        end
    end
    always @(*) begin
        if(state==Inchannel)begin
            if(in_channel==5)begin
                next_in_channel=0;
            end
            else begin
                next_in_channel=in_channel + 1;
            end
        end
        else begin
            next_in_channel = in_channel;
        end
    end

    //row weight count
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
            if(state==LoadWeight && row_weight_cnt>=3)begin
                weights2D[loading_row_weight][0] <= next_save_weight[ 7: 0];
                weights2D[loading_row_weight][1] <= next_save_weight[15: 8];
                weights2D[loading_row_weight][2] <= next_save_weight[23:16];
                weights2D[loading_row_weight][3] <= next_save_weight[31:24];
                weights2D[loading_row_weight][4] <= next_save_weight[39:32];
            end
            else begin
                weights2D[loading_row_weight][0] <= weights2D[loading_row_weight][0];
                weights2D[loading_row_weight][1] <= weights2D[loading_row_weight][1];
                weights2D[loading_row_weight][2] <= weights2D[loading_row_weight][2];
                weights2D[loading_row_weight][3] <= weights2D[loading_row_weight][3];
                weights2D[loading_row_weight][4] <= weights2D[loading_row_weight][4];
            end
            
        end
    end
    
     //id of to-load activation 
    reg [7:0]act_cnt;
    reg [7:0]next_act_cnt;
    always@(posedge clk)begin
        if(!rst_n) begin
            act_cnt<=8'd0;
        end
        else begin 
            act_cnt <= next_act_cnt;
        end
    end
    always @(*)begin
        if (state==LoadAct||state==Wait0||state==Wait1||state==Comp)begin
                if(act_cnt==16'd8)begin //0,2,4,...18,20,then 21,23,25...39,41,then 42,44...
                    next_act_cnt = 0; 
                end
                else next_act_cnt = act_cnt+16'd4;
            end
        else begin
            next_act_cnt = 0;
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
        if (state==LoadAct||state==Wait0||state==Wait1||state==Comp)begin
                if(act_cnt==16'd8)begin //0,2,4,...18,20,then 21,23,25...39,41,then 42,44...
                    if(row_act_cnt==16'd13)begin
                        next_row_act_cnt=0;
                    end
                    else begin
                        next_row_act_cnt = row_act_cnt+16'd1; 
                    end
                end
                else next_row_act_cnt = row_act_cnt;
        end
        else begin
            next_row_act_cnt = 0;
        end
    end
    //computing activation
    reg [7:0]cpact_col;
    reg [7:0]next_cpact_col;
    always@(posedge clk)begin
        if(!rst_n) begin
            cpact_col<=8'd0;
        end
        else begin 
            cpact_col <= next_cpact_col;
        end
    end
    always @(*)begin
        if (state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
                if(cpact_col==8'd8)begin //0,2,4,...18,20,then 21,23,25...39,41,then 42,44...
                    next_cpact_col = 0; 
                end
                else next_cpact_col = cpact_col+8'd4;
            end
        else begin
            next_cpact_col = 0;
        end
    end
    //row of cp act
    reg [7:0]cpact_row;
    reg [7:0]next_cpact_row;
    always@(posedge clk)begin
        if(!rst_n) begin
            cpact_row<=8'd0;
        end
        else begin 
            cpact_row <= next_cpact_row;
        end
    end
    always @(*)begin
        if (state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
                if(cpact_col==8'd8)begin //0,2,4,...18,20,then 21,23,25...39,41,then 42,44...
                    if(cpact_row==8'd13)begin
                        next_cpact_row=0;
                    end
                    else begin
                        next_cpact_row = cpact_row+8'd1;
                    end
                end
                else begin
                    next_cpact_row = cpact_row;
                end 
            end
        else begin
            next_cpact_row = 0;
        end
    end


    //save the psum
    //output array for a channel
    reg signed [31:0] out_act[9:0][9:0];
    reg signed [31:0] next_out_psum[4:0][3:0]; 
    //integer i,j;
    always@(posedge clk)begin
        if(!rst_n) begin
            for (i=0;i<10;i=i+1)begin
                for(j=0;j<10;j=j+1)begin
                    out_act[i][j]<=0;
                end
            end
        end
        else begin 
            if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
                case(cpact_row)
                //debug todo: the boundary of those "6" byte long
                    8'd0:begin
                        if(cpact_col<8)begin 
                            for (i=0;i<1;i=i+1)begin
                                for(j=0;j<4;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                        else begin
                            for (i=0;i<1;i=i+1)begin
                                for(j=0;j<2;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                        
                    end
                    8'd1:begin
                        if(cpact_col<8)begin 
                            for (i=0;i<2;i=i+1)begin
                                for(j=0;j<4;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                        else begin
                            for (i=0;i<2;i=i+1)begin
                                for(j=0;j<2;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                    end
                    8'd2:begin
                        if(cpact_col<8)begin 
                            for (i=0;i<3;i=i+1)begin
                                for(j=0;j<4;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                        else begin
                            for (i=0;i<3;i=i+1)begin
                                for(j=0;j<2;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                    end
                    8'd3:begin
                        if(cpact_col<8)begin 
                            for (i=0;i<4;i=i+1)begin
                                for(j=0;j<4;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                        else begin
                            for (i=0;i<4;i=i+1)begin
                                for(j=0;j<2;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                    end
                    8'd10:begin
                        if(cpact_col<8)begin 
                            for (i=1;i<5;i=i+1)begin
                                for(j=0;j<4;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                        else begin
                            for (i=1;i<5;i=i+1)begin
                                for(j=0;j<2;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                    end
                    8'd11:begin
                        if(cpact_col<8)begin 
                            for (i=2;i<5;i=i+1)begin
                                for(j=0;j<4;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                        else begin
                            for (i=2;i<5;i=i+1)begin
                                for(j=0;j<2;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                    end
                    8'd12:begin
                        if(cpact_col<8)begin 
                            for (i=3;i<5;i=i+1)begin
                                for(j=0;j<4;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                        else begin
                            for (i=3;i<5;i=i+1)begin
                                for(j=0;j<2;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                    end
                    8'd13:begin
                        if(cpact_col<8)begin 
                            for (i=4;i<5;i=i+1)begin
                                for(j=0;j<4;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                        else begin
                            for (i=4;i<5;i=i+1)begin
                                for(j=0;j<2;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                    end
                    default:begin
                        if(cpact_col<8)begin 
                            for (i=0;i<5;i=i+1)begin
                                for(j=0;j<4;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                        else begin
                            for (i=0;i<5;i=i+1)begin
                                for(j=0;j<2;j=j+1)begin
                                    out_act[cpact_row-i][cpact_col+j] <= next_out_psum[i][j];
                                end
                            end
                        end
                    end
                endcase
            end
            else begin
                //debug
                if(state==Outchannel)begin
                    for (i=0;i<10;i=i+1)begin
                        for(j=0;j<10;j=j+1)begin
                            out_act[i][j] <= 0;
                        end
                    end
                end
                else begin
                    for (i=0;i<10;i=i+1)begin
                        for(j=0;j<10;j=j+1)begin
                            out_act[i][j] <= out_act[i][j];
                        end
                    end
                end
                
            end
        end
        
    end
    //combinational saving and adding the psum 
    always @(*)begin
        if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
            case(cpact_row)
                8'd0:begin
                    if(cpact_col<8)begin
                        for (i=0;i<1;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=1;i<5;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                    end
                    else begin
                        for (i=0;i<1;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=1;i<5;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        for (i=0;i<5;i=i+1)begin
                            for(j=2;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                    end
                    
                end
                8'd1:begin
                    if(cpact_col<8)begin
                        for (i=0;i<2;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=2;i<5;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        
                    end
                    else begin
                        for (i=0;i<2;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=2;i<5;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        for (i=0;i<5;i=i+1)begin
                            for(j=2;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                    end
                end
                8'd2:begin
                    if(cpact_col<8)begin
                        for (i=0;i<3;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=3;i<5;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                    end
                    else begin
                        for (i=0;i<3;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=3;i<5;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        for (i=0;i<5;i=i+1)begin
                            for(j=2;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                    end
                end
                8'd3:begin
                    if(cpact_col<8)begin
                        for (i=0;i<4;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=4;i<5;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                    end
                    else begin
                        for (i=0;i<4;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=4;i<5;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        for (i=0;i<5;i=i+1)begin
                            for(j=2;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                    end
                end
                8'd10:begin
                    if(cpact_col<8)begin
                        for (i=0;i<1;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        for (i=1;i<5;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                    end
                    else begin
                        for (i=0;i<1;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        for (i=1;i<5;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=0;i<5;i=i+1)begin
                            for(j=2;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                    end
                end
                8'd11:begin
                    if(cpact_col<8)begin
                        for (i=0;i<2;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        for (i=2;i<5;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                    end
                    else begin
                        for (i=0;i<2;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        for (i=2;i<5;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=0;i<5;i=i+1)begin
                            for(j=2;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                    end
                end
                8'd12:begin
                    if(cpact_col<8)begin
                        for (i=0;i<3;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        for (i=3;i<5;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                    end
                    else begin
                        for (i=0;i<3;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        for (i=3;i<5;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=0;i<5;i=i+1)begin
                            for(j=2;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                    end
                end
                8'd13:begin
                    if(cpact_col<8)begin
                        for (i=0;i<4;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        for (i=4;i<5;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                    end
                    else begin
                        for (i=0;i<4;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                        for (i=4;i<5;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=0;i<5;i=i+1)begin
                            for(j=2;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                    end
                end
                default:begin
                    if(cpact_col<8)begin
                        for (i=0;i<5;i=i+1)begin
                            for(j=0;j<4;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                    end
                    else begin
                        for (i=0;i<5;i=i+1)begin
                            for(j=0;j<2;j=j+1)begin
                                next_out_psum[i][j] = out_act[cpact_row-i][cpact_col+j]+comp_res[i][j];
                            end
                        end
                        for (i=0;i<5;i=i+1)begin
                            for(j=2;j<4;j=j+1)begin
                                next_out_psum[i][j] = 0;
                            end
                        end
                    end
                end
            endcase
        end
        else begin
            for (i=0;i<5;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    next_out_psum[i][j] = 0;
                end

            end
        end
    end
    //combinational for asserting the intput for conv
    always @(*)begin
        if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
            //data for computing
            wt_row0 = {weights2D[0][4],weights2D[0][3],weights2D[0][2],weights2D[0][1],weights2D[0][0]};
            wt_row1 = {weights2D[1][4],weights2D[1][3],weights2D[1][2],weights2D[1][1],weights2D[1][0]};
            wt_row2 = {weights2D[2][4],weights2D[2][3],weights2D[2][2],weights2D[2][1],weights2D[2][0]};
            wt_row3 = {weights2D[3][4],weights2D[3][3],weights2D[3][2],weights2D[3][1],weights2D[3][0]};
            wt_row4 = {weights2D[4][4],weights2D[4][3],weights2D[4][2],weights2D[4][1],weights2D[4][0]};
            activation0 = act_rdata0;
            activation1 = act_rdata1;
        end
        else begin
            wt_row0 = 0;
            wt_row1 = 0;
            wt_row2 = 0;
            wt_row3 = 0;
            wt_row4 = 0;
            activation0=0;
            activation1=0;
        end
    end

    //save back to sram and pooling relu quan
    reg [7:0] outrow;
    reg [7:0] next_outrow;
    reg [7:0] outcol;
    reg [7:0] next_outcol;

    always @(posedge clk)begin
        if(!rst_n)begin
            outcol <= 0;
        end
        else begin
            outcol <= next_outcol;
        end
    end
    always @(*)begin
        if(state==PoolingQuan)begin
            if(outcol<8)begin
                next_outcol = outcol + 4;
            end
            else begin
                next_outcol = 0;
            end
        end
        else begin
            next_outcol = 0;
        end
    end

    always @(posedge clk)begin
        if(!rst_n)begin
            outrow <= 0;
        end
        else begin
            outrow <= next_outrow;
        end
    end
    always @(*)begin
        if(state==PoolingQuan)begin
            if(outcol==8)begin
                next_outrow = outrow + 2;
            end
            else 
                next_outrow = outrow;
            
        end
        else begin
            next_outrow = 0;
        end
    end

    always @(*)begin
        if(state==PoolingQuan)begin
            if(outcol==8)begin
                for(i=0;i<2;i=i+1)begin
                    for(j=0;j<2;j=j+1)begin
                        prq_in[i][j] = out_act[outrow + i][outcol + j];
                    end
                end
                prq_in[0][2]=0;
                prq_in[0][3]=0;
                prq_in[1][2]=0;
                prq_in[1][3]=0;
            end
            else begin
                for(i=0;i<2;i=i+1)begin
                    for(j=0;j<4;j=j+1)begin
                        prq_in[i][j] = out_act[outrow + i][outcol + j];
                    end
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
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=0;
                act_addr1=0;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                finish = 0;
            end
            Outchannel:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=0;
                act_addr1=0;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Inchannel;
                finish = 0;
            end
            Inchannel:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=0;
                act_addr1=0;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=LoadWeight;
                finish = 0;
            end
            LoadWeight:begin
                weight_cen  = 1'b0;
                act_cen     = 1'b1;

                weight_addr0=weight_offset + out_channel*60 + in_channel*10 + row_weight_cnt*2;
                weight_addr1=weight_offset + out_channel*60 + in_channel*10 + row_weight_cnt*2 + 1;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 0;
                act_addr1 = 0;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                if(row_weight_cnt==7)begin
                    next_state=LoadAct;
                end
                else begin
                    next_state=LoadWeight;
                end
                finish = 0;
            end
            LoadAct:begin
                
                weight_cen  = 1'b1;
                act_cen     = 1'b0;

                next_state=Wait0;
                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = act_offset + in_channel*56 + row_act_cnt*16'd4 + {10'b0,act_cnt [7:2]};
                act_addr1 = act_offset + in_channel*56 + row_act_cnt*16'd4 + {10'b0,act_cnt [7:2]}+1;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                finish = 0;
            end
            Wait0:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0= act_offset + in_channel*56 + row_act_cnt*16'd4 + {10'b0,act_cnt [7:2]};
                act_addr1= act_offset + in_channel*56 + row_act_cnt*16'd4 + {10'b0,act_cnt [7:2]}+1;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Wait1;
                finish = 0;
            end
            Wait1:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0= act_offset + in_channel*56 + row_act_cnt*16'd4 + {10'b0,act_cnt [7:2]};
                act_addr1= act_offset + in_channel*56 + row_act_cnt*16'd4 + {10'b0,act_cnt [7:2]}+1;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Comp;
                finish = 0;
            end
            
            Comp:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                //load data (3 cycle later)
                act_addr0= act_offset + in_channel*56 + row_act_cnt*16'd4 + {10'b0,act_cnt [7:2]};
                act_addr1= act_offset + in_channel*56 + row_act_cnt*16'd4 + {10'b0,act_cnt [7:2]} + 1;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                if(row_act_cnt==16'd13 && act_cnt==16'd8)begin
                    next_state=Wait2;
                end
                else begin
                    next_state=Comp;
                end
                finish = 0;
            end 
            Wait2:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=0;
                act_addr1=0;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Wait3;
                finish = 0;
            end
            Wait3:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=0;
                act_addr1=0;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Wait4;
                finish = 0;
            end
            Wait4:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

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
                next_state=Wait5;
                finish = 0;
            end
            Wait5:begin
                
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

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
                
                if(in_channel==5)begin
                    next_state=PoolingQuan;
                end
                else begin
                    next_state=Inchannel;
                end
                finish = 0;
            end
            PoolingQuan:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                //act_addr0 = 16'd592 + (( out_channel*5+outrow[7:1] )>>2 )*5 +  ( out_channel*5+outrow[7:1] )%4;
                //act_addr1 = 16'd592 + (( out_channel*5+outrow[7:1] )>>2 )*5 +  ( out_channel*5+outrow[7:1] )%4 +1;
                act_addr0 = 16'd2200 + out_channel*30 +  outrow*3    + outcol[7:2];
                act_addr1 = 16'd2200 + out_channel*30 + (outrow+1)*3 + outcol[7:2];
                act_wdata0 = quanout0;
                act_wdata1 = quanout1;
                act_wea0 = 4'b1111;
                act_wea1 = 4'b1111;
                if(outrow==8 && outcol==8)begin //debug out col
                    if(out_channel==8'd15)begin
                        next_state=Waitend0;
                    end
                    else begin
                        next_state=Outchannel;
                    end
                end
                else begin
                    next_state=PoolingQuan;
                end
                finish = 0;
               
            end
            Waitend0:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=0;
                act_addr1=0;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Waitend1;
                finish = 0;
            end
            Waitend1:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=0;
                act_addr1=0;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Finish;
                finish = 0;
            end
            Finish:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=0;
                act_addr1=0;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state = Finish;
                finish = 1;
            end
            
            default:  begin
                next_state=Pre;
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=0;
                act_addr1=0;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                finish = 0; 
            end
        endcase
    end

endmodule

//innerproduct module
module innerproduct8_5(
    
    input wire [31:0] act0,
    input wire [31:0] act1,

    input wire signed [39:0] wt_row0,
    input wire signed [39:0] wt_row1,
    input wire signed [39:0] wt_row2,
    input wire signed [39:0] wt_row3,
    input wire signed [39:0] wt_row4,

    output signed [31:0] out_00,
    output signed [31:0] out_01,
    output signed [31:0] out_02,
    output signed [31:0] out_03,
    output signed [31:0] out_10,
    output signed [31:0] out_11,
    output signed [31:0] out_12,
    output signed [31:0] out_13,
    output signed [31:0] out_20,
    output signed [31:0] out_21,
    output signed [31:0] out_22,
    output signed [31:0] out_23,
    output signed [31:0] out_30,
    output signed [31:0] out_31,
    output signed [31:0] out_32,
    output signed [31:0] out_33,
    output signed [31:0] out_40,
    output signed [31:0] out_41,
    output signed [31:0] out_42,
    output signed [31:0] out_43
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

    wire signed [7:0] weight[4:0][4:0];
   


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
    assign weight[2][0] = wt_row2[ 7: 0];
    assign weight[2][1] = wt_row2[15: 8];
    assign weight[2][2] = wt_row2[23:16];
    assign weight[2][3] = wt_row2[31:24];
    assign weight[2][4] = wt_row2[39:32];
    assign weight[3][0] = wt_row3[ 7: 0];
    assign weight[3][1] = wt_row3[15: 8];
    assign weight[3][2] = wt_row3[23:16];
    assign weight[3][3] = wt_row3[31:24];
    assign weight[3][4] = wt_row3[39:32];
    assign weight[4][0] = wt_row4[ 7: 0];
    assign weight[4][1] = wt_row4[15: 8];
    assign weight[4][2] = wt_row4[23:16];
    assign weight[4][3] = wt_row4[31:24];
    assign weight[4][4] = wt_row4[39:32];
    
    //calculating
    assign out_00 = weight[0][0]*a0 + weight[0][1]*a1 + weight[0][2]*a2 + weight[0][3]*a3 + weight[0][4]*a4;
    assign out_01 = weight[0][0]*a1 + weight[0][1]*a2 + weight[0][2]*a3 + weight[0][3]*a4 + weight[0][4]*a5;
    assign out_02 = weight[0][0]*a2 + weight[0][1]*a3 + weight[0][2]*a4 + weight[0][3]*a5 + weight[0][4]*a6;
    assign out_03 = weight[0][0]*a3 + weight[0][1]*a4 + weight[0][2]*a5 + weight[0][3]*a6 + weight[0][4]*a7;
    assign out_10 = weight[1][0]*a0 + weight[1][1]*a1 + weight[1][2]*a2 + weight[1][3]*a3 + weight[1][4]*a4;
    assign out_11 = weight[1][0]*a1 + weight[1][1]*a2 + weight[1][2]*a3 + weight[1][3]*a4 + weight[1][4]*a5;
    assign out_12 = weight[1][0]*a2 + weight[1][1]*a3 + weight[1][2]*a4 + weight[1][3]*a5 + weight[1][4]*a6;
    assign out_13 = weight[1][0]*a3 + weight[1][1]*a4 + weight[1][2]*a5 + weight[1][3]*a6 + weight[1][4]*a7;
    assign out_20 = weight[2][0]*a0 + weight[2][1]*a1 + weight[2][2]*a2 + weight[2][3]*a3 + weight[2][4]*a4;
    assign out_21 = weight[2][0]*a1 + weight[2][1]*a2 + weight[2][2]*a3 + weight[2][3]*a4 + weight[2][4]*a5;
    assign out_22 = weight[2][0]*a2 + weight[2][1]*a3 + weight[2][2]*a4 + weight[2][3]*a5 + weight[2][4]*a6;
    assign out_23 = weight[2][0]*a3 + weight[2][1]*a4 + weight[2][2]*a5 + weight[2][3]*a6 + weight[2][4]*a7;
    assign out_30 = weight[3][0]*a0 + weight[3][1]*a1 + weight[3][2]*a2 + weight[3][3]*a3 + weight[3][4]*a4;
    assign out_31 = weight[3][0]*a1 + weight[3][1]*a2 + weight[3][2]*a3 + weight[3][3]*a4 + weight[3][4]*a5;
    assign out_32 = weight[3][0]*a2 + weight[3][1]*a3 + weight[3][2]*a4 + weight[3][3]*a5 + weight[3][4]*a6;
    assign out_33 = weight[3][0]*a3 + weight[3][1]*a4 + weight[3][2]*a5 + weight[3][3]*a6 + weight[3][4]*a7;
    assign out_40 = weight[4][0]*a0 + weight[4][1]*a1 + weight[4][2]*a2 + weight[4][3]*a3 + weight[4][4]*a4;
    assign out_41 = weight[4][0]*a1 + weight[4][1]*a2 + weight[4][2]*a3 + weight[4][3]*a4 + weight[4][4]*a5;
    assign out_42 = weight[4][0]*a2 + weight[4][1]*a3 + weight[4][2]*a4 + weight[4][3]*a5 + weight[4][4]*a6;
    assign out_43 = weight[4][0]*a3 + weight[4][1]*a4 + weight[4][2]*a5 + weight[4][3]*a6 + weight[4][4]*a7;

   
endmodule    
module conv2_7(
    // Weight sram, dual port
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg finish,

    input wire [15:0] weight_offset,
    input wire [15:0] act_offset,
    input wire [31:0] scale,
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
    parameter [7:0] Inchannel   =8'd8;


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
    wire signed [31:0]comp_res[1:0][9:0];//2*12
    innerproduct16_10 inpro16(
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

        .out_10 (comp_res[1][0]),
        .out_11 (comp_res[1][1]),
        .out_12 (comp_res[1][2]),
        .out_13 (comp_res[1][3]),
        .out_14 (comp_res[1][4]),
        .out_15 (comp_res[1][5]),
        .out_16 (comp_res[1][6]),
        .out_17 (comp_res[1][7]), 
        .out_18 (comp_res[1][8]),
        .out_19 (comp_res[1][9])
    );
    reg [31:0] prq_in[1:0][3:0];
    wire [31:0] quanout0;
    wire [31:0] quanout1;
    reluQuan8 rq8(
        .scale (scale),
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

    reg[7:0]in_channel,next_in_channel;
    always @(posedge clk) begin//debug about when to add
        if(!rst_n)begin
            in_channel <= 0;
        end
        else begin
            in_channel <= next_in_channel;
        end
    end
    always @(*) begin
        if(state==Inchannel)begin
            if(in_channel>=5)
                next_in_channel=0;
            else
                next_in_channel=in_channel + 1;
        end
        else begin

            next_in_channel = in_channel;
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
                if(rowstart_cnt==0||rowstart_cnt==7)begin
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
            if(rowstart_cnt==0)begin
                next_rowstart_cnt = rowstart_cnt+8'd1;
            end
            else begin
                next_rowstart_cnt = rowstart_cnt+8'd2;
            end
        end
        else begin
            if(state==Inchannel||state==LoadWeight||state==LoadAct||state==Wait0||state==Wait1||state==Comp||state==Quan0||state==Quan1)begin
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
    reg signed [31:0] out_act[1:0][9:0]; //2*11
    reg signed [31:0] next_out_psum[1:0][9:0]; 
    //integer i,j;
    always@(posedge clk)begin
        if(!rst_n) begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<10;j=j+1)begin
                    out_act[i][j]<=0;
                end
            end
        end//debug
        else begin 
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<10;j=j+1)begin
                    out_act[i][j] <= next_out_psum[i][j];
                end
            end
        end
        
    end
    //combinational saving and adding the psum 
    always @(*)begin
        if(state==Comp)begin
            if(cpcol_cnt==8)begin
                for (i=0;i<2;i=i+1)begin
                    for(j=0;j<10;j=j+1)begin
                        next_out_psum[i][j] = out_act[i][j]+comp_res[i][j];
                    end
                end
            end
            else begin
                for (i=0;i<2;i=i+1)begin
                    for(j=0;j<10;j=j+1)begin
                        next_out_psum[i][j] = out_act[i][j];
                    end
                end
            end
            
                
        end
        else if(state==LoadWeight||state==LoadAct||state==Wait0||state==Wait1||state==Inchannel||state==Quan0||state==Quan1)begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<10;j=j+1)begin
                    next_out_psum[i][j] = out_act[i][j];
                end
            end
        end
        else if(state==PoolingQuan)begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<10;j=j+1)begin
                    next_out_psum[i][j] = 0;
                end

            end
        end
        else begin
            for (i=0;i<2;i=i+1)begin
                for(j=0;j<10;j=j+1)begin
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
            else if(rowstart_cnt==7)begin
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
                for(j=0;j<2;j=j+1)begin
                    prq_in[i][j] = out_act[i][j+8];
                end
            end
            prq_in[0][2]=0;
            prq_in[0][3]=0;
            prq_in[1][2]=0;
            prq_in[1][3]=0;
        end
        else begin
            for(i=0;i<2;i=i+1)begin
                for(j=0;j<4;j=j+1)begin
                    prq_in[i][j] =0;
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
wire [7:0]fix_rowstart_cnt;
assign fix_rowstart_cnt = (rowstart_cnt==0) ? 0 : rowstart_cnt+1;

    always @*begin
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
                next_state=Inchannel;
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
            Inchannel:begin
                next_state = LoadWeight;
            end
            LoadWeight:begin
                if(row_weight_cnt>=7)begin
                    weight_cen  =1'b1;
                    act_cen     =1'b1;
                end
                else begin
                    weight_cen  =1'b0;
                    act_cen     =1'b1;
                end
                weight_addr0=weight_offset + out_channel*84 + in_channel*14 + row_weight_cnt*2;
                weight_addr1=weight_offset + out_channel*84 + in_channel*14 + row_weight_cnt*2 + 1;
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
                act_addr0 = act_offset + in_channel*56 + rowstart_cnt*4 + row_act_cnt*16'd4 + col_cnt[7:2];
                act_addr1 = act_offset + in_channel*56 + rowstart_cnt*4 + row_act_cnt*16'd4 + col_cnt[7:2]+1;
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
                act_addr0=act_offset + in_channel*56 + rowstart_cnt*4 + row_act_cnt*16'd4 + col_cnt[7:2];
                act_addr1=act_offset + in_channel*56 + rowstart_cnt*4 + row_act_cnt*16'd4 + col_cnt[7:2]+1;
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
                act_addr0=act_offset + in_channel*56 + rowstart_cnt*4 + row_act_cnt*16'd4 + col_cnt[7:2];
                act_addr1=act_offset + in_channel*56 + rowstart_cnt*4 + row_act_cnt*16'd4 + col_cnt[7:2]+1;
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
                act_addr0=act_offset + in_channel*56 + rowstart_cnt*4 + row_act_cnt*16'd4 + col_cnt[7:2];
                act_addr1=act_offset + in_channel*56 + rowstart_cnt*4 + row_act_cnt*16'd4 + col_cnt[7:2] + 1;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                
                if(rowstart_cnt==0||rowstart_cnt==7)begin
                    if(cpact_row==8'd6&&cpcol_cnt==8'd8 )begin//debug padding may cause this different
                        if(in_channel==5)
                            next_state=Quan0;
                        else
                            next_state = Inchannel;
                    end
                    else begin
                        next_state=Comp;
                    end
                end
                else begin
                    if(cpact_row==8'd7&&cpcol_cnt==8'd8 )begin//debug padding may cause this different
                        if(in_channel==5)
                            next_state=Quan0;
                        else
                            next_state = Inchannel;
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
                act_addr0 = 16'd2200 + out_channel*30 + fix_rowstart_cnt*3 ;//7=14/2
                act_addr1 = 16'd2200 + out_channel*30 + (fix_rowstart_cnt+1)*3 ;
                
                act_wdata0  = quanout0;//debug
                act_wea0    = 4'b1111;
                act_wdata1  = quanout1;
                act_wea1    = 4'b1111;
                next_state=Quan1;
            end
            Quan1:begin//mddle
                weight_cen  =1'b1;
                act_cen     =1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = 16'd2200 + out_channel*30 + fix_rowstart_cnt*3 +1;//7=14/2
                act_addr1 = 16'd2200 + out_channel*30 + (fix_rowstart_cnt+1)*3 +1;
                act_wdata0  = quanout0;//debug
                act_wea0    = 4'b1111;
                act_wdata1  = quanout1;
                act_wea1    = 4'b1111;
                
                next_state=PoolingQuan;
            end
            PoolingQuan:begin//right part
                weight_cen  =1'b1;
                act_cen     =1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = 16'd2200 + out_channel*30 + fix_rowstart_cnt*3 +2;//7=14/2
                act_addr1 = 16'd2200 + out_channel*30 + (fix_rowstart_cnt+1)*3 +2;
                act_wdata0  = quanout0;//debug
                act_wea0    = 4'b1111;
                act_wdata1  = quanout1;
                act_wea1    = 4'b1111;
                

                if(rowstart_cnt==7)begin
                    if(out_channel==15) next_state=Waitend0;
                    else next_state=Outchannel;
                end
                else begin
                    next_state=Inchannel;
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

module innerproduct16_10 (
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

    output [31:0] out_10,
    output [31:0] out_11,
    output [31:0] out_12,
    output [31:0] out_13,
    output [31:0] out_14,
    output [31:0] out_15,
    output [31:0] out_16,
    output [31:0] out_17, 
    output [31:0] out_18,
    output [31:0] out_19
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
    assign a15 = 0;

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
   

endmodule

module conv3(
    // Weight sram, dual port
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg finish,

    input wire [15:0] weight_offset,
    input wire [15:0] act_offset,
    input wire [31:0] scale,
    output reg weight_cen,
    output reg [ 3:0] weight_wea0,
    output reg [15:0] weight_addr0,
    input wire [31:0] weight_rdata0,
    output reg [ 3:0] weight_wea1,
    output reg [15:0] weight_addr1,
    input wire [31:0] weight_rdata1,

    // Activation sram, dual port
    output reg act_cen,
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
    //parameter [3:0] Inchannel=4'd6;
    parameter [3:0] LoadWeight=4'd2;
    parameter [3:0] LoadAct=4'd3;
    parameter [3:0] Comp=4'd4;
    parameter [3:0] Quan=4'd5;


    parameter [3:0] Finish=4'd9;
    parameter [3:0] Wait0=4'd10;
    parameter [3:0] Wait1=4'd11;
    parameter [3:0] Wait2=4'd12;
    parameter [3:0] Wait3=4'd13;
    parameter [3:0] Wait4=4'd14;
    parameter [3:0] Wait5=4'd15;
    parameter [3:0] Waitend0=4'd7;
    parameter [3:0] Waitend1=4'd8;


    reg [31:0]activation0;
    reg [31:0]activation1;
    reg [39:0]weight0;
    reg [39:0]weight1;
    wire signed [31:0]comp_res;
    innerproduct8 inpro8(
        .weight0(weight0[7 :0 ]),
        .weight1(weight0[15:8 ]),
        .weight2(weight0[23:16]),
        .weight3(weight0[31:24]),
        .weight4(weight1[7 :0 ]),
        .weight5(weight1[15:8 ]),
        .weight6(weight1[23:16]),
        .weight7(weight1[31:24]),
        
        .act0(activation0[7 :0 ]),
        .act1(activation0[15:8 ]),
        .act2(activation0[23:16]),
        .act3(activation0[31:24]),
        .act4(activation1[7 :0 ]),
        .act5(activation1[15:8 ]),
        .act6(activation1[23:16]),
        .act7(activation1[31:24]),
        .out(comp_res)
    );

    reg [31:0] prq_in;
    wire [7:0] quanout;
    reluQuan1 rq(
        .scale (scale),
        .in(prq_in),
        .out(quanout)
    );

    
//output channel
    reg [7:0]out_channel;
    reg [7:0]next_out_channel;
    
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
    //input channel
    /*reg [7:0]in_channel;
    reg [7:0]next_in_channel;
    always @(posedge clk) begin
        if(!rst_n)begin
            in_channel <= 0;
        end
        else begin
            in_channel <= next_in_channel;
        end
    end*/
    

    //row weight count
    reg [15:0]weight_cnt;
    reg [15:0]next_weight_cnt;
    always@(posedge clk) begin
        if(!rst_n) begin
            weight_cnt <= 15'd0;
        end
        else begin
            weight_cnt <= next_weight_cnt;
        end
    end
    always@(*)begin
        if (state==LoadAct||state==Comp||state==Wait0||state==Wait1)begin
            next_weight_cnt =weight_cnt+8;
        end  
        else begin
            next_weight_cnt = 0;
        end
    end
//loading weight
    reg [15:0]loading_weight_cnt;
    reg [15:0]next_loading_weight_cnt;
    always@(posedge clk) begin
        if(!rst_n) begin
            loading_weight_cnt <= 4'd0;
        end
        else begin
            loading_weight_cnt <= next_loading_weight_cnt;
        end
    end
    always@(*)begin
        if (state==LoadAct||state==Comp||state==Wait0||state==Wait1||state==Wait2||state==Wait3||state==Wait4||state==Wait5)begin
            next_loading_weight_cnt =loading_weight_cnt+8;
        end  
        else begin
            next_loading_weight_cnt = 0;
        end
    end
    //save weight to array

    integer i;
    integer j;
    
     //id of to-load activation 
    reg [15:0]act_cnt;
    reg [15:0]next_act_cnt;
    always@(posedge clk)begin
        if(!rst_n) begin
            act_cnt<=16'd0;
        end
        else begin 
            act_cnt <= next_act_cnt;
        end
    end
    always @(*)begin
        if (state==LoadAct||state==Wait0||state==Wait1||state==Comp)begin
            next_act_cnt = act_cnt+16'd8;
        end
        else begin
            next_act_cnt = 0;
        end
    end
    //row act
   
    //computing activation
    reg [15:0]cpact_cnt;
    reg [15:0]next_cpact_cnt;
    always@(posedge clk)begin
        if(!rst_n) begin
            cpact_cnt<=15'd0;
        end
        else begin 
            cpact_cnt <= next_cpact_cnt;
        end
    end
    always @(*)begin
        if (state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
            next_cpact_cnt = cpact_cnt+8'd8;
        end
        else begin
            next_cpact_cnt = 0;
        end
    end
    


    //save the psum
    //output array for a channel
    reg signed [31:0] out_act;
    reg signed [31:0] next_out_psum; 
    //integer i,j;
    always@(posedge clk)begin
        if(!rst_n) begin
            out_act <= 0;
        end
        else begin 
            if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
                out_act <= next_out_psum;
            end
            else begin
                //debug
                if(state==Outchannel)begin
                    out_act <= 0;
                end
                else begin
                    out_act <= out_act;
                end
                
            end
        end
        
    end
    //combinational saving and adding the psum 
    always @(*)begin
        if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
            next_out_psum = out_act + comp_res;
        end
        else begin
            next_out_psum = 0;
        end
    end
    
//combinational for asserting the intput for conv
    always @(*)begin
        if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
            //data for computing
            weight0 = weight_rdata0;
            weight1 = weight_rdata1;
            activation0 = act_rdata0;
            activation1 = act_rdata1;
        end
        else begin
            weight0 = 0;
            weight1 = 0;
            activation0=0;
            activation1=0;
        end
    end
    //save back to sram and pooling relu quan
    always @(*)begin
        if(state==Quan)begin
            prq_in=out_act;
        end
        else begin
            prq_in = 0;
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
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
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
                if(start==1'b1)begin
                    next_state=LoadAct;
                end
                else begin
                    next_state=Pre;
                end
                finish = 0;
            end
            Outchannel:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

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
                next_state=LoadAct;
                finish = 0;
            end
            LoadAct:begin
                next_state=Wait0;
                weight_cen  = 1'b0;
                act_cen     = 1'b0;

                weight_addr0=weight_offset + out_channel*100 + weight_cnt[15:2];
                weight_addr1=weight_offset + out_channel*100 + weight_cnt[15:2] + 1;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 =  act_offset + act_cnt [15:2];
                act_addr1 =  act_offset + act_cnt [15:2] + 1;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
            end
            Wait0:begin
                weight_cen  = 1'b0;
                act_cen     = 1'b0;

                weight_addr0=weight_offset + out_channel*100 + weight_cnt[15:2];
                weight_addr1=weight_offset + out_channel*100 + weight_cnt[15:2] + 1;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0= act_offset + act_cnt [15:2];
                act_addr1= act_offset + act_cnt [15:2] + 1;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state=Wait1;
                finish = 0;
            end
            Wait1:begin
                
                weight_cen  = 1'b0;
                act_cen     = 1'b0;
                weight_addr0=weight_offset + out_channel*100 + weight_cnt[15:2];
                weight_addr1=weight_offset + out_channel*100 + weight_cnt[15:2] + 1;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=  act_offset + act_cnt [15:2];
                act_addr1=  act_offset + act_cnt [15:2] + 1;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state=Comp;
                finish = 0;
            end
            
            Comp:begin
                weight_cen  = 1'b0;
                act_cen     = 1'b0;

                weight_addr0=weight_offset + out_channel*100 + weight_cnt[15:2];
                weight_addr1=weight_offset + out_channel*100 + weight_cnt[15:2] + 1;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                //load data (3 cycle later)
                act_addr0= act_offset + act_cnt [15:2];
                act_addr1= act_offset + act_cnt [15:2] + 1;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                if(act_cnt==16'd392)begin
                    next_state=Wait2;
                end
                else begin
                    next_state=Comp;
                end
                finish = 0;
            end 
            Wait2:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=0;
                act_addr1=0;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state=Wait3;
                finish = 0;
            end
            Wait3:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=0;
                act_addr1=0;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state=Wait4;
                finish = 0;
            end
            Wait4:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
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
                next_state=Wait5;
                finish = 0;
            end
            Wait5:begin
                
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

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
                
                next_state=Quan;
                finish = 0;
            end
            Quan:begin
                
                weight_cen  = 1'b1;
                act_cen     = 1'b0;

                weight_addr0 = 16'd0;
                weight_addr1 = 16'd0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0 = act_offset +100 + out_channel[7:2] ;
                act_addr1 = 0;
                case( out_channel[1:0])
                    2'd0:begin
                        act_wdata0 = {24'd0,quanout};
                        act_wdata1 = 0;
                        act_wea0 = 4'b0001;
                        act_wea1 = 4'b0000;
                    end
                    2'd1:begin
                        act_wdata0 = { 16'd0,quanout,8'd0 };
                        act_wdata1 = 0;
                        act_wea0 = 4'b0010;
                        act_wea1 = 4'b0000;
                    end
                    2'd2:begin
                        act_wdata0 = { 8'd0,quanout,16'd0 };
                        act_wdata1 = 0;
                        act_wea0 = 4'b0100;
                        act_wea1 = 4'b0000;
                    end
                    2'd3:begin
                        act_wdata0 = { quanout,24'd0 };
                        act_wdata1 = 0;
                        act_wea0 = 4'b1000;
                        act_wea1 = 4'b0000;
                    end
                    default:begin
                        act_wdata0 = 0;
                        act_wdata1 = 0;
                        act_wea0 = 4'b0000;
                        act_wea1 = 4'b0000;
                    end
                endcase
                
                
                if(out_channel==8'd119)begin
                    next_state=Waitend0;
                end
                else begin
                    next_state=Outchannel;
                end
                finish = 0;
                
               
            end
            Waitend0:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

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
                next_state=Waitend1;
                finish = 0;
            end
            Waitend1:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

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
                next_state=Finish;
                finish = 0;
            end
            Finish:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

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
                next_state = Finish;
                finish = 1;
            end
            
            default:  begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;

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
                next_state=Pre; 
                finish = 0;
            end

        endcase
    end

endmodule

module innerproduct8(
    input signed [7:0] weight0,
    input signed [7:0] weight1,
    input signed [7:0] weight2,
    input signed [7:0] weight3,
    input signed [7:0] weight4,
    input signed [7:0] weight5,
    input signed [7:0] weight6,
    input signed [7:0] weight7,
    
    input signed [7:0] act0,
    input signed [7:0] act1,
    input signed [7:0] act2,
    input signed [7:0] act3,
    input signed [7:0] act4,
    input signed [7:0] act5,
    input signed [7:0] act6,
    input signed [7:0] act7,
    output signed [31:0] out
);

    wire signed[31:0] wr0;
    wire signed[31:0] wr1;
    wire signed[31:0] wr2;
    wire signed[31:0] wr3;
    wire signed[31:0] wr4;
    wire signed[31:0] wr5;
    wire signed[31:0] wr6;
    wire signed[31:0] wr7;

    
    assign wr0 = act0 * weight0;
    assign wr1 = act1 * weight1;
    assign wr2 = act2 * weight2;
    assign wr3 = act3 * weight3;
    assign wr4 = act4 * weight4;
    assign wr5 = act5 * weight5;
    assign wr6 = act6 * weight6;
    assign wr7 = act7 * weight7;

    assign out = wr0 + wr1 + wr2 + wr3 + wr4 + wr5 + wr6 + wr7;


endmodule
//relu quan
module reluQuan1(
    input signed [31:0]scale,
    input signed [31:0]in,
    output signed [7:0]out
);
    wire signed [31:0]relu;
    assign relu = (!in[31]) ? in : 0;

    wire signed [63:0]scaled;
    assign scaled = relu * scale;

    assign out = (scaled[63:23]==0) ? scaled[23:16] : 8'd127;
endmodule

module fc6 (
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg finish,
    
    input wire [15:0] weight_offset,
    input wire [15:0] act_offset,
    input wire [31:0] scale,
    output reg weight_cen,
    output reg [ 3:0] weight_wea0,
    output reg [15:0] weight_addr0,
    input wire [31:0] weight_rdata0,
    output reg [ 3:0] weight_wea1,
    output reg [15:0] weight_addr1,
    input wire [31:0] weight_rdata1,

    // Activation sram, dual port
    output reg act_cen,
    output reg [ 3:0] act_wea0,
    output reg [15:0] act_addr0,
    output reg [31:0] act_wdata0,
    input wire [31:0] act_rdata0,
    output reg [ 3:0] act_wea1,
    output reg [15:0] act_addr1,
    output reg [31:0] act_wdata1,
    input wire [31:0] act_rdata1
);
    // Add your design here

    reg [3:0] state;
    reg [3:0] next_state;
    
    
    parameter [3:0] Pre=4'd0;
    parameter [3:0] PreLoad=4'd1;
    parameter [3:0] Comp=4'd2;
    parameter [3:0] Quan=4'd3;
    parameter [3:0] WriteData=4'd4;
    parameter [3:0] Wait_write0=4'd5;
    parameter [3:0] Wait_write1=4'd6;

    parameter [3:0] Finish=4'd8;
    parameter [3:0] Wait0=4'd10;
    parameter [3:0] Wait1=4'd11;
    parameter [3:0] Wait2=4'd12;
    parameter [3:0] Wait3=4'd13;
    parameter [3:0] Wait4=4'd14;

    
    reg [31:0]weight0;
    reg [31:0]weight1;
    reg [31:0]activation0;
    reg [31:0]activation1;
    wire signed [31:0]comp_res;
    innerproduct8 inpro8(
        .weight0(weight0[7 :0 ]),
        .weight1(weight0[15:8 ]),
        .weight2(weight0[23:16]),
        .weight3(weight0[31:24]),
        .weight4(weight1[7 :0 ]),
        .weight5(weight1[15:8 ]),
        .weight6(weight1[23:16]),
        .weight7(weight1[31:24]),
        
        .act0(activation0[7 :0 ]),
        .act1(activation0[15:8 ]),
        .act2(activation0[23:16]),
        .act3(activation0[31:24]),
        .act4(activation1[7 :0 ]),
        .act5(activation1[15:8 ]),
        .act6(activation1[23:16]),
        .act7(activation1[31:24]),

        .out(comp_res)
    );

    //ReLu, Quantization, Clamp
    reg [31:0]in0;
    wire [7:0]quanout;
    reluQuan1 rq(
        .scale (scale),
        .in(in0),
        .out(quanout)
    );


    always@(posedge clk) begin
        if(!rst_n) begin
            state <= Pre;
        end
        else begin
            state <= next_state;
        end
    end
    //weight count
    reg [15:0]weight_count;//0-20,21-41,42-62,63-83......
    reg [15:0]next_weight_count;
    always@(posedge clk) begin
        if(!rst_n) begin
            weight_count <= 16'd0;
        end
        else begin
            weight_count <= next_weight_count;
        end
    end
    always@(*)begin
        if (state==PreLoad||state==Wait0||state==Wait1||state==Comp)begin
                if(weight_count==16'd112)begin //0,2,4,...18,20,then 21,23,25...39,41,then 42,44...
                    next_weight_count =0; 
                end
                else next_weight_count =weight_count+16'd8;
            end
        else begin
            next_weight_count = weight_count;
        end
    end
    reg [15:0]row_weight_count;
    reg [15:0]next_row_weight_count;
    always@(posedge clk) begin
        if(!rst_n) begin
            row_weight_count <= 16'd0;
        end
        else begin
            row_weight_count <= next_row_weight_count;
        end
    end
    always@(*)begin
        if(weight_count==16'd112)begin //
            if(state==PreLoad||state==Wait0||state==Wait1||state==Comp)begin
                next_row_weight_count =row_weight_count+16'd1; 
            end
            else next_row_weight_count =row_weight_count; 
        end  
        else begin
            next_row_weight_count = row_weight_count;
        end
    end

    //weight counter to record what is currently computing ;
    reg [15:0]cpwt_count;
    reg [15:0]next_cpwt_count;
    always@(posedge clk) begin
        if(!rst_n) begin
            cpwt_count <= 16'd0;
        end
        else begin
            cpwt_count <= next_cpwt_count;
        end
    end
    always@(*)begin
        if (state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
                if(cpwt_count==16'd112)begin 
                    next_cpwt_count =0; 
                end
                else next_cpwt_count = cpwt_count+16'd8;
            end
        else begin
            next_cpwt_count = cpwt_count;
        end
    end
    reg [15:0]row_cpwt_count;
    reg [15:0]next_row_cpwt_count;
    always@(posedge clk) begin
        if(!rst_n) begin
            row_cpwt_count <= 16'd0;
        end
        else begin
            row_cpwt_count <= next_row_cpwt_count;
        end
    end
    always@(*)begin
        if(cpwt_count==16'd112)begin //
            if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
                next_row_cpwt_count =row_cpwt_count+16'd1; 
            end
            else next_row_cpwt_count =row_cpwt_count; 
        end  
        else begin
            next_row_cpwt_count = row_cpwt_count;
        end
    end

    
    //id of to-load activation 
    reg [7:0]cur_act_id;
    reg [7:0]next_cur_act_id;
    always@(posedge clk)begin
        if(!rst_n) begin
            cur_act_id<=8'd0;
        end
        else begin 
            cur_act_id <= next_cur_act_id;
        end
    end
    always @(*)begin
        if (state==PreLoad||state==Wait0||state==Wait1||state==Comp)begin
                if(cur_act_id==16'd112)begin //0,2,4,...18,20,then 21,23,25...39,41,then 42,44...
                    next_cur_act_id = 0; 
                end
                else next_cur_act_id = cur_act_id+16'd8;
            end
        else begin
            next_cur_act_id = cur_act_id;
        end
    end

    //id of computing act
    reg [7:0]cur_cpact_id;
    reg [7:0]next_cur_cpact_id;
    always@(posedge clk)begin
        if(!rst_n) begin
            cur_cpact_id<=8'd0;
        end
        else begin 
            cur_cpact_id <= next_cur_cpact_id;
        end
    end
    always @(*)begin
        if (state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
                if(cur_cpact_id==16'd112)begin //0,2,4,...18,20,then 21,23,25...39,41,then 42,44...
                    next_cur_cpact_id = 0; 
                end
                else next_cur_cpact_id = cur_cpact_id+16'd8;
            end
        else begin
            next_cur_cpact_id = cur_cpact_id;
        end
    end

    //save result
    reg signed[31:0]out_act;//1個 32 bit
    reg signed[31:0]next_out_psum;
    integer  i;
    always@(posedge clk)begin
        if(!rst_n) begin
            out_act <= 0;
        end
        else begin 
            out_act <= next_out_psum;
        end
    end
    always @(*)begin
        if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
            next_out_psum = out_act + comp_res;
        end
        else if(state==Quan)begin
            next_out_psum = 0;
        end
        else begin
            next_out_psum = out_act;
        end
    end
    
    //out id 
    reg [7:0]out_id_cnt;
    reg [7:0]next_out_id_cnt;
    always @(posedge clk)begin
        if(!rst_n)begin
            out_id_cnt <= 0;
        end
        else begin
            out_id_cnt <= next_out_id_cnt;
        end
    end
    always @(*)begin
        if(state==Quan)begin
            if(out_id_cnt==8'd83)begin
               next_out_id_cnt = 0; 
            end
            else begin
                next_out_id_cnt = out_id_cnt + 1;
            end
        end
        else begin
            next_out_id_cnt = out_id_cnt;
        end
    end
    //out id counter
    /*always @(posedge clk)begin
        if(!rst_n)begin
            finish = 0;
        end
        else begin
            out_id_cnt = next_out_id_cnt;
        end
    end
    always @(*)begin
        if(state==WriteData)begin
            if(out_id_cnt==8'd80)begin
               next_out_id_cnt = 0; 
            end
            else begin
                next_out_id_cnt = out_id_cnt + 8;
            end
        end
        else begin
            next_out_id_cnt = out_id_cnt;
        end
    end*/
    always @(*)begin
        if(state==Quan)begin
            in0=out_act;
        end
        else begin
            in0 = 0;
        end
    end
    always @(*)begin
        if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
            weight0=weight_rdata0;
            weight1=weight_rdata1; 
            activation0=act_rdata0;
            activation1=act_rdata1;
        end
        else begin
            weight0=0;
            weight1=0; 
            activation0=0;
            activation1=0;
        end
    end
    always @*begin
        case(state)
            Pre:begin
                if(start==1'b1)begin
                    next_state=PreLoad;
                end
                else begin
                    next_state=Pre;
                end
                weight_cen  =1'b1;
                act_cen     =1'b1;
                act_addr0=0;
                act_addr1=0;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                finish = 0;
            end
            PreLoad:begin
                weight_cen  =1'b0;
                act_cen     =1'b0;
                next_state=Wait0;
                act_addr0= act_offset + {10'b0,cur_act_id [7:2]};
                act_addr1= act_offset + {10'b0,cur_act_id [7:2]}+1;
                weight_addr0=weight_offset + row_weight_count*16'd30 + weight_count[15:2];
                weight_addr1=weight_offset + row_weight_count*16'd30 + weight_count[15:2]+16'd1;
                
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                finish = 0;
            end
            Wait0:begin
                weight_cen  =1'b0;
                act_cen     =1'b0;
                act_addr0= act_offset + {10'b0,cur_act_id [7:2]};
                act_addr1= act_offset + {10'b0,cur_act_id [7:2]}+1;
                weight_addr0=weight_offset + row_weight_count*16'd30 + weight_count[15:2];
                weight_addr1=weight_offset + row_weight_count*16'd30 + weight_count[15:2]+16'd1;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                finish = 0;
                next_state=Wait1;
            end
            Wait1:begin
                weight_cen  =1'b0;
                act_cen     =1'b0;
                act_addr0= act_offset + {10'b0,cur_act_id [7:2]};
                act_addr1= act_offset + {10'b0,cur_act_id [7:2]}+1;
                weight_addr0=weight_offset + row_weight_count*16'd30 + weight_count[15:2];
                weight_addr1=weight_offset + row_weight_count*16'd30 + weight_count[15:2]+16'd1;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                finish = 0;
                next_state=Comp;
            end
            
            Comp:begin
                //load data (3 cycle later)
                weight_cen  =1'b0;
                act_cen     =1'b0;
                act_addr0= act_offset + {10'b0,cur_act_id [7:2]};
                act_addr1= act_offset + {10'b0,cur_act_id [7:2]}+1;
                weight_addr0=weight_offset + row_weight_count*16'd30 + weight_count[15:2];
                weight_addr1=weight_offset + row_weight_count*16'd30 + weight_count[15:2]+16'd1;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                //data for computing
                if(weight_count==112)begin
                    next_state=Wait2;
                end
                else begin
                    next_state=Comp;
                end
                finish = 0;
            end 
            Wait2:begin
                weight_cen  =1'b1;
                act_cen     =1'b1;
                act_addr0=0;
                act_addr1=0;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Wait3;
                finish = 0;
            end
            Wait3:begin
                weight_cen  =1'b1;
                act_cen     =1'b1;
                act_addr0=0;
                act_addr1=0;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Wait4;
                finish = 0;
            end
            Wait4:begin
                weight_cen  =1'b1;
                act_cen     =1'b1;
                act_addr0=0;
                act_addr1=0;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Quan;
                finish = 0;
            end
            Quan:begin
                weight_cen  =1'b1;
                act_cen     =1'b0;
                //next_state=WriteData;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                finish = 0;
                case(out_id_cnt[1:0])
                    2'b00:begin
                        act_wea0  = 4'b0001;
                        act_wdata0 = {24'd0,quanout};
                    end
                    2'b01:begin
                        act_wea0  = 4'b0010;
                        act_wdata0 = {16'd0,quanout,8'd0};
                    end
                    2'b10:begin
                        act_wea0  = 4'b0100;
                        act_wdata0 = {8'd0,quanout,16'd0};
                    end
                    2'b11:begin
                        act_wea0  = 4'b1000;
                        act_wdata0 = {quanout,24'd0};
                    end
                    default:begin
                        act_wea0  = 4'b0000;
                        act_wdata0 = 32'd0;
                    end

                endcase
                
                act_addr0 = act_offset+30 + out_id_cnt[7:2];
                act_wea1  = 4'b0000; // can't write;
                act_addr1 = 16'd0;
                act_wdata1 = 0;
                if(out_id_cnt==8'd83)begin
                    next_state = Wait_write0;
                end
                else begin
                    next_state = PreLoad;
                end
                
            end
            Wait_write0:begin
                weight_cen  =1'b1;
                act_cen     =1'b1;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0  = 4'b0000;
                act_addr0 = 16'd0;
                act_wea1  = 4'b000; 
                act_addr1 = 16'd0 ;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state = Wait_write1;
                finish = 0;
            end
            Wait_write1:begin
                weight_cen  =1'b1;
                act_cen     =1'b1;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0  = 4'b0000;
                act_addr0 = 16'd0;
                act_wea1  = 4'b000; 
                act_addr1 = 16'd0 ;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state = Finish;
                finish = 0;
            end
            Finish:begin
                weight_cen  =1'b1;
                act_cen     =1'b1;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0  = 4'b0000;
                act_addr0 = 16'd0;
                act_wea1  = 4'b000; 
                act_addr1 = 16'd0 ;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state = Finish;
                finish = 1;
            end
            default:  begin
                weight_cen  =1'b1;
                act_cen     =1'b1;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0  = 4'b0000;
                act_addr0 = 16'd0;
                act_wea1  = 4'b000; 
                act_addr1 = 16'd0 ;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state=Pre;
                finish = 0;
            end 
        endcase
    end
endmodule



module fc7 (
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg finish,

    input wire [15:0] weight_offset,
    input wire [15:0] act_offset,
    input wire [31:0] scale,
    output reg weight_cen,
    output reg [ 3:0] weight_wea0,
    output reg [15:0] weight_addr0,
    input wire [31:0] weight_rdata0,
    output reg [ 3:0] weight_wea1,
    output reg [15:0] weight_addr1,
    input wire [31:0] weight_rdata1,

    // Activation sram, dual port
    output reg act_cen,
    output reg [ 3:0] act_wea0,
    output reg [15:0] act_addr0,
    output reg [31:0] act_wdata0,
    input wire [31:0] act_rdata0,
    output reg [ 3:0] act_wea1,
    output reg [15:0] act_addr1,
    output reg [31:0] act_wdata1,
    input wire [31:0] act_rdata1
);
    // Add your design here

    reg [3:0] state;
    reg [3:0] next_state;
    
    
    parameter [3:0] Pre=4'd0;
    parameter [3:0] PreLoad=4'd1;
    parameter [3:0] Comp=4'd2;
    parameter [3:0] Quan=4'd3;
    parameter [3:0] WriteData=4'd4;
    parameter [3:0] Wait_write0=4'd5;
    parameter [3:0] Wait_write1=4'd6;

    parameter [3:0] Finish=4'd8;
    parameter [3:0] Wait0=4'd10;
    parameter [3:0] Wait1=4'd11;
    parameter [3:0] Wait2=4'd12;
    parameter [3:0] Wait3=4'd13;
    parameter [3:0] Wait4=4'd14;

    
    reg [31:0]weight0;
    reg [31:0]weight1;
    reg [31:0]activation0;
    reg [31:0]activation1;
    wire signed [31:0]comp_res;
    innerproduct8 inpro8(
        .weight0(weight0[7 :0 ]),
        .weight1(weight0[15:8 ]),
        .weight2(weight0[23:16]),
        .weight3(weight0[31:24]),
        .weight4(weight1[7 :0 ]),
        .weight5(weight1[15:8 ]),
        .weight6(weight1[23:16]),
        .weight7(weight1[31:24]),
        
        .act0(activation0[7 :0 ]),
        .act1(activation0[15:8 ]),
        .act2(activation0[23:16]),
        .act3(activation0[31:24]),
        .act4(activation1[7 :0 ]),
        .act5(activation1[15:8 ]),
        .act6(activation1[23:16]),
        .act7(activation1[31:24]),

        .out(comp_res)
    );
    //ReLu, Quantization, Clamp
    reg [31:0]in0;
    reg [31:0]in1;
    //debug load bias
    reg [31:0]bias0;
    reg [31:0]bias1;
    wire [31:0]bias_out_act0;
    wire [31:0]bias_out_act1;
    /*relu_quan_bias32 reluq(
        .in0( in0 ),
        .in1( in1 ),
        .bias0( bias0 ),
        .bias1( bias1 ),
        .out0(bias_out_act0),
        .out1(bias_out_act1)
    );*/


    
    //weight count
    reg [15:0]weight_count;//0-20,21-41,42-62,63-83......
    reg [15:0]next_weight_count;
    always@(posedge clk) begin
        if(!rst_n) begin
            weight_count <= 16'd0;
        end
        else begin
            weight_count <= next_weight_count;
        end
    end
    always@(*)begin
        if (state==PreLoad||state==Wait0||state==Wait1||state==Comp)begin
                if(weight_count==16'd80)begin //0,2,4,...18,20,then 21,23,25...39,41,then 42,44...
                    next_weight_count =0; 
                end
                else next_weight_count =weight_count+16'd8;
            end
        else begin
            next_weight_count = weight_count;
        end
    end
    reg [15:0]row_weight_count;
    reg [15:0]next_row_weight_count;
    always@(posedge clk) begin
        if(!rst_n) begin
            row_weight_count <= 16'd0;
        end
        else begin
            row_weight_count <= next_row_weight_count;
        end
    end
    always@(*)begin
        if(weight_count==16'd80)begin //
            if(state==PreLoad||state==Wait0||state==Wait1||state==Comp)begin
                next_row_weight_count =row_weight_count+16'd1; 
            end
            else next_row_weight_count =row_weight_count; 
        end  
        else begin
            next_row_weight_count = row_weight_count;
        end
    end

    //weight counter to record what is currently computing ;
    reg [15:0]cpwt_count;
    reg [15:0]next_cpwt_count;
    always@(posedge clk) begin
        if(!rst_n) begin
            cpwt_count <= 16'd0;
        end
        else begin
            cpwt_count <= next_cpwt_count;
        end
    end
    always@(*)begin
        if (state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
                if(cpwt_count==16'd80)begin 
                    next_cpwt_count =0; 
                end
                else next_cpwt_count = cpwt_count+16'd8;
            end
        else begin
            next_cpwt_count = cpwt_count;
        end
    end
    reg [15:0]row_cpwt_count;
    reg [15:0]next_row_cpwt_count;
    always@(posedge clk) begin
        if(!rst_n) begin
            row_cpwt_count <= 16'd0;
        end
        else begin
            row_cpwt_count <= next_row_cpwt_count;
        end
    end
    always@(*)begin
        if(cpwt_count==16'd80)begin //
            if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
                next_row_cpwt_count =row_cpwt_count+16'd1; 
            end
            else next_row_cpwt_count =row_cpwt_count; 
        end  
        else begin
            next_row_cpwt_count = row_cpwt_count;
        end
    end

    
    //id of to-load activation 
    reg [7:0]cur_act_id;
    reg [7:0]next_cur_act_id;
    always@(posedge clk)begin
        if(!rst_n) begin
            cur_act_id<=8'd0;
        end
        else begin 
            cur_act_id <= next_cur_act_id;
        end
    end
    always @(*)begin
        if (state==PreLoad||state==Wait0||state==Wait1||state==Comp)begin
                if(cur_act_id==16'd80)begin //0,2,4,...18,20,then 21,23,25...39,41,then 42,44...
                    next_cur_act_id = 0; 
                end
                else next_cur_act_id = cur_act_id+16'd8;
            end
        else begin
            next_cur_act_id = cur_act_id;
        end
    end

    //id of computing act
    reg [7:0]cur_cpact_id;
    reg [7:0]next_cur_cpact_id;
    always@(posedge clk)begin
        if(!rst_n) begin
            cur_cpact_id<=8'd0;
        end
        else begin 
            cur_cpact_id <= next_cur_cpact_id;
        end
    end
    always @(*)begin
        if (state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
                if(cur_cpact_id==16'd80)begin //0,2,4,...18,20,then 21,23,25...39,41,then 42,44...
                    next_cur_cpact_id = 0; 
                end
                else next_cur_cpact_id = cur_cpact_id+16'd8;
            end
        else begin
            next_cur_cpact_id = cur_cpact_id;
        end
    end

    //save result
    reg signed[31:0]out_act[9:0];//10個 32 bit
    reg signed[31:0]next_out_psum;
    integer  i;
    always@(posedge clk)begin
        if(!rst_n) begin
            for (i=0;i<10;i=i+1)begin
                out_act[i]<=0;
            end
        end
        else begin 
            out_act[row_cpwt_count] <= next_out_psum;
        end
    end
    always @(*)begin
        if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
            next_out_psum = out_act[row_cpwt_count] + comp_res;
        end
        else begin
            next_out_psum = out_act[row_cpwt_count];
        end
    end
    
    //out id 
    reg [7:0]out_id_cnt;
    reg [7:0]next_out_id_cnt;
    always @(posedge clk)begin
        if(!rst_n)begin
            out_id_cnt <= 0;
        end
        else begin
            out_id_cnt <= next_out_id_cnt;
        end
    end
    always @(*)begin
        if(state==Quan)begin
            if(out_id_cnt==8'd8)begin
               next_out_id_cnt = 0; 
            end
            else begin
                next_out_id_cnt = out_id_cnt + 2;
            end
        end
        else begin
            next_out_id_cnt = 0;
        end
    end
    
    always @(*)begin
        if(state==Quan)begin
            in0 = out_act[out_id_cnt + 0];
            in1 = out_act[out_id_cnt + 1];
        end
        else begin
            in0 = 0;
            in1 = 0;
        end
    end
    //control the input of innerproduct
    always @(*)begin
        if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
            if(cur_cpact_id==80)begin
                weight0=weight_rdata0;
                weight1=0; 
                activation0=act_rdata0;
                activation1=0;
            end
            else begin
                weight0=weight_rdata0;
                weight1=weight_rdata1; 
                activation0=act_rdata0;
                activation1=act_rdata1;
            end
        end
        else begin
            weight0=0;
            weight1=0; 
            activation0=0;
            activation1=0;
        end
    end
    //load bias
    reg [3:0] bias_cnt;
    reg [3:0] next_bias_cnt;
    always @(posedge clk)begin
        if(!rst_n)begin
            bias_cnt <= 0;
        end
        else begin
            bias_cnt <= next_bias_cnt;
        end
    end
    always @(*)begin
        if(state==Wait2||state==Wait3||state==Wait4||state==Quan)begin
            next_bias_cnt = bias_cnt + 2;
        end
        else begin
            next_bias_cnt = bias_cnt;
        end
    end
    always @(*)begin
        if(state==Quan)begin
            bias0 = weight_rdata0;
            bias1 = weight_rdata1;
        end
        else begin
            bias0 = 0;
            bias1 = 0;
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
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0  = 4'b0000;
                act_addr0 = 16'd0;
                act_wea1  = 4'b000; 
                act_addr1 = 16'd0 ;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                if(start==1'b1)begin
                    next_state=PreLoad;
                end
                else begin
                    next_state=Pre;
                end
                finish = 0;
            end
            PreLoad:begin
                next_state=Wait0;
                weight_cen  = 1'b0;
                act_cen     = 1'b0;

                act_addr0= act_offset + {10'b0,cur_act_id [7:2]};
                act_addr1= act_offset + {10'b0,cur_act_id [7:2]}+1;
                weight_addr0=weight_offset + row_weight_count*16'd21 + weight_count[15:2];
                weight_addr1=weight_offset + row_weight_count*16'd21 + weight_count[15:2]+16'd1;
                
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                finish = 0;
            end
            Wait0:begin
                weight_cen  = 1'b0;
                act_cen     = 1'b0;

                act_addr0= act_offset + {10'b0,cur_act_id [7:2]};
                act_addr1= act_offset + {10'b0,cur_act_id [7:2]}+1;
                weight_addr0=weight_offset + row_weight_count*16'd21 + weight_count[15:2];
                weight_addr1=weight_offset + row_weight_count*16'd21 + weight_count[15:2]+16'd1;
                next_state=Wait1;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                finish = 0;
            end
            Wait1:begin
                weight_cen  = 1'b0;
                act_cen     = 1'b0;
                act_addr0= act_offset + {10'b0,cur_act_id [7:2]};
                act_addr1= act_offset + {10'b0,cur_act_id [7:2]}+1;
                weight_addr0=weight_offset + row_weight_count*16'd21 + weight_count[15:2];
                weight_addr1=weight_offset + row_weight_count*16'd21 + weight_count[15:2]+16'd1;
                next_state=Comp;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                finish = 0;
            end
            
            Comp:begin
                //load data (3 cycle later)
                weight_cen  = 1'b0;
                act_cen     = 1'b0;
                act_addr0= act_offset + {10'b0,cur_act_id [7:2]};
                act_addr1= act_offset + {10'b0,cur_act_id [7:2]}+1;
                weight_addr0=weight_offset + row_weight_count*16'd21 + weight_count[15:2];
                weight_addr1=weight_offset + row_weight_count*16'd21 + weight_count[15:2]+16'd1;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                //data for computing
                if(weight_count==80 && row_weight_count==16'd9)begin
                    next_state=Wait2;
                end
                else begin
                    next_state=Comp;
                end
                finish = 0;
            end 
            Wait2:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                act_addr0=0;
                act_addr1=0;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Wait3;
                finish = 0;
            end
            Wait3:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                act_addr0=0;
                act_addr1=0;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Wait4;
                finish = 0;
            end
            Wait4:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_addr0=0;
                act_addr1=0;
                act_wea0=4'b0000;
                act_wea1=4'b0000;
                act_wdata0 = 0;
                act_wdata1 = 0;
                next_state=Quan;
                finish = 0;
            end
            Quan:begin
                //next_state=WriteData;
                weight_cen  = 1'b1;
                act_cen     = 1'b0;
                weight_addr0=16'd15750 + bias_cnt;
                weight_addr1=16'd15750 + bias_cnt + 1;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0  = 4'b1111;
                act_addr0 = act_offset+21 + out_id_cnt;
                act_wea1  = 4'b1111; 
                act_addr1 = act_offset+21 + out_id_cnt + 1;
                act_wdata0 = in0;
                act_wdata1 = in1;
                if(out_id_cnt==8)begin
                    next_state = Wait_write0;
                end
                else begin
                    next_state = Quan;
                end
                finish = 0;
                
            end
            Wait_write0:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0  = 4'b0000;
                act_addr0 = 16'd0;
                act_wea1  = 4'b000; 
                act_addr1 = 16'd0 ;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state = Wait_write1;
                finish = 0;
            end
            Wait_write1:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0  = 4'b0000;
                act_addr0 = 16'd0;
                act_wea1  = 4'b000; 
                act_addr1 = 16'd0 ;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state = Finish;
                finish = 0;
            end
            Finish:begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0  = 4'b0000;
                act_addr0 = 16'd0;
                act_wea1  = 4'b000; 
                act_addr1 = 16'd0 ;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state = Finish;
                finish = 1;
            end
            default:  begin
                weight_cen  = 1'b1;
                act_cen     = 1'b1;
                weight_addr0=0;
                weight_addr1=0;
                weight_wea0 = 4'b0000;
                weight_wea1 = 4'b0000;
                act_wea0  = 4'b0000;
                act_addr0 = 16'd0;
                act_wea1  = 4'b000; 
                act_addr1 = 16'd0 ;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                next_state=Pre;
                finish = 0;
            end 
        endcase
    end
endmodule

module max1 (
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
        if(state==Out1)begin
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
    reg [7:0]outact [13:0];
    reg [7:0]next_outact [13:0];
    
    always @(posedge clk)begin
        if(!rst_n)begin
            for(i = 0; i <14;i=i+1)begin
                outact[i]<=0;
            end
        end
        else begin
            for(i = 0; i <14;i=i+1)begin
                outact[i]<=next_outact[i];
            end
        end
    end
    always @(*)begin
        for(i = 0; i <14;i=i+1)begin
            next_outact[i]=outact[i];
        end
        if(state==Comp||state==Wait2||state==Wait3||state==Wait4)begin
            next_outact[cpact_cnt]  =plout0;
            next_outact[cpact_cnt+1]=plout1;
        end
        else if(state==LoadAct)begin
            for(i = 0; i <14;i=i+1)begin
                next_outact[i]=0;
            end
        end

        else begin
            for(i = 0; i <14;i=i+1)begin
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
                act_addr0 = 16'd1024 + channel*196 + row_act_cnt      * 7 + act_cnt;
                act_addr1 = 16'd1024 + channel*196 + (row_act_cnt+1)  * 7 + act_cnt;
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
                act_addr0 = 16'd1024 + channel*196 + row_act_cnt      * 7 + act_cnt;
                act_addr1 = 16'd1024 + channel*196 + (row_act_cnt+1)  * 7 + act_cnt;
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
                act_addr0 = 16'd1024 + channel*196 + row_act_cnt      * 7 + act_cnt;
                act_addr1 = 16'd1024 + channel*196 + (row_act_cnt+1)  * 7 + act_cnt;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                next_state=Comp;
            end
            Comp:begin
                weight_cen  =1;
                act_cen     =0;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = 16'd1024 + channel*196 + row_act_cnt      * 7 + act_cnt;
                act_addr1 = 16'd1024 + channel*196 + (row_act_cnt+1)  * 7 + act_cnt;
                act_wea0 = 4'b0000;
                act_wea1 = 4'b0000;
                act_wdata0 = 32'd0;
                act_wdata1 = 32'd0;
                finish = 0;
                if(act_cnt==6)
                    next_state=Wait2;
                else
                    next_state=Comp;
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
                act_addr0 = act_offset + channel*56 + row_act_cnt*2;
                act_addr1 = act_offset + channel*56 + row_act_cnt*2+1;
                act_wea0 = 4'b1111;
                act_wea1 = 4'b1111;
                act_wdata0 = {outact[3], outact[2], outact[1], outact[0]};
                act_wdata1 = {outact[7], outact[6], outact[5], outact[4]};
                finish = 0;
                next_state=Out1;
            end
            Out1:begin
                weight_cen  =1;
                act_cen     =0;
                weight_addr0=16'd0;
                weight_addr1=16'd0;
                weight_wea0=4'b0000;
                weight_wea1=4'b0000;
                act_addr0 = act_offset + channel*56 + row_act_cnt*2+2;
                act_addr1 = act_offset + channel*56 + row_act_cnt*2+3;
                act_wea0 = 4'b1111;
                act_wea1 = 4'b1111;
                act_wdata0 = {outact[11], outact[10], outact[9], outact[8]};
                act_wdata1 = {16'd0, outact[13], outact[12]};
                finish = 0;
                if(channel==5)begin
                    if(row_act_cnt==26)
                        next_state=Waitend0;
                    else
                        next_state=LoadAct;
                end
                else begin
                    if(row_act_cnt==26)
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

module maxpool8_2(
    input wire signed [7:0] in0_0 ,
    input wire signed [7:0] in0_1 ,
    input wire signed [7:0] in0_2 ,
    input wire signed [7:0] in0_3 ,
    input wire signed [7:0] in1_0 ,
    input wire signed [7:0] in1_1 ,
    input wire signed [7:0] in1_2 ,
    input wire signed [7:0] in1_3 ,
    output [7:0] out0,
    output [7:0] out1

);
    wire signed [7:0] poolhf_0 ;
    wire signed [7:0] poolhf_1 ;
    wire signed [7:0] poolhf_2 ;
    wire signed [7:0] poolhf_3 ;
    
    assign poolhf_0  = (in0_0  > in1_0 ) ? in0_0  : in1_0  ;
    assign poolhf_1  = (in0_1  > in1_1 ) ? in0_1  : in1_1  ;
    assign poolhf_2  = (in0_2  > in1_2 ) ? in0_2  : in1_2  ;
    assign poolhf_3  = (in0_3  > in1_3 ) ? in0_3  : in1_3  ;

    wire signed [7:0] pool_0 ;
    wire signed [7:0] pool_1 ;

    assign pool_0  = (poolhf_0  > poolhf_1  ) ? poolhf_0   : poolhf_1  ;
    assign pool_1  = (poolhf_2  > poolhf_3  ) ? poolhf_2   : poolhf_3  ;
    assign out0 = pool_0;
    assign out1 = pool_1;
endmodule

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

