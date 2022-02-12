////////////////////////////////////////////////////////////////////////////////
// R5P SoC
//
// NOTE: details on XPM libraries: ug953-vivado-7series-libraries.pdf
////////////////////////////////////////////////////////////////////////////////

module r5p_soc_arty #(
  // implementation device (ASIC/FPGA vendor/device)
  string CHIP = "ARTIX_GEN"
)(
  // system signals
  input  logic          CLK100MHZ,  // clock
  input  logic          ck_rst,     // reset (active low)
  // GPIO
  inout  wire  [42-1:0] ck_io
);

///////////////////////////////////////////////////////////////////////////////
// local parameters
////////////////////////////////////////////////////////////////////////////////

localparam int unsigned GW = 32;

///////////////////////////////////////////////////////////////////////////////
// local signals
////////////////////////////////////////////////////////////////////////////////

// clock
logic clk;

// reset synchronizer
logic rst;

// GPIO
logic [GW-1:0] gpio_o;
logic [GW-1:0] gpio_e;
logic [GW-1:0] gpio_i;

///////////////////////////////////////////////////////////////////////////////
// PLL
////////////////////////////////////////////////////////////////////////////////

// TODO: use proper PLL
assign clk = CLK100MHZ;

///////////////////////////////////////////////////////////////////////////////
// reset synchronizer
////////////////////////////////////////////////////////////////////////////////

//logic rst_r;

//always @(posedge clk, negedge ck_rst)
//if (~ck_rst)  {rst, rst_r} <= 2'b1;
//else          {rst, rst_r} <= {rst_r, 1'b0};

// xpm_cdc_async_rst: Asynchronous Reset Synchronizer
// Xilinx Parameterized Macro, version 2021.2
xpm_cdc_async_rst #(
 .DEST_SYNC_FF    (4), // DECIMAL; range: 2-10
 .INIT_SYNC_FF    (0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
 .RST_ACTIVE_HIGH (1)  // DECIMAL; 0=active low reset, 1=active high reset
)
xpm_cdc_async_rst_inst (
  .src_arst  (~ck_rst),
  .dest_arst (rst),
  .dest_clk  (clk)
);

////////////////////////////////////////////////////////////////////////////////
// R5P SoC instance
////////////////////////////////////////////////////////////////////////////////

r5p_soc_top #(
  .GW      (GW),
  .CHIP    (CHIP)
) soc (
  // system signals
  .clk     (clk),
  .rst     (rst),
  // GPIO
  .gpio_o  (gpio_o),
  .gpio_e  (gpio_e),
  .gpio_i  (gpio_i)
);

////////////////////////////////////////////////////////////////////////////////
// GPIO
////////////////////////////////////////////////////////////////////////////////

//logic [32-1:0] gpio_r;
//
//// asynchronous input synchronization
//always_ff @(posedge clk, posedge rst)
//if (rst) begin
//  gpio_r <= '0;
//  gpio_i <= '0;
//end else begin
//  gpio_r <= ck_io[32-1:0];
//  gpio_i <= gpio_r;
//end

// GPIO input synchronizer
// xpm_cdc_array_single: Single-bit Array Synchronizer
// Xilinx Parameterized Macro, version 2021.2
xpm_cdc_array_single #(
 .DEST_SYNC_FF   (2), // DECIMAL; range: 2-10
 .INIT_SYNC_FF   (0), // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
 .SIM_ASSERT_CHK (0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
 .SRC_INPUT_REG  (0), // DECIMAL; 0=do not register input, 1=register input
 .WIDTH         (GW)  // DECIMAL; range: 1-1024
) gpio_cdc (
 .src_clk  (clk),
 .src_in   (ck_io[GW-1:0]),
 .dest_clk (clk),
 .dest_out (gpio_i[GW-1:0])
);

// GPIO
generate
for (genvar i=0; i<GW; i++) begin
  assign ck_io[i] = gpio_e[i] ? gpio_o[i] : 1'bz;
end
endgenerate

// unused IO
assign ck_io[42-1:GW] = 1'bz;

endmodule: r5p_soc_arty