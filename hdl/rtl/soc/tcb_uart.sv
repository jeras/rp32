////////////////////////////////////////////////////////////////////////////////
// TCB interface UART controller
////////////////////////////////////////////////////////////////////////////////
// Copyright 2022 Iztok Jeras
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
///////////////////////////////////////////////////////////////////////////////

module tcb_uart #(
  // UART parameters
  parameter int    BYTESIZE = 8,              // transfer size in bits
  parameter string PARITY   = "NONE",         // parity type "EVEN", "ODD", "NONE"
  parameter int    STOPSIZE = 1,              // number of stop bits
  parameter int    N_BIT    = 2,              // clock cycles per bit
  parameter int    N_LOG    = $clog2(N_BIT)   // size of boudrate generator counter
)(
  // UART
  input  logic uart_rxd,  // receive
  output logic uart_txd,  // transmit
  // system bus interface
  tcb_if.sub   bus
);

// UART transfer length
localparam UTL = BYTESIZE + (PARITY!="NONE") + STOPSIZE;

// parity option
localparam CFG_PRT = (PARITY!="EVEN");

// Avalon signals
logic bus_trn;

// baudrate signals
logic    [N_LOG-1:0] txd_bdr, rxd_bdr;
logic                txd_ena, rxd_ena;

// ser/des signals
logic                ser_run, des_run;  // transfer run status
logic          [3:0] ser_cnt, des_cnt;  // transfer length counter
logic [BYTESIZE-1:0] ser_dat, des_dat;  // data shift register
logic                ser_prt, des_prt;  // parity register

logic                rxd_start, rxd_end;
 
// receiver status
logic                status_rdy;  // receive data ready
logic                status_err;  // receive data error
logic                status_prt;  // receive data parity error
logic [BYTESIZE-1:0] status_dat;  // receive data register

//////////////////////////////////////////////////////////////////////////////
// TCB logic
//////////////////////////////////////////////////////////////////////////////

// TCB transfer status
assign bus_trn = bus.vld & bus.rdy;

// TCB read data
assign bus.rdt = {status_rdy, status_err, status_prt, {ADW-BYTESIZE-3{1'b0}}, status_dat};

// interrupt request
assign irq = status_rdy | status_err;

//////////////////////////////////////////////////////////////////////////////
// UART transmitter FIFO
//////////////////////////////////////////////////////////////////////////////



//////////////////////////////////////////////////////////////////////////////
// serializer
//////////////////////////////////////////////////////////////////////////////

// baudrate generator from clock (it counts down to 0 generating a baud pulse)
always @ (posedge bus.clk, posedge bus.rst)
if (bus.rst)  ser_bdr <= cfg_bdr;
else          ser_bdr <= ser_ena ? cfg_bdr : ser_bdr - ~ser_rdy;

// enable signal for shifting logic
assign ser_ena = ~|ser_bdr;

// serializer handshake (parallel transfer)
assign ser_trn = ser_vld & ser_rdy;

// bit counter
always @ (posedge bus.clk, posedge bus.rst)
if (bus.rst)    ser_cnt <= 4'd0;
else begin
  if (ser_trn)  ser_cnt <= UTL;
  else          ser_cnt <= ser_cnt-1;
end

// serializer handshake ready (parallel transfer)
assign ser_rdy = ~|ser_cnt;

// data shift register
// without reset, to reduce ASIC area
always @(posedge bus.clk)
if      (ser_trn)  ser_reg <= ser_dat;
else if (ser_ena)  ser_reg <= {1'b1, ser_reg[BYTESIZE-1:1]};

// output register
// reset to STOP state
always @(posedge bus.clk, posedge bus.rst)
if       (bus.rst)  ser_bit <= 1'b1;
else if (~ser_rdy)  ser_bit <= txd_dat[0];

//////////////////////////////////////////////////////////////////////////////
// UART receiver
//////////////////////////////////////////////////////////////////////////////

reg uart_rxd_dly;

// delay uart_rxd and detect a start negative edge
always @ (posedge bus.clk)
uart_rxd_dly <= uart_rxd;

assign rxd_start = uart_rxd_dly & ~uart_rxd & ~rxd_run;

// baudrate generator from clock (it counts down to 0 generating a baud pulse)
always @ (posedge bus.clk, posedge bus.rst)
if (rst)          rxd_bdr <= N_BIT-1;
else begin
  if (rxd_start)  rxd_bdr <= ((N_BIT-1)>>1)-1;
  else            rxd_bdr <= ~|rxd_bdr ? N_BIT-1 : rxd_bdr - rxd_run;
end

// enable signal for shifting logic
always @ (posedge bus.clk, posedge bus.rst)
if (rst)  rxd_ena <= 1'b0;
else      rxd_ena <= (rxd_bdr == 'd1);

// bit counter
always @ (posedge bus.clk, posedge bus.rst)
if (rst)             rxd_cnt <= 0;
else begin
  if (rxd_start)     rxd_cnt <= UTL;
  else if (rxd_ena)  rxd_cnt <= rxd_cnt - 1;
end

// shift status
always @ (posedge bus.clk, posedge bus.rst)
if (rst)             rxd_run <= 1'b0;
else begin
  if (rxd_start)     rxd_run <= 1'b1;
  else if (rxd_ena)  rxd_run <= rxd_cnt != 4'd0;
end

assign rxd_end = ~|rxd_cnt & rxd_ena;

// data shift register
always @ (posedge bus.clk)
if (rxd_ena)  rxd_dat <= {uart_rxd, rxd_dat[BYTESIZE-1:1]};

// avalon read data and parity error
always @ (posedge bus.clk)
if (rxd_end)  status_dat <= rxd_dat;

// fifo interrupt status
always @ (posedge bus.clk, posedge bus.rst)
if (rst)                 status_rdy <= 1'b0;
else begin
  if (rxd_end)           status_rdy <= 1'b1;
  else if (avalon_trn_r) status_rdy <= 1'b0;
end

// fifo overflow error
always @ (posedge bus.clk, posedge bus.rst)
if (rst)                 status_err <= 1'b0;
else begin
  if (avalon_trn_r)      status_err <= 1'b0;
  else if (rxd_end)      status_err <= status_rdy;
end

endmodule: tcb_uart