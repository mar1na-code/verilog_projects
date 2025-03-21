
// Paul Chow
// November 2021
//

// iColour is the colour for the box
//
// oX, oY, oColour and oPlot should be wired to the appropriate ports on the VGA controller
//

// Some constants are set as parameters to accommodate the different implementations
// X_SCREEN_PIXELS, Y_SCREEN_PIXELS are the dimensions of the screen
//       Default is 160 x 120, which is size for fake_fpga and baseline for the DE1_SoC vga controller
// CLOCKS_PER_SECOND should be the frequency of the clock being used.

//'include "drawBox.v" //so we have modules defined there

module moveBox(iColour, iResetn, iClock, moveNow, FINALDONE, counter, nextStep, stepsLeft, iX, iY, X_DIM, Y_DIM, oX, oY, oColour, oPlot, FrameCounter, oDone); 
   input wire [5:0] iColour;
   output wire [5:0] oColour;     // VGA pixel colour (0-7)
   input wire iResetn;
   input wire iClock;
   input [1:0] counter;
   input[7:0] stepsLeft;
   input nextStep;
   input wire [7:0] iX;
   input wire [6:0] iY;
   input wire [7:0] X_DIM, Y_DIM;
   input wire moveNow, FINALDONE;

   output wire [7:0] oX;         // VGA pixel coordinates
   output wire [6:0] oY;
   output wire 	     oPlot;       // Pixel drawn enable
   output wire oDone;

   wire set, erase, go, _wait;
   output wire[6:0] FrameCounter; //need to connect to our conectBox.v

   parameter
     X_BOXSIZE = 8'd4,   // Box X dimension
     Y_BOXSIZE = 7'd4,   // Box Y dimension
     X_SCREEN_PIXELS = 9,  // X screen width for starting resolution and fake_fpga
     Y_SCREEN_PIXELS = 7,  // Y screen height for starting resolution and fake_fpga
     CLOCKS_PER_SECOND = 5000, // 5 KHZ for fake_fpga
     X_MAX = X_SCREEN_PIXELS - 1 - X_BOXSIZE, // 0-based and account for box width
     Y_MAX = Y_SCREEN_PIXELS - 1 - Y_BOXSIZE,

     FRAMES_PER_UPDATE = 60,
     PULSES_PER_SIXTIETH_SECOND = CLOCKS_PER_SECOND / 60
	       ;

//instatiate
Control C_move(iResetn, iClock, oDone, counter, moveNow, nextStep, stepsLeft, FrameCounter, FINALDONE, set, erase, go, _wait);
Datapath D_move(iResetn, iClock, set, _wait, FrameCounter);
drawBox draw(go, erase, iClock, iResetn, iColour, iX, iY, X_DIM, Y_DIM, oX, oY, oColour, oPlot, oDone); //draw box, only activated when go is on (when drawing or clearing box)
endmodule
 
 module Control(iResetn, iClock, oDone, counter, moveNow, nextStep, stepsLeft, FrameCounter, FINALDONE, set, erase, go, _wait);
   input iResetn, iClock, oDone, moveNow, FINALDONE, nextStep;

   input [1:0] counter;
   input wire [6:0] FrameCounter;
   input wire [7:0] stepsLeft;

output reg set, erase, go, _wait;

reg [4:0] current_state, next_state;

   localparam 
		START=4'd0,	
		SET_UP=4'd1,
                DRAW = 4'd2,
                WAIT = 4'd3,
                CLEAR = 4'd4;
		 
	always@(*)
    begin: state_table
            case (current_state)
		START: next_state=SET_UP;
		SET_UP: begin
		if(FINALDONE==1)
		next_state=WAIT;
		else
		next_state = counter ? CLEAR : DRAW;
		end
		DRAW: begin
		next_state= oDone ? SET_UP : DRAW;
		end
		WAIT: next_state= (((nextStep==1'b1 || stepsLeft!=0) && counter==2'b1 && FrameCounter==0 )|| moveNow==1) ? SET_UP : WAIT; 
	 	CLEAR: next_state= oDone ? SET_UP : CLEAR;
	endcase
	end

	always @(*)
    begin: enable_signals
        // By default make all our signals 0
	set=0;
	_wait=0;
	erase=0;
	go=0;

  case (current_state)
	   SET_UP: set=1;
           DRAW: begin
		erase=0;
		go=1;
		end
	   WAIT: _wait=1;
	   CLEAR: begin
		erase=1;
		go=1;
		end	
       endcase

end // enable_signals


    // current_state registers
    always@(posedge iClock)
    begin: state_FFs
        if(!iResetn) //active low
            current_state <= START;
        else
            current_state <= next_state;
    end // state_FFS

endmodule // END OF CONTROL



module Datapath(iResetn, iClock, set, _wait, FrameCounter);

input iResetn, iClock, set, _wait; 

output reg [6:0] FrameCounter;


//need for counters
   parameter
     X_BOXSIZE = 8'd4,   // Box X dimension
     Y_BOXSIZE = 7'd4,   // Box Y dimension
     X_SCREEN_PIXELS = 9,  // X screen width for starting resolution and fake_fpga
     Y_SCREEN_PIXELS = 7,  // Y screen height for starting resolution and fake_fpga
     CLOCKS_PER_SECOND = 5000, // 5 KHZ for fake_fpga
     X_MAX = X_SCREEN_PIXELS - 1 - X_BOXSIZE, // 0-based and account for box width
     Y_MAX = Y_SCREEN_PIXELS - 1 - Y_BOXSIZE,
     STEP_SIZE=8'd2,

     FRAMES_PER_UPDATE = 7'd100,
     PULSES_PER_SIXTIETH_SECOND = CLOCKS_PER_SECOND / 60
	       ;

//our operations

always @ (posedge iClock)

begin

	if (set==1)
	begin
	FrameCounter<=FRAMES_PER_UPDATE;
	end
	//erase and go dictate what drawBox does.

	else if (_wait==1)
	begin
	//before we start clearing, get our original x and y back from connect box.
	FrameCounter=FrameCounter-1;
	end
end

endmodule
