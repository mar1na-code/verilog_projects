vlib work

# compile all verilog modules in mux.v to working dir
# could also have multiple verilog files , other files FIRST
#file with topLevel Module
vlog conectBox.v

#load simulation using mux as the top level simulation module
#vsim -L altera_mf_ver vga_adapter
vsim conectBox

#log all signals and add some signals to waveform window
log {/*}
# add wave {/*} would add all items in top level simulation module
add wave {/*}

add wave -position insertpoint  \
sim:/conectBox/ccontrol/current_state

add wave -position insertpoint  \
sim:/conectBox/move/C_move/current_state

#iResetn, iClock, nextStep, up, down, left, right, oX, oY, oColour, oPlot
# first test case
#set input values using the force command, signal names need to be in {} brackets
force {iClock} 0 0ns, 1 5ns -repeat 10ns

force {iResetn} 0
force {nextStep} 1
force {up} 0
force {down} 0
force {left} 0
force {right} 0
run 10ns

force {iResetn} 1
force {nextStep} 1
force {up} 0
force {down} 0
force {left} 0
force {right} 1
run 1.2ms
