`timescale 1ns/1ps

//`define L1_BUFFER

// You can modify CYCLE to meet your clock period.
// You can modify END_CYCLES to ensure the simulation can be finished.
`define CYCLE 4.1 
`define END_CYCLES 100000  
module RAE_tb();
    // ===== System Information =====
    integer i;
    integer layer_count;
    integer cycle_count;
    integer L2_weight_count;
    integer L2_act_count;
    reg start_count;
`ifdef L1_BUFFER
    integer L1_count; 
`endif


    // ===== SRAM Signals =====
    wire        sram_weight_cen;
    wire [ 3:0] sram_weight_wea0;
    wire [15:0] sram_weight_addr0;
    wire [31:0] sram_weight_wdata0;
    wire [31:0] sram_weight_rdata0;
    wire [ 3:0] sram_weight_wea1;
    wire [15:0] sram_weight_addr1;
    wire [31:0] sram_weight_wdata1;
    wire [31:0] sram_weight_rdata1;
    
    wire        sram_act_cen;
    wire [ 3:0] sram_act_wea0;
    wire [15:0] sram_act_addr0;
    wire [31:0] sram_act_wdata0;
    wire [31:0] sram_act_rdata0;
    wire [ 3:0] sram_act_wea1;
    wire [15:0] sram_act_addr1;
    wire [31:0] sram_act_wdata1;
    wire [31:0] sram_act_rdata1;

    // ===== Golden =====
    reg [31:0] golden [0:1023];

    // ===== Testbench Signals =====
    reg         clk;
    reg         rst_n;
    reg [23:0]  conf;
    reg         valid;
    wire        ready;
    wire [1:0]  status;
    
    reg [31:0] configuration [0:6];

    // ===== Module instantiation =====
    RAE u_RAE(
        .clk(clk),
        .rst_n(rst_n),
        .conf(conf),        
        .valid(valid),
        .ready(ready),
        .status(status),

        // Dual-port weight sram ports
        .sram_weight_cen(sram_weight_cen),
        .sram_weight_wea0(sram_weight_wea0),
        .sram_weight_addr0(sram_weight_addr0),
        .sram_weight_wdata0(sram_weight_wdata0),
        .sram_weight_rdata0(sram_weight_rdata0),
        .sram_weight_wea1(sram_weight_wea1),
        .sram_weight_addr1(sram_weight_addr1),
        .sram_weight_wdata1(sram_weight_wdata1),
        .sram_weight_rdata1(sram_weight_rdata1),

        // Dual-port activation sram ports
        .sram_act_cen(sram_act_cen),
        .sram_act_wea0(sram_act_wea0),
        .sram_act_addr0(sram_act_addr0),
        .sram_act_wdata0(sram_act_wdata0),
        .sram_act_rdata0(sram_act_rdata0),
        .sram_act_wea1(sram_act_wea1),
        .sram_act_addr1(sram_act_addr1),
        .sram_act_wdata1(sram_act_wdata1),
        .sram_act_rdata1(sram_act_rdata1)
    );

    SRAM_weight_16384x32b weight_sram( 
        .clk(clk),
        .cen(sram_weight_cen),
        .wea0(sram_weight_wea0),
        .addr0(sram_weight_addr0),
        .wdata0(sram_weight_wdata0),
        .rdata0(sram_weight_rdata0),
        .wea1(sram_weight_wea1),
        .addr1(sram_weight_addr1),
        .wdata1(sram_weight_wdata1),
        .rdata1(sram_weight_rdata1)
    );
    
    SRAM_activation_4096x32b act_sram( 
        .clk(clk),
        .cen(sram_act_cen),
        .wea0(sram_act_wea0),
        .addr0(sram_act_addr0),
        .wdata0(sram_act_wdata0),
        .rdata0(sram_act_rdata0),
        .wea1(sram_act_wea1),
        .addr1(sram_act_addr1),
        .wdata1(sram_act_wdata1),
        .rdata1(sram_act_rdata1)       
    );

    integer test_lenet=1;
    // ===== Load data ===== //
    initial begin
        // TODO: you should change the filename for your own
        
        case(test_lenet)
            0:begin
                weight_sram.load_data("../pattern/patterns/lenet0/img0/weights.csv");
                act_sram.load_data("../pattern/patterns/lenet0/img0/image.csv");
                $readmemh("../pattern/patterns/lenet0/img0/golden.csv", golden);
                $readmemh("../pattern/patterns/lenet0/img0/conf_bits.csv", configuration);
            end
            1:begin
                weight_sram.load_data("../pattern/patterns/lenet1/img0/weights.csv");
                act_sram.load_data("../pattern/patterns/lenet1/img0/image.csv");
                $readmemh("../pattern/patterns/lenet1/img0/golden.csv", golden);
                $readmemh("../pattern/patterns/lenet1/img0/conf_bits.csv", configuration);
            end
            2:begin
                weight_sram.load_data("../pattern/patterns/lenet2/img0/weights.csv");
                act_sram.load_data("../pattern/patterns/lenet2/img0/image.csv");
                $readmemh("../pattern/patterns/lenet2/img0/golden.csv", golden);
                $readmemh("../pattern/patterns/lenet2/img0/conf_bits.csv", configuration);
            end
            3:begin
                weight_sram.load_data("../pattern/patterns/lenet3/img0/weights.csv");
                act_sram.load_data("../pattern/patterns/lenet3/img0/image.csv");
                $readmemh("../pattern/patterns/lenet3/img0/golden.csv", golden);
                $readmemh("../pattern/patterns/lenet3/img0/conf_bits.csv", configuration);
            end
            4:begin
                weight_sram.load_data("../pattern/patterns/lenet4/img0/weights.csv");
                act_sram.load_data("../pattern/patterns/lenet4/img0/image.csv");
                $readmemh("../pattern/patterns/lenet4/img0/golden.csv", golden);
                $readmemh("../pattern/patterns/lenet4/img0/conf_bits.csv", configuration);
            end
            5:begin
                weight_sram.load_data("../pattern/patterns/lenet5/img0/weights.csv");
                act_sram.load_data("../pattern/patterns/lenet5/img0/image.csv");
                $readmemh("../pattern/patterns/lenet5/img0/golden.csv", golden);
                $readmemh("../pattern/patterns/lenet5/img0/conf_bits.csv", configuration);
            end
            default:begin
                weight_sram.load_data("../pattern/patterns/lenet0/img0/weights.csv");
                act_sram.load_data("../pattern/patterns/lenet0/img0/image.csv");
                $readmemh("../pattern/patterns/lenet0/img0/golden.csv", golden);
                $readmemh("../pattern/patterns/lenet0/img0/conf_bits.csv", configuration);
            end
        endcase

    end


    // ===== System reset ===== //
    initial begin
        clk = 0;
        rst_n = 1;
        cycle_count = 0;
        L2_weight_count = 0;
        L2_act_count = 0;
        layer_count = 0; 

`ifdef L1_BUFFER
        L1_count = 0;        
`endif
    end
    
    // ===== Cycle Count ===== //
    initial begin
        while(layer_count < 7)
            raise_start;
    end

    always @(posedge clk) begin
        if(start_count)
            cycle_count <= cycle_count + 1;
    end 

    // ==== Layer Count ==== //
    always@(posedge valid) begin        
        layer_count <= layer_count + 1;
    end

    // ==== L2 Buffer Access Time ==== //
    always@(posedge clk) begin        
        if(~ready)begin
            if(~sram_weight_cen) 
                L2_weight_count <= L2_weight_count + 1; 
        end
    end

    always@(posedge clk) begin        
        if(~ready)begin
            if(~sram_act_cen)
                L2_act_count <= L2_act_count + 1; 
        end
    end
    
    // ==== L1 Buffer Access Time ==== //
	// This always block is a reference for counting access counts.
	// Please modify this block to count the access counts 
	// via the chip enable signals if you have a L1 buffer.
`ifdef L1_BUFFER    
    always@(posedge clk) begin        
        if(~ready)begin
            if(~u_RAE.bank0.cen) 
                L1_count <= L1_count + 1; 
            if(~u_RAE.bank1_cen)
                L1_count <= L1_count + 1; 
        end
    end
`endif

   
    // ===== Time Exceed Abortion ===== //
    initial begin
        #(`CYCLE*`END_CYCLES);
        $display("\n========================================================");
        $display("You have exceeded the cycle count limit.");
        $display("Simulation abort");
        $display("========================================================");
        $finish;    
    end

    // ===== Clock Generator ===== //
    always #(`CYCLE/2) begin
        clk = ~clk;
    end 

    // ===== Set simulation info ===== //
    initial begin
    // $dumpfile("RAE.vcd");
    // $dumpvars("+all");
    //$fsdbDumpfile("RAE.fsdb");
    //$fsdbDumpvars("+mda");
    // $sdf_annotate("../syn/netlist/RAE_syn.sdf", u_RAE);
    `ifdef GATESIM
        $dumpfile("RAE_syn.vcd");
        $dumpvars("+all");
        //$fsdbDumpfile("RAE.fsdb");
        //$fsdbDumpvars("+mda");
        $sdf_annotate("../syn/netlist/RAE_syn.sdf", u_RAE);
	`else
        `ifdef POSTSIM
            $dumpfile("RAE_post.vcd");
            $dumpvars("+all");
            //$fsdbDumpfile("RAE.fsdb");
            //$fsdbDumpvars("+mda");
            $sdf_annotate("../apr/netlist/CHIP.sdf",u_RAE );
        `else
            //$dumpfile("RAE.vcd");
            //$dumpvars("+all");
            $fsdbDumpfile("rae.fsdb");
            $fsdbDumpvars("+mda");
        `endif
    `endif
    end
        

    // ===== Simulating  ===== //
    initial begin
        #(`CYCLE);
        $display("Reset System");
        @(negedge clk);
        rst_n = 1'b0;
        #(`CYCLE);
        rst_n = 1'b1;
		valid = 1'b0;
        conf = 'b0;
        #(`CYCLE);
        
        while(layer_count < 7)begin
            wait(ready && status == 2'b00);
            //$display("L2 weight     of layer",layer_count," ",L2_weight_count);
            //$display("L2 activation of layer",layer_count," ",L2_act_count);  
            computing;
            
        end
        
        wait(ready && status == 2'b00 && layer_count == 7);
        $display("Computation is finished, start validating result...");
        if(test_lenet<=3)validate;
        else validate_28;
        

        $display("Simulation finish");
        $finish;
    end

    task computing; begin
        @(negedge clk);
        conf = configuration[layer_count][23:0];       
        valid = 1'b1;
        @(negedge clk);
        valid = 1'b0;

        // Verify if the RAE shows BUSY status
        wait(status == 2'b01);
    end
    endtask

    task raise_start; begin
        wait(valid);
        start_count = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        //@(posedge clk);
        wait(ready == 1);
        start_count = 0;
    end
    endtask

    integer errors, total_errors;
    task validate; begin
        // Input Image
        total_errors = 0;
        $display("=====================");

        errors = 0;
        for(i=0 ; i<256 ; i=i+1)
            if(golden[i] !== act_sram.RAM[i]) begin
                $display("[ERROR]   [%d] Image Result:%8h Golden:%8h", i, act_sram.RAM[i], golden[i]);
                errors = errors + 1;
            end
            else begin
                //$display("[CORRECT]   [%d] Image Result:%8h Golden:%8h", i, act_sram.RAM[i], golden[i]);
            end
        if(errors == 0)
            $display("Image             [PASS]");
        else
            $display("Image             [FAIL]");
        total_errors = total_errors + errors;
            
        // Conv1
        errors = 0;
        for(i=256 ; i<592 ; i=i+1)
            if(golden[i] !== act_sram.RAM[i]) begin
                $display("[ERROR]   [%d] Conv1 Result:%8h Golden:%8h", i-256, act_sram.RAM[i], golden[i]);
                errors = errors + 1;
            end
            else begin
                //$display("[CORRECT]   [%d] Conv1 Result:%8h Golden:%8h", i-256, act_sram.RAM[i], golden[i]);
            end
        if(errors == 0)
            $display("Conv 1 activation [PASS]");
        else
            $display("Conv 1 activation [FAIL]");
        total_errors = total_errors + errors;
            
        // Conv2
        errors = 0;
        for(i=592 ; i<692 ; i=i+1)
            if(golden[i] !== act_sram.RAM[i]) begin
                $display("[ERROR]     [%d] Conv2 Result:%8h Golden:%8h", i-592, act_sram.RAM[i], golden[i]);
                errors = errors + 1;
            end
            else begin
                //$display("[CORRECT]   [%d] Conv2 Result:%8h Golden:%8h", i-592, act_sram.RAM[i], golden[i]);
            end
        if(errors == 0)
            $display("Conv 2 activation [PASS]");
        else
            $display("Conv 2 activation [FAIL]");
        total_errors = total_errors + errors;

        // Conv3
        errors = 0;
        for(i=692 ; i<722 ; i=i+1)
            if(golden[i] !== act_sram.RAM[i]) begin
                $display("[ERROR]     [%d] Conv3 Result:%8h Golden:%8h", i-692, act_sram.RAM[i], golden[i]);
                errors = errors + 1;
            end
            else begin
                //$display("[CORRECT]   [%d] Conv3 Result:%8h Golden:%8h", i-692, act_sram.RAM[i], golden[i]);
            end
        if(errors == 0)
            $display("Conv 3 activation [PASS]");
        else
            $display("Conv 3 activation [FAIL]");
        total_errors = total_errors + errors;
        
        // FC1
        errors = 0;
        for(i=722 ; i<743 ; i=i+1)
            if(golden[i] !== act_sram.RAM[i]) begin
                //$display("[ERROR]   [%d] FC1 Result:%8h Golden:%8h", i-722, act_sram.RAM[i], golden[i]);
                errors = errors + 1;
            end 
            else begin
                //$display("[CORRECT]   [%d] FC1 Result:%8h Golden:%8h", i-722, act_sram.RAM[i], golden[i]);
            end
        if(errors == 0)
            $display("FC   1 activation [PASS]");
        else 
            $display("FC   1 activation [FAIL]");
        total_errors = total_errors + errors;
        
        // FC2
        errors = 0;
        for(i=743 ; i<753 ; i=i+1)
            if(golden[i] !== act_sram.RAM[i]) begin
                $display("[ERROR]   [%d] FC2 Result:%8h Golden:%8h", i-743, act_sram.RAM[i], golden[i]);
                errors = errors + 1;
            end 
            else begin
                //$display("[CORRECT]   [%d] FC2 Result:%8h Golden:%8h", i-743, act_sram.RAM[i], golden[i]);
            end
        if(errors == 0)
            $display("FC   2 activation [PASS]");
        else
            $display("FC   2 activation [FAIL]");
        total_errors = total_errors + errors;

        if(total_errors == 0) begin
            $display(">>> Congratulation! All result are correct");
        end
        else begin
            $display(">>> There are %d errors", total_errors);
        end
    `ifdef GATESIM
        $display("  [Pre-layout gate-level simulation]");
	`else
        `ifdef POSTSIM
            $display("  [Post-layout gate-level simulation]");
        `else
            $display("  [RTL simulation]\n");
        `endif
    `endif
        $display("Clock Period: %.2f ns,Total cycle count: %d cycles", `CYCLE, cycle_count);
        `ifdef L1_BUFFER
            $display("L1 Buffer Access times:\t\t\t  %d", L1_count);
        `endif    
        $display("L2 Weight Buffer Access times:\t\t  %d", L2_weight_count);
        $display("L2 Actication Buffer Access times:\t  %d", L2_act_count);
        $display("=====================");
    end
    endtask

    task validate_28; begin
        // Input Image
        total_errors = 0;
        $display("=====================");

        errors = 0;
        for(i=0 ; i<196 ; i=i+1)
            if(golden[i] !== act_sram.RAM[i]) begin
                $display("[ERROR]   [%d] Image Result:%8h Golden:%8h", i, act_sram.RAM[i], golden[i]);
                errors = errors + 1;
            end
            else begin
                //$display("[CORRECT]   [%d] Image Result:%8h Golden:%8h", i, act_sram.RAM[i], golden[i]);
            end
        if(errors == 0)
            $display("Image             [PASS]");
        else
            $display("Image             [FAIL]");
        total_errors = total_errors + errors;
            
        // Conv1
        errors = 0;
        for(i=196 ; i<532 ; i=i+1)
            if(golden[i] !== act_sram.RAM[i]) begin
                $display("[ERROR]   [%d] Conv1 Result:%8h Golden:%8h", i-196, act_sram.RAM[i], golden[i]);
                errors = errors + 1;
            end
            else begin
                //$display("[CORRECT]   [%d] Conv1 Result:%8h Golden:%8h", i-196, act_sram.RAM[i], golden[i]);
            end
        if(errors == 0)
            $display("Conv 1 activation [PASS]");
        else
            $display("Conv 1 activation [FAIL]");
        total_errors = total_errors + errors;
            
        // Conv2
        errors = 0;
        for(i=532 ; i<632 ; i=i+1)
            if(golden[i] !== act_sram.RAM[i]) begin
                $display("[ERROR]     [%d] Conv2 Result:%8h Golden:%8h", i-532, act_sram.RAM[i], golden[i]);
                errors = errors + 1;
            end
            else begin
                //$display("[CORRECT]   [%d] Conv2 Result:%8h Golden:%8h", i-592, act_sram.RAM[i], golden[i]);
            end
        if(errors == 0)
            $display("Conv 2 activation [PASS]");
        else
            $display("Conv 2 activation [FAIL]");
        total_errors = total_errors + errors;

        // Conv3
        errors = 0;
        for(i=632 ; i<662 ; i=i+1)
            if(golden[i] !== act_sram.RAM[i]) begin
                $display("[ERROR]     [%d] Conv3 Result:%8h Golden:%8h", i-632, act_sram.RAM[i], golden[i]);
                errors = errors + 1;
            end
            else begin
                //$display("[CORRECT]   [%d] Conv3 Result:%8h Golden:%8h", i-692, act_sram.RAM[i], golden[i]);
            end
        if(errors == 0)
            $display("Conv 3 activation [PASS]");
        else
            $display("Conv 3 activation [FAIL]");
        total_errors = total_errors + errors;
        
        // FC1
        errors = 0;
        for(i=662 ; i<683 ; i=i+1)
            if(golden[i] !== act_sram.RAM[i]) begin
                $display("[ERROR]   [%d] FC1 Result:%8h Golden:%8h", i-662, act_sram.RAM[i], golden[i]);
                errors = errors + 1;
            end 
            else begin
                //$display("[CORRECT]   [%d] FC1 Result:%8h Golden:%8h", i-722, act_sram.RAM[i], golden[i]);
            end
        if(errors == 0)
            $display("FC   1 activation [PASS]");
        else 
            $display("FC   1 activation [FAIL]");
        total_errors = total_errors + errors;
        
        // FC2
        errors = 0;
        for(i=683 ; i<693 ; i=i+1)
            if(golden[i] !== act_sram.RAM[i]) begin
                $display("[ERROR]   [%d] FC2 Result:%8h Golden:%8h", i-683, act_sram.RAM[i], golden[i]);
                errors = errors + 1;
            end 
            else begin
                //$display("[CORRECT]   [%d] FC2 Result:%8h Golden:%8h", i-743, act_sram.RAM[i], golden[i]);
            end
        if(errors == 0)
            $display("FC   2 activation [PASS]");
        else
            $display("FC   2 activation [FAIL]");
        total_errors = total_errors + errors;

        if(total_errors == 0) begin
            $display(">>> Congratulation! All result are correct");
        end
        else begin
            $display(">>> There are %d errors", total_errors);
        end
    `ifdef GATESIM
        $display("  [Pre-layout gate-level simulation]");
	`else
        `ifdef POSTSIM
            $display("  [Post-layout gate-level simulation]");
        `else
            $display("  [RTL simulation]\n");
        `endif
    `endif
        $display("Clock Period: %.2f ns,Total cycle count: %d cycles", `CYCLE, cycle_count);
        `ifdef L1_BUFFER
            $display("L1 Buffer Access times:\t\t\t  %d", L1_count);
        `endif    
        $display("L2 Weight Buffer Access times:\t\t  %d", L2_weight_count);
        $display("L2 Actication Buffer Access times:\t  %d", L2_act_count);
        $display("=====================");
    end
    endtask
    

endmodule