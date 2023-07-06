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
