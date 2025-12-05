
////////////////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Josh Sackos
//
// Create Date:    07/11/2012
// Module Name:    PmodJSTK
// Project Name: 	 PmodJSTK_Demo
// Target Devices: ICEStick
// Tool versions:  iCEcube2
// Description: This component consists of three subcomponents a 66.67kHz serial clock,
//					 an SPI controller and a SPI interface. The SPI interface component is
//					 responsible for sending and receiving a byte of data to and from the
//					 PmodJSTK when a request is made. The SPI controller component manages all
//					 data transfer requests, and manages the data bytes being sent to the PmodJSTK.
//
// Revision History:
// 						Revision 0.01 - File Created (Josh Sackos)
//							Revision 1.0 - Updated to send 5 bytes of data instead of just 1
////////////////////////////////////////////////////////////////////////////////////////////

// ==============================================================================
// 										  Define Module
// ==============================================================================
module PmodJSTK(
		CLK,
		RST,
		sndRec,
		DIN,
		MISO,
		SS,
		SCLK,
		MOSI,
		DOUT
		);

// ===========================================================================
// 										Port Declarations
// ===========================================================================
			input CLK;						// 100MHz onboard clock
			input RST;						// Reset
			input sndRec;					// Send receive, initializes data read/write
			input [39:0] DIN;				// Data that is to be sent to the slave
			input MISO;						// Master in slave out
			output SS;						// Slave select, active low
			output SCLK;					// Serial clock
			output MOSI;					// Master out slave in
			output [39:0] DOUT;			// All data read from the slave

// ===========================================================================
// 							  Parameters, Regsiters, and Wires
// ===========================================================================

			// Output wires and registers
			wire SS;
			wire SCLK;
			wire MOSI;
			wire [39:0] DOUT;

			wire getByte;									// Initiates a data byte transfer in SPI_Int
			wire [7:0] sndDataByte;						// Data to be sent to Slave
			wire [7:0] RxData;							// Output data from SPI_Int
			wire BUSY;										// Handshake from SPI_Int to SPI_Ctrl


			// 66.67kHz Clock Divider, period 15us
			wire iSCLK;										// Internal serial clock,
																// not directly output to slave,
																// controls state machine, etc.

// ===========================================================================
// 										Implementation
// ===========================================================================

			//-----------------------------------------------
			//  	  				SPI Controller
			//-----------------------------------------------
			spiCtrl SPI_Ctrl(
					.CLK(iSCLK),
					.RST(RST),
					.sndRec(sndRec),
					.BUSY(BUSY),
					.DIN(DIN),
					.RxData(RxData),
					.SS(SS),
					.getByte(getByte),
					.sndData(sndDataByte),
					.DOUT(DOUT)
			);

			//-----------------------------------------------
			//  	  				  SPI Mode 0
			//-----------------------------------------------
			spiMode0 SPI_Int(
					.CLK(iSCLK),
					.RST(RST),
					.sndRec(getByte),
					.DIN(sndDataByte),
					.MISO(MISO),
					.MOSI(MOSI),
					.SCLK(SCLK),
					.BUSY(BUSY),
					.DOUT(RxData)
			);

			//-----------------------------------------------
			//  	  				SPI Controller
			//-----------------------------------------------
			ClkDiv_66_67kHz SerialClock(
					.CLK(CLK),
					.RST(RST),
					.CLKOUT(iSCLK)
			);

endmodule

///////////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Josh Sackos
// 
// Create Date:    07/11/2012
// Module Name:    spiMode0
// Project Name: 	 PmodJSTK_Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.1
// Description: This module provides the interface for sending and receiving data
//					 to and from the PmodJSTK, SPI mode 0 is used for communication.  The
//					 master (Nexys3) reads the data on the MISO input on rising edges, the
//					 slave (PmodJSTK) reads the data on the MOSI output on rising edges.
//					 Output data to the slave is changed on falling edges, and input data
//					 from the slave changes on falling edges.
//
//					 To initialize a data transfer between the master and the slave simply
//					 assert the sndRec input.  While the data transfer is in progress the
//					 BUSY output is asserted to indicate to other componenets that a data
//					 transfer is in progress.  Data to send to the slave is input on the 
//					 DIN input, and data read from the slave is output on the DOUT output.
//
//					 Once a sndRec signal has been received a byte of data will be sent
//					 to the PmodJSTK, and a byte will be read from the PmodJSTK.  The
//					 data that is sent comes from the DIN input. Received data is output
//					 on the DOUT output.
//
// Revision History: 
// 						Revision 0.01 - File Created (Josh Sackos)
///////////////////////////////////////////////////////////////////////////////////////


// ==============================================================================
// 										  Define Module
// ==============================================================================
module spiMode0(
    CLK,
    RST,
    sndRec,
    DIN,
    MISO,
    MOSI,
    SCLK,
	 BUSY,
    DOUT
    );


	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================

			input CLK;						// 66.67kHz serial clock
			input RST;						// Reset
			input sndRec;					// Send receive, initializes data read/write
			input [7:0] DIN;				// Byte that is to be sent to the slave
			input MISO;						// Master input slave output
			output MOSI;					// Master out slave in
			output SCLK;					// Serial clock
			output BUSY;					// Busy if sending/receiving data
			output [7:0] DOUT;			// Current data byte read from the slave

	// ===========================================================================
	// 							  Parameters, Regsiters, and Wires
	// ===========================================================================
			wire MOSI;
			wire SCLK;
			wire [7:0] DOUT;
			reg BUSY;

			// FSM States
			parameter [1:0] Idle = 2'd0,
								 Init = 2'd1,
								 RxTx = 2'd2,
								 Done = 2'd3;

			reg [4:0] bitCount;							// Number bits read/written
			reg [7:0] rSR = 8'h00;						// Read shift register
			reg [7:0] wSR = 8'h00;						// Write shift register
			reg [1:0] pState = Idle;					// Present state

			reg CE = 0;										// Clock enable, controls serial
																// clock signal sent to slave
	
	 
	// ===========================================================================
	// 										Implementation
	// ===========================================================================

			// Serial clock output, allow if clock enable asserted
			assign SCLK = (CE == 1'b1) ? CLK : 1'b0;
			// Master out slave in, value always stored in MSB of write shift register
			assign MOSI = wSR[7];
			// Connect data output bus to read shift register
			assign DOUT = rSR;
	
			//-------------------------------------
			//			 Write Shift Register
			// 	slave reads on rising edges,
			// change output data on falling edges
			//-------------------------------------
			always @(negedge CLK) begin
					if(RST == 1'b1) begin
							wSR <= 8'h00;
					end
					else begin
							// Enable shift during RxTx state only
							case(pState)
									Idle : begin
											wSR <= DIN;
									end
									
									Init : begin
											wSR <= wSR;
									end
									
									RxTx : begin
											if(CE == 1'b1) begin
													wSR <= {wSR[6:0], 1'b0};
											end
									end
									
									Done : begin
											wSR <= wSR;
									end
							endcase
					end
			end




			//-------------------------------------
			//			 Read Shift Register
			// 	master reads on rising edges,
			// slave changes data on falling edges
			//-------------------------------------
			always @(posedge CLK) begin
					if(RST == 1'b1) begin
							rSR <= 8'h00;
					end
					else begin
							// Enable shift during RxTx state only
							case(pState)
									Idle : begin
											rSR <= rSR;
									end
									
									Init : begin
											rSR <= rSR;
									end
									
									RxTx : begin
											if(CE == 1'b1) begin
													rSR <= {rSR[6:0], MISO};
											end
									end
									
									Done : begin
											rSR <= rSR;
									end
							endcase
					end
			end



			
			//------------------------------
			//		   SPI Mode 0 FSM
			//------------------------------
			always @(negedge CLK) begin
			
					// Reset button pressed
					if(RST == 1'b1) begin
							CE <= 1'b0;				// Disable serial clock
							BUSY <= 1'b0;			// Not busy in Idle state
							bitCount <= 4'h0;		// Clear #bits read/written
							pState <= Idle;		// Go back to Idle state
					end
					else begin
							
							case (pState)
							
								// Idle
								Idle : begin

										CE <= 1'b0;				// Disable serial clock
										BUSY <= 1'b0;			// Not busy in Idle state
										bitCount <= 4'd0;		// Clear #bits read/written
										

										// When send receive signal received begin data transmission
										if(sndRec == 1'b1) begin
											pState <= Init;
										end
										else begin
											pState <= Idle;
										end
										
								end

								// Init
								Init : begin
								
										BUSY <= 1'b1;			// Output a busy signal
										bitCount <= 4'h0;		// Have not read/written anything yet
										CE <= 1'b0;				// Disable serial clock
										
										pState <= RxTx;		// Next state receive transmit
										
								end

								// RxTx
								RxTx : begin

										BUSY <= 1'b1;						// Output busy signal
										bitCount <= bitCount + 1'b1;	// Begin counting bits received/written
										
										// Have written all bits to slave so prevent another falling edge
										if(bitCount >= 4'd8) begin
												CE <= 1'b0;
										end
										// Have not written all data, normal operation
										else begin
												CE <= 1'b1;
										end
										
										// Read last bit so data transmission is finished
										if(bitCount == 4'd8) begin
												pState <= Done;
										end
										// Data transmission is not finished
										else begin
												pState <= RxTx;
										end

								end

								// Done
								Done : begin

										CE <= 1'b0;			// Disable serial clock
										BUSY <= 1'b1;		// Still busy
										bitCount <= 4'd0;	// Clear #bits read/written
										
										pState <= Idle;

								end

								// Default State
								default : pState <= Idle;
								
							endcase
					end
			end

endmodule

////////////////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Josh Sackos
//
// Create Date:    07/11/2012
// Module Name:    spiCtrl
// Project Name: 	 PmodJSTK_Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.1
// Description: This component manages all data transfer requests,
//					 and manages the data bytes being sent to the PmodJSTK.
//
//  				 For more information on the contents of the bytes being sent/received
//					 see page 2 in the PmodJSTK reference manual found at the link provided
//					 below.
//
//
// Revision History:
// 						Revision 0.01 - File Created (Josh Sackos)
//						Revision 1.00 - Updated to transmit 5 bytes instead of 1 byte
////////////////////////////////////////////////////////////////////////////////////////////

// ==============================================================================
// 										  Define Module
// ==============================================================================
module spiCtrl(
		CLK,
		RST,
		sndRec,
		BUSY,
		DIN,
		RxData,
		SS,
		getByte,
		sndData,
		DOUT
		);

	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================

			input CLK;						// 66.67kHz onboard clock
			input RST;						// Reset
			input sndRec;					// Send receive, initializes data read/write
			input BUSY;						// If active data transfer currently in progress
			input [39:0] DIN;				// Data that is to be sent to the slave
			input [7:0] RxData;			// Last data byte received
			output SS;						// Slave select, active low
			output getByte;				// Initiates a data transfer in SPI_Int
			output [7:0] sndData;		// Data that is to be sent to the slave
			output [39:0] DOUT;			// All data read from the slave

	// ===========================================================================
	// 							  Parameters, Regsiters, and Wires
	// ===========================================================================

			// Output wires and registers
			reg SS = 1'b1;
			reg getByte = 1'b0;
			reg [7:0] sndData = 8'h00;
			reg [39:0] DOUT = 40'h0000000000;

			// FSM States
			parameter [2:0] Idle = 3'd0,
								 Init = 3'd1,
								 Wait = 3'd2,
								 Check = 3'd3,
								 Done = 3'd4;

			// Present State
			reg [2:0] pState = Idle;

			reg [2:0] byteCnt = 3'd0;					// Number bytes read/written
			parameter byteEndVal = 3'd5;				// Number of bytes to send/receive
			reg [39:0] tmpSR = 40'h0000000000;			// Temporary shift register to
															// accumulate all five received data bytes
			reg [39:0] tmpSRsend = 40'h0000000000;		// Temporary shift register to
															// shift through all five send data bytes

	// ===========================================================================
	// 										Implementation
	// ===========================================================================

	always @(negedge CLK) begin
			if(RST == 1'b1) begin
					// Reest everything
					SS <= 1'b1;
					getByte <= 1'b0;
					sndData <= 8'h00;
					tmpSRsend <= 40'h0000000000;
					tmpSR <= 40'h0000000000;
					DOUT <= 40'h0000000000;
					byteCnt <= 3'd0;
					pState <= Idle;
			end
			else begin

					case(pState)

								// Idle
								Idle : begin

										SS <= 1'b1;								// Disable slave
										getByte <= 1'b0;						// Do not request data
										sndData <= 8'h00;						// Clear data to be sent
										tmpSRsend <= DIN;						// Send temporary data
										tmpSR <= 40'h0000000000;				// Clear temporary data
										DOUT <= DOUT;							// Retain output data
										byteCnt <= 3'd0;						// Clear byte count

										// When send receive signal received begin data transmission
										if(sndRec == 1'b1) begin
											pState <= Init;
										end
										else begin
											pState <= Idle;
										end

								end

								// Init
								Init : begin

										SS <= 1'b0;								// Enable slave
										getByte <= 1'b1;						// Initialize data transfer
										sndData <= tmpSRsend[39:32];			// Store data byte to be sent
										tmpSRsend <= tmpSRsend;					// Retain temporary send data
										tmpSR <= tmpSR;							// Retain temporary data
										DOUT <= DOUT;							// Retain output data

										if(BUSY == 1'b1) begin
												pState <= Wait;
												byteCnt <= byteCnt + 1;	// Count
										end
										else begin
												pState <= Init;
										end

								end

								// Wait
								Wait : begin

										SS <= 1'b0;								// Enable slave
										getByte <= 1'b0;						// Data request already in progress
										sndData <= sndData;						// Retain data to send
										tmpSRsend <= tmpSRsend;					// Retain temporary send data
										tmpSR <= tmpSR;							// Retain temporary data
										DOUT <= DOUT;							// Retain output data
										byteCnt <= byteCnt;						// Do not count

										// Finished reading byte so grab data
										if(BUSY == 1'b0) begin
												pState <= Check;
										end
										// Data transmission is not finished
										else begin
												pState <= Wait;
										end

								end

								// Check
								Check : begin

										SS <= 1'b0;								// Enable slave
										getByte <= 1'b0;						// Do not request data
										sndData <= sndData;						// Retain data to send
										tmpSRsend <= {tmpSRsend[31:0], 8'h00}; // Shift send data
										tmpSR <= {tmpSR[31:0], RxData};			// Store byte just read
										DOUT <= DOUT;							// Retain output data
										byteCnt <= byteCnt;						// Do not count

										// Finished reading bytes so done
										if(byteCnt == 3'd5) begin
												pState <= Done;
										end
										// Have not sent/received enough bytes
										else begin
												pState <= Init;
										end
								end

								// Done
								Done : begin

										SS <= 1'b1;							// Disable slave
										getByte <= 1'b0;					// Do not request data
										sndData <= 8'h00;					// Clear input
										DOUT[39:0] <= tmpSR[39:0];			// Update output data
										byteCnt <= byteCnt;					// Do not count

										// Wait for external sndRec signal to be de-asserted
										if(sndRec == 1'b0) begin
												pState <= Idle;
										end
										else begin
												pState <= Done;
										end

								end

								// Default State
								default : pState <= Idle;
						endcase
			end
	end

endmodule

//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ryan
//
// Create Date:		05/23/2017
// Module Name:		ClkDiv_66_67kHz
// Project Name:	Joystick_Controller
// Target Devices:	ICEStick
// Tool versions:	iCEcube2
// Description: Converts input 12 MHz clock signal to a 66.67kHz clock signal for serial comm
//////////////////////////////////////////////////////////////////////////////////

// ==============================================================================
// 										  Define Module
// ==============================================================================
module ClkDiv_66_67kHz(
    CLK,										// 12MHz onbaord clock
    RST,										// Reset
    CLKOUT									// New clock output
    );

// ===========================================================================
// 										Port Declarations
// ===========================================================================
	input CLK;
	input RST;
	output CLKOUT;

// ===========================================================================
// 							  Parameters, Regsiters, and Wires
// ===========================================================================

	// Output register
	reg CLKOUT = 1'b1;

	// Value to toggle output clock at
	parameter cntEndVal = 7'b1011010;
	// Current count
	reg [6:0] clkCount = 7'b0000000;

// ===========================================================================
// 										Implementation
// ===========================================================================

	//----------------------------------------------
	// 66.67kHz Clock Divider, period 15us, for serial clock timing
	//----------------------------------------------
	always @(posedge CLK) begin

			// Reset clock
			if(RST == 1'b1) begin
					CLKOUT <= 1'b0;
					clkCount <= 0;
			end
			// Count/toggle normally
			else begin

					if(clkCount == cntEndVal) begin
							CLKOUT <= ~CLKOUT;
							clkCount <= 0;
					end
					else begin
							clkCount <= clkCount + 1'b1;
					end

			end

	end

endmodule

//////////////////////////////////////////////////////////////////////////////////
// Engineer: Ryan
//
// Create Date:		06/07/2017
// Module Name:		ClkDiv_20Hz
// Project Name:	Joystick_Controller
// Target Devices:	ICEStick
// Tool versions:	iCEcube2
// Description: Converts input 12 MHz clock signal to a 20Hz "update system" clock signal
//////////////////////////////////////////////////////////////////////////////////

// ==============================================================================
// 										  Define Module
// ==============================================================================
module ClkDiv_20Hz(
    CLK,										// 12MHz onbaord clock
    RST,										// Reset
    CLKOUT,									// New clock output
    CLKOUTn
    );

// ===========================================================================
// 										Port Declarations
// ===========================================================================
	input CLK;
	input RST;
	output CLKOUT;
	output CLKOUTn;

// ===========================================================================
// 							  Parameters, Regsiters, and Wires
// ===========================================================================

	// Output register
	reg CLKOUT = 1'b1;

	// Value to toggle output clock at
	parameter cntEndVal = 19'h493E0;
	// Current count
	reg [18:0] clkCount = 19'h00000;

// ===========================================================================
// 										Implementation
// ===========================================================================
    
    assign CLKOUTn = ~CLKOUT;
    
	//-------------------------------------------------
	// 20Hz Clock Divider Generates timing to initiate Send/Receive
	//-------------------------------------------------
	always @(posedge CLK) begin

			// Reset clock
			if(RST == 1'b1) begin
					CLKOUT <= 1'b0;
					clkCount <= 0;
			end
			// Count/toggle normally
			else begin

					if(clkCount == cntEndVal) begin
							CLKOUT <= ~CLKOUT;
							clkCount <= 0;
					end
					else begin
							clkCount <= clkCount + 1'b1;
					end

			end

	end

endmodule