module top(
    input clk_25mhz,
    output led,
    output UART_TX,
    input UART_RX,
);

  wire clk = clk_25mhz;

  // wire break;
  reg [5:0] reset_cnt = 0;
  wire resetn = &reset_cnt;
  wire resetncpu = resetn; // & !break;

  always @(posedge clk) begin
      reset_cnt <= reset_cnt + !resetn;
  end

  parameter integer MEM_WORDS = 8192;
  parameter [31:0] STACKADDR = 32'h 0000_0000 + (4*MEM_WORDS);       // end of memory
  parameter [31:0] PROGADDR_RESET = 32'h 0000_0000;                 // start of memory

  reg [31:0] ram [0:MEM_WORDS-1];
  initial $readmemh("../firmware/firmware.hex", ram);
  reg [31:0] ram_rdata;
  reg ram_ready;

  wire mem_valid;
  wire mem_instr;
  wire mem_ready;
  wire [31:0] mem_addr;
  wire [31:0] mem_wdata;
  wire [3:0] mem_wstrb;
  wire [31:0] mem_rdata;

  always @(posedge clk)
  begin
    ram_ready <= 1'b0;
    if (mem_addr[31:24] == 8'h00 && mem_valid) begin
      if (mem_wstrb[0]) ram[mem_addr[23:2]][7:0] <= mem_wdata[7:0];
      if (mem_wstrb[1]) ram[mem_addr[23:2]][15:8] <= mem_wdata[15:8];
      if (mem_wstrb[2]) ram[mem_addr[23:2]][23:16] <= mem_wdata[23:16];
      if (mem_wstrb[3]) ram[mem_addr[23:2]][31:24] <= mem_wdata[31:24];

      ram_rdata <= ram[mem_addr[23:2]];
      ram_ready <= 1'b1;
    end
  end

  wire iomem_valid;
  reg iomem_ready;
  wire [31:0] iomem_addr;
  wire [31:0] iomem_wdata;
  wire [3:0] iomem_wstrb;
  wire [31:0] iomem_rdata;

  assign iomem_valid = mem_valid && (mem_addr[31:24] > 8'h 01);
  assign iomem_wstrb = mem_wstrb;
  assign iomem_addr = mem_addr;
  assign iomem_wdata = mem_wdata;

  wire        simpleuart_reg_div_sel = mem_valid && (mem_addr == 32'h 0200_0004);
  wire [31:0] simpleuart_reg_div_do;

  wire        simpleuart_reg_dat_sel = mem_valid && (mem_addr == 32'h 0200_0008);
  wire [31:0] simpleuart_reg_dat_do;
  wire simpleuart_reg_dat_wait;

  always @(posedge clk) begin
    iomem_ready <= 1'b0;
    if (iomem_valid && iomem_wstrb[0] && mem_addr == 32'h 02000000) begin
      led <= iomem_wdata[0];
      iomem_ready <= 1'b1;
    end
  end


  assign mem_ready = (iomem_valid && iomem_ready) ||
                     simpleuart_reg_div_sel || (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait) ||
                     ram_ready;

  assign mem_rdata = simpleuart_reg_div_sel ? simpleuart_reg_div_do :
                     simpleuart_reg_dat_sel ? simpleuart_reg_dat_do :
                      ram_rdata;


picorv32 #(
  .ENABLE_COUNTERS(0),
  .ENABLE_COUNTERS64(0),
  .ENABLE_REGS_16_31(0),
  .ENABLE_REGS_DUALPORT(0),
  .LATCHED_MEM_RDATA(0),
  .TWO_STAGE_SHIFT(0),
  .BARREL_SHIFTER(0),
  .TWO_CYCLE_COMPARE(0),
  .TWO_CYCLE_ALU(0),
  .COMPRESSED_ISA(0),
  .CATCH_MISALIGN(0),
  .CATCH_ILLINSN(0),
  .ENABLE_PCPI(0),
  .ENABLE_MUL(0),
  .ENABLE_FAST_MUL(0),
  .ENABLE_DIV(0),
  .ENABLE_IRQ(0),
  .ENABLE_IRQ_QREGS(0),
  .ENABLE_IRQ_TIMER(0),
  .ENABLE_TRACE(0),
  .REGS_INIT_ZERO(0),
  .MASKED_IRQ(32'h 0000_0000),
  .LATCHED_IRQ(32'h ffff_ffff),
  .PROGADDR_RESET(PROGADDR_RESET),
  .PROGADDR_IRQ(32'h 0000_0000),
  .STACKADDR(STACKADDR),
) cpu (
  .clk         (clk        ),
  .resetn      (resetncpu  ),
  .mem_valid   (mem_valid  ),
  .mem_instr   (mem_instr  ),
  .mem_ready   (mem_ready  ),
  .mem_addr    (mem_addr   ),
  .mem_wdata   (mem_wdata  ),
  .mem_wstrb   (mem_wstrb  ),
  .mem_rdata   (mem_rdata  )
);

simpleuart # (
  .DEFAULT_DIV(217)
) simpleuart (
  .clk         (clk         ),
  .resetn      (resetn      ),

  .ser_tx      (UART_TX     ),
  .ser_rx      (UART_RX     ),

  .reg_div_we  (simpleuart_reg_div_sel ? mem_wstrb : 4'b 0000),
  .reg_div_di  (mem_wdata),
  .reg_div_do  (simpleuart_reg_div_do),

  .reg_dat_we  (simpleuart_reg_dat_sel ? mem_wstrb[0] : 1'b 0),
  .reg_dat_re  (simpleuart_reg_dat_sel && !mem_wstrb),
  .reg_dat_di  (mem_wdata),
  .reg_dat_do  (simpleuart_reg_dat_do),
  .reg_dat_wait(simpleuart_reg_dat_wait)
);


endmodule
