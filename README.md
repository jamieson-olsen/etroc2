# ETROC2 readout logic

This design consists of 256 "pixel" inputs which accept TDC data supplied by the testbench. It is fully synchronous and automatically handles multiple back-to-back L1ACCEPTs.

## Pixel Modules

The pixel module contains a dual port RAM circular buffer. TDC data is written into this RAM on every BX. When a L1ACCEPT occurs all pixel modules "jump back" in time and fetch the TDC data for the target event from the RAM buffer. As the data leaves the Pixel Module it is tagged with the ROW and COL location in the 16x16 array. It is also tagged with an event number, which is used by the merge cell to resolve which hit should be selected. This event number increments with each L1accept, and if there have not been any L1accepts in some time it is reset to zero.

## Merge Modules

The merge cell has two inputs and one output. Each input feeds into a shallow FIFO. A small state machine looks at the FIFO flags and outputs and determines which FIFO drives the output on each clock cycle. For example, if FIFO A has data and FIFO B does not, FIFO A is read and pushed to the output, which feeds into the next "tier" of merge cells.

If both FIFOs have data the selection logic looks at the event number and chooses the "older" hit. In this way multiple, consecutive events maybe present and will be sorted out automatically. The output of the last merge cell is zero suppressed.

## Testbench File

The testbench creates a 2-D array of 16x16 (256) pixel modules, followed by the tree of merge modules. The number of merge modules is 255 (128 + 64 + 32 + 16 + 8 + 4 + 2 + 1). The user supplies TDC data to these pixel cells in the testbench. This firmware is written in a generic plain-old-vanilla VHDL for maximum portability.

Datao's input vector file "MCburstxx.dat" format:

BC L1A Pix(0,0) Pix(1,0) ... Pix(14,15) Pix(15,15) 

where each pixel value Pix(Row,Col) is a 32-bit unsigned int with bits defined as:

bit 31 = 0
bit 30 = 0
bit 29 = valid
bits 28..19 = toa(9..0)
bits 18..10 = tot(8..0)
bits 9..0 = cal(9..0)







