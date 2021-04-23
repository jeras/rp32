////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

module mem #(
  // 1kB by default
  string       FN = "",         // binary initialization file name
  int unsigned DW = 32,         // data    width
  int unsigned SW = DW/8,       // select  width
  int unsigned SZ = 2**12,      // memory size in bytes
  int unsigned AW = $clog2(SZ)  // address width
)(
  input  logic                 clk,  // clock
  input  logic                 req,  // write or read request
  input  logic                 wen,  // write enable
  input  logic [SW-1:0]        sel,  // byte select
  input  logic [AW-1:0]        adr,  // address
  input  logic [SW-1:0][8-1:0] wdt,  // write data
  output logic [SW-1:0][8-1:0] rdt,  // read data
  output logic                 ack   // write or read acknowledge
);

// word address width
localparam int unsigned WW = $clog2(SW);

logic [8-1:0] mem [0:SZ-1];

// write and read access
always @(posedge clk)
if (req) begin
  if (wen) begin
    // write access
    for (int unsigned i=0; i<SW; i++) begin
      if (sel[i])  mem[int'(adr)+i] <= wdt[i];
    end
  end else begin
    // read access
    for (int unsigned i=0; i<SW; i++) begin
      if (sel[i])  rdt[i] <= mem[int'(adr)+i];
      else         rdt[i] <= 'x;
    end
  end
end

// trivial acknowledge
assign ack = 1'b1;
//always @(posedge clk)
//  ack <= req;

// initialization
initial
if (FN!="") begin
  int code;  // status code
  int fd;    // file descriptor
  fd = $fopen(FN, "rb");
  code = $fread(mem, fd);
  $fclose(fd);
end

endmodule: mem