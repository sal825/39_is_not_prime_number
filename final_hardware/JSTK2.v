`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Josh Sackos
// Modified by: <you>
// 
// Description:
// Modified version of PmodJSTK to support external SS control
// for single SPI master, multi-slave (time-multiplexed) operation.
//
////////////////////////////////////////////////////////////////////////////////////////////

module PmodJSTK(
    CLK,
    RST,
    sndRec,
    DIN,
    MISO,
    SS,        // <<< 外部控制的 Slave Select
    SCLK,
    MOSI,
    DOUT
);

// ===========================================================================
// Port Declarations
// ===========================================================================
input        CLK;        // 100MHz clock
input        RST;
input        sndRec;     // trigger send/receive
input  [7:0] DIN;        // data to send
input        MISO;       // from slave
input        SS;         // <<< SS 由 top module 控制（active low）

output       SCLK;       // SPI clock
output       MOSI;       // SPI MOSI
output [39:0] DOUT;      // received data

// ===========================================================================
// Internal Wires
// ===========================================================================
wire        getByte;
wire [7:0]  sndData;
wire [7:0]  RxData;
wire        BUSY;

wire        iSCLK;       // internal 66.67kHz clock

// ===========================================================================
// SPI Controller (NO LONGER DRIVES SS)
// ===========================================================================
spiCtrl SPI_Ctrl(
    .CLK(iSCLK),
    .RST(RST),
    .sndRec(sndRec),
    .BUSY(BUSY),
    .DIN(DIN),
    .RxData(RxData),
    .getByte(getByte),
    .sndData(sndData),
    .DOUT(DOUT)
);

// ===========================================================================
// SPI Mode 0 Engine
// ===========================================================================
spiMode0 SPI_Int(
    .CLK(iSCLK),
    .RST(RST),
    .sndRec(getByte),
    .DIN(sndData),
    .MISO(MISO),
    .MOSI(MOSI),
    .SCLK(SCLK),
    .BUSY(BUSY),
    .DOUT(RxData)
);

// ===========================================================================
// 66.67kHz Clock Divider
// ===========================================================================
ClkDiv_66_67kHz SerialClock(
    .CLK(CLK),
    .RST(RST),
    .CLKOUT(iSCLK)
);

endmodule
