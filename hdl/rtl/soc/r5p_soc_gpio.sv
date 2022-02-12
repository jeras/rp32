////////////////////////////////////////////////////////////////////////////////
// GPIO controller RTL
//
// NOTE: In case this module is connected to asynchronous signals,
//       the input signals `gpio_i` require a CDC synchronizer.
////////////////////////////////////////////////////////////////////////////////

module r5p_soc_gpio #(
  int unsigned GW = 32,   // GPIO width
  bit     CFG_MIN = 1'b0  // minimalistic implementation
)(
  // GPIO signals
  output logic [GW-1:0] gpio_o,
  output logic [GW-1:0] gpio_e,
  input  logic [GW-1:0] gpio_i,
  // bus interface
  r5p_bus_if.sub bus
);

generate
if (CFG_MIN) begin: gen_min

  // minimalistic implementation
  // only the GPIO input can be read
  assign bus.rdt = gpio_i;

end: gen_min
else begin: gen_nrm

  // normal implementation
  // output registers and GPIO input are decoded and properly delayed
  always_ff @(posedge bus.clk, posedge bus.rst)
  if (bus.rst) begin
    bus.rdt <= '0;
  end else if (bus.vld & bus.rdy) begin
    if (~bus.wen) begin
      // read access
      case (bus.adr[4-1:0])
        4'h0:    bus.rdt <= gpio_o;
        4'h4:    bus.rdt <= gpio_e;
        4'h8:    bus.rdt <= gpio_i;
        default: bus.rdt <= 'x;
      endcase
    end
  end

end: gen_nrm
endgenerate

// write output and output enable
always_ff @(posedge bus.clk, posedge bus.rst)
if (bus.rst) begin
  gpio_o <= '0;
  gpio_e <= '0;
end else if (bus.vld & bus.rdy) begin
  if (bus.wen) begin
    // write access
    case (bus.adr[4-1:0])
      4'h0:    gpio_o <= bus.wdt[GW-1:0];
      4'h4:    gpio_e <= bus.wdt[GW-1:0];
      default: ;  // do nothing
    endcase
  end
end

// controller response is immediate
assign bus.rdy = 1'b1;

endmodule: r5p_soc_gpio