//draws our entire character...
//`include "moveBox.v"

//REQUIRED INPUTS: nextStep (do we move forward?); up, down, left, right

module conectBox(iResetn, iClock, nextStep, up, down, left, right, oX, oY, oColour, oPlot);
parameter CHARACTER_WIDTH=7'd12;

input iResetn, iClock, nextStep, up, down, left, right;

output oPlot;
output wire [7:0] oX;
output wire [6:0] oY;
output wire [5:0] oColour; //DO WE WANT TO USE MORE OF THE TOGGLE OPTIONS FOR COLOUR??

wire oDone, body, face, Leye, Reye, moveNow, FINALDONE;
wire [7:0]  iX;
wire [6:0]  iY;
wire [6:0] FrameCounter;
wire [7:0] stepsLeft;
wire [5:0] iColour;
wire [1:0] counter;
wire [7:0] X_DIM, Y_DIM;

cData cdata(iResetn, iClock, start, body, face, Leye, Reye, FINALDONE ,increm, up, down, left, right, iX, iY, X_DIM, Y_DIM, iColour, counter, stepsLeft, moveNow);
cControl ccontrol(iResetn, iClock, nextStep, oDone, counter, FrameCounter, stepsLeft, start, body, face, Leye, Reye, FINALDONE, increm);
moveBox move(iColour, iResetn, iClock, moveNow, FINALDONE, counter, nextStep, stepsLeft, iX, iY, X_DIM, Y_DIM, oX, oY, oColour, oPlot, FrameCounter, oDone); 
endmodule

module cControl(iResetn, iClock, nextStep, oDone, counter, FrameCounter, stepsLeft, start, body, face, Leye, Reye, FINALDONE, increm);
input iResetn, iClock, nextStep, oDone;
input [1:0] counter;
input [6:0] FrameCounter;
input [7:0] stepsLeft;
output reg start, body, face, Leye, Reye, FINALDONE, increm;
reg [4:0] current_state, next_state;

localparam 
		START=5'd0,
		loadBODY=5'd1,
		BODY=5'd2,
		loadFACE=5'd3,
                FACE = 5'd4,
		loadL_EYE=5'd5,
                L_EYE = 5'd6,
		loadR_EYE=5'd7,
                R_EYE = 5'd8, 
                WAIT =5'd9,
		INCREM=5'd10;
		
	always@(*)
    begin: state_table
            case (current_state)
		START: next_state=loadBODY;
		loadBODY: next_state=BODY;
		BODY: next_state=oDone ? loadFACE : BODY;
		loadFACE: next_state=FACE;
		FACE: next_state=oDone ? loadL_EYE : FACE;
		loadL_EYE: next_state=L_EYE;
		L_EYE: next_state=oDone ? loadR_EYE : L_EYE;
		loadR_EYE: next_state=R_EYE;
	 	R_EYE: next_state=oDone ? WAIT : R_EYE;
		WAIT: begin 
		if((nextStep==1'b1 || stepsLeft!=1'b0) && counter==2'b1)
		next_state= FrameCounter==0 ? loadBODY : WAIT ;
		else
		next_state=counter? WAIT: INCREM;
		end
		INCREM: next_state=loadBODY;
	endcase
	end

	always @(*)
    begin: enable_signals
        // By default make all our signals 0
	start=1'b0;
	body=1'b0;
	face=1'b0; 
	Leye=1'b0;
	Reye=1'b0; 
	FINALDONE=1'b0;
	increm=1'b0;

  case (current_state)
	   START: start=1'b1;
	   loadBODY: begin
                body=1'b1;
                end
           loadFACE: begin
		face=1'b1;
		end
	   loadL_EYE: begin
		Leye=1'b1;
		end
	   loadR_EYE: begin
		Reye=1'b1; 
		end	
	WAIT: begin
		FINALDONE=1'b1;  
		end
	INCREM: begin
		increm=1'b1;
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


endmodule

module cData(iResetn, iClock, start, body, face, Leye, Reye, FINALDONE ,increm, up, down, left, right, iX, iY, X_DIM, Y_DIM, iColour, counter, stepsLeft, moveNow); //gives us position of face, we return depending on what we are drawing...
parameter CHARACTER_WIDTH=7'd12,
	  START_X=8'd20,
	  START_Y=7'd20,
	  STEP_SIZE=8'd2;

input iResetn, iClock, start, body, face, Leye, Reye, FINALDONE ,increm, up, down, left, right;

output reg [7:0] iX;
output reg [6:0] iY;
output reg [5:0] iColour;
output reg [1:0] counter;
output reg [7:0] stepsLeft;
output reg moveNow;
output reg [7:0] X_DIM, Y_DIM;

reg [7:0] ix;
reg [6:0] iy;

always @ (posedge iClock)
begin

if(start==1)
begin
ix<=START_X;
iy<=START_Y;
counter<=2'b0;
stepsLeft<=0;
moveNow=0;
end

else if(body==1)
begin
begin
iX=ix+CHARACTER_WIDTH/2'd3; //position relative to face.
iY=iy+CHARACTER_WIDTH-1;
iColour=6'b101011;
X_DIM=CHARACTER_WIDTH/2'd3;
Y_DIM=CHARACTER_WIDTH;
end

begin
if(stepsLeft==0 && counter==1)
stepsLeft<=STEP_SIZE;
end
moveNow<=0;

end

else if(face==1)
begin
iX<=ix;
iY<=iy;
iColour=6'b111100;
X_DIM=CHARACTER_WIDTH;
Y_DIM=CHARACTER_WIDTH-2;
end

else if (Leye==1)
begin
iX<=ix+CHARACTER_WIDTH/5;
iY<=iy+CHARACTER_WIDTH/4;
iColour<=6'b111111;
X_DIM=CHARACTER_WIDTH/3'd5;
Y_DIM=CHARACTER_WIDTH/3'd5;
end

else if (Reye==1)
begin
iX<=ix+CHARACTER_WIDTH*3/5;
iY<=iy+CHARACTER_WIDTH/4;
iColour=6'b111111;
X_DIM=CHARACTER_WIDTH/3'd5;
Y_DIM=CHARACTER_WIDTH/3'd5;

begin 
if(counter==1)
stepsLeft=stepsLeft-1;
else //counter==0
counter=2'd2;
end

counter=counter-1; //MUST BE BLOCKING STATEMENT
end

else if (increm==1)
begin
moveNow<=1;
begin
if(up==1)
iy<=iy-3;
else if(down==1)
iy<=iy+3;
else if(right==1)
ix<=ix+3;
else if(left==1)
ix<=ix-3;
end
end

end

endmodule 
