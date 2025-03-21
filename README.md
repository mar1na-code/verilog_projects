# verilog_projects

The code on here includes the work I've done for my Digital Systems Course's final project. 

The Animation folder includes 3 modules, which when run together, has 3 interconnected FSMs that facilitate the animation of a character: it operates by drawing the character, incrementing the position of the upper left corner of the character based on the user input, and erasing only where character was previously, and redrawing. 

To debug, I used ModelSim, and only once I got the flags I was expecting with each clock cycle, I used Quartus to implement it on a DE1-SoC board.

To run these modules, you need to include a number of files to deal with the dependencies of connecting to + drawing on a VGA.
