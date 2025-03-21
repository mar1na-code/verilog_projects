 
//
// Paul Chow
// November 2021
//

module drawBox(go, erase, iClock, iResetn, iColour, iX, iY, X_DIM, Y_DIM, oX, oY, oColour, oPlot, oDone);
   parameter X_SCREEN_PIXELS = 10'd640;
   parameter Y_SCREEN_PIXELS = 9'd480;

   input wire go, iResetn, erase, iClock;
   input wire [5:0] iColour;
   input wire [7:0] X_DIM, Y_DIM;
   input wire [7:0] iX;
   input wire [6:0] iY;

   output wire [7:0] oX;         // VGA pixel coordinates
   output wire [6:0] oY;

   output wire [5:0] oColour;     // VGA pixel colour (0-7)
   output wire 	     oPlot;       // Pixel draw enable
   output wire       oDone;       // goes high when finished drawing frame

   wire ld_count, ld_xyc, ld_draw;
   //wire enable; //adjusted clock.

  control c(go, iClock, iResetn, oDone,ld_count,ld_xyc,ld_draw);
  datapath d(iClock, iResetn, erase, iColour, iX, iY, X_DIM, Y_DIM ,ld_count, ld_xyc, ld_draw, oX, oY, oColour, oPlot, oDone);

endmodule
 


module control(go, iClock, iResetn, oDone,ld_count,ld_xyc,ld_draw);

input go, iClock, iResetn, oDone;
output reg ld_count, ld_xyc, ld_draw;

reg [5:0] current_state, next_state;

   localparam   
		START           =4'd1, 
		ACCEPT        = 4'd2,
                DRAW   = 4'd3;
		
		//S_CYCLE_0 = 5'd5,
		//S_CYCLE_1 = 5'd6;

  always@(*)
    begin: state_table
            case (current_state)
		START: next_state = go ? ACCEPT : START;
		ACCEPT: next_state = DRAW;
		DRAW: next_state = oDone ? START : DRAW; //WHY IS ODONE TAKING SO LONG TO DO ITS JOB AND GOT TO START?? ~3 CLOCK CYCLES/ 3POSEDGE

        endcase
    	end // state_table

	always @(*)
    	begin: enable_signals
        // By default make all our signals 0
       ld_count=1'b0;
       ld_xyc = 1'b0;
       ld_draw = 1'b0;

  case (current_state)
	    START: ld_count=1'b1;
            ACCEPT: ld_xyc = 1'b1;
            DRAW: ld_draw = 1'b1;
       endcase

end // enable_signals


    // current_state registers
    always@(posedge iClock)
    begin: state_FFs
        if(!iResetn)
            current_state <= START;
        else
            current_state <= next_state;
    end // state_FFS

endmodule // END OF CONTROL

module datapath(iClock, iResetn, erase, iColour, iX, iY, X_DIM, Y_DIM ,ld_count, ld_xyc, ld_draw, oX, oY, oColour, oPlot, oDone);
   input iClock, iResetn, erase, ld_count, ld_xyc, ld_draw;
input[7:0] X_DIM, Y_DIM ;
   parameter X_SCREEN_PIXELS = 8'd160, 
             Y_SCREEN_PIXELS = 7'd120;

   input [5:0] iColour;
   input [7:0] iX;
   input [6:0] iY;

    output reg [7:0] oX;        
    output reg [6:0] oY;
    reg [7:0] oX1;         // initial oX and oY
    reg [6:0] oY1;
    output reg oDone; 
    reg [7:0] xDim, yDim; //Screen dimensions: 4x4 for draw; entire screen for clear
    output reg [5:0] oColour;  
    output oPlot; 
    reg [5:0] xcounter, ycounter;

assign oPlot= ld_draw;

//count and relase new oX and Oy with every clock cycle.
	always @ (posedge iClock) 
	begin

	oDone<=(xcounter==(xDim) && ycounter==(yDim) &&(ld_draw) );

		if(ld_count)
		begin
		xcounter<=0;
		ycounter<=1;
		end

  		else if(ld_xyc)
		begin
		oX1<= iX;
		oX<= iX;
		oY<= iY;
		oY1<= iY;
	        oColour <= (erase ? 6'b111111 : iColour); //background is white.
		xDim <=X_DIM; //Can change size of box as wanted.
		yDim <=Y_DIM;
		end
	else if(xcounter<=(xDim-1) && ycounter<=(yDim)&&(ld_draw) )
	begin
	oX=oX1+xcounter;
	xcounter=xcounter+1;
	end
	
	else if (xcounter>(xDim-1) && ycounter<=(yDim-1) && (ld_draw))
	begin
	oX=oX1;
	oY=oY1+ycounter;
	ycounter=ycounter+1;
	xcounter<=1;
	end


	end

	endmodule
