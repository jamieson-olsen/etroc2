# ETROC2 readout logic

This design consists of 256 "pixel" inputs which accept TDC data supplied by the testbench. It is fully synchronous and automatically handles multiple back-to-back L1ACCEPTs.

## Pixel Modules

The pixel module contains a dual port RAM circular buffer. TDC data is written into this RAM on every BX. When a L1ACCEPT occurs the pixel modules "jump back" in time and fetch the TDC data for the target event from the RAM buffer. All pixel modules push the data into to a tree of merge cells, which merge data into a single stream.

## Merge Modules

The merge cell has two inputs and one output. Each input feeds into a shallow FIFO. A small state machine looks at the FIFO flags and outputs and determines which FIFO drives the output on each clock cycle. For example, if FIFO A has data and FIFO B does not, FIFO A is read and pushed to the output, which feeds into the next "tier" of merge cells.

If both FIFOs have data the selection logic looks at the BCID value and chooses the "older" TDC data. In this way multiple, consecutive events maybe present and will be sorted out automatically. The output of the last merge cell is zero suppressed.

## Testbench File

The testbench creates a 1-D array of 256 pixel modules, followed by the tree of merge modules. The number of merge modules is 255 (128 + 64 + 32 + 16 + 8 + 4 + 2 + 1). The user supplies fake TDC data to these pixel cells in the testbench. This firmware is written in a generic plain-old-vanilla VHDL for maximum portability.





