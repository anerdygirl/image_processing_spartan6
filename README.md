# image_processing_spartan6

For my summer internship project, I designed and implemented a pure-VHDL image-processing pipeline (grayscale conversion, Sobel edge detection, 3×3 median filtering, and passthrough) implemented on a Digilent Nexys 3 / Xilinx Spartan-6 XC6SLX16 FPGA, with UART transmission to a Python host-side visualizer.

## Inspiration

Adapted from a reference design that used a CMOS camera module and a MicroBlaze soft processor, but neither of which were available for this project. This implementation substitutes a preloaded ROM test image for live capture, and a pure VHDL finite-state-machine architecture for the soft processor.

![Four side-by-side image-processing results of two white lilies among green foliage and yellow flowers: the top-left panel is titled Received frame (passthrough) and shows the original color image, the top-right is titled Received frame (grayscale) and shows the scene in gray tones, the bottom-left is titled Received frame (sobel) and shows high-contrast edges, and the bottom-right is titled Received frame (median) and shows a smoothed grayscale version. The panels document the same floral scene under four processing modes, with no people present.](<docs/additional results/lily_results.png>)
Grayscale, Sobel edge detection, median filtering, and passthrough — all four modes, real hardware output.

**source image:**
![source image: lily flower](<docs/additional results/lily.jpg>)

## Architecture

Six VHDL modules, orchestrated by a central Moore-machine controller:

```text
img_rom → processing_top1 → frame_out → TX → UART → PC (receive_frame.py)
                ↑
            ctrl_fsm (orchestrates process_en / tx_en handshakes)
```

| Module               | Role                                                                        |
| -------------------- | --------------------------------------------------------------------------- |
| `ctrl_fsm`           | Top-level sequencer (`INIT → PROCESS_FRAME → WAIT_FLUSH → TRANSMIT → loop`) |
| `img_rom`            | Preloaded test image, Block Memory Generator ROM, 16-bit × 4800 (80×60)     |
| `processing_top1`    | Compute core — grayscale / Sobel / median / passthrough, runtime-selectable |
| `frame_out`          | Output buffer, Block Memory Generator RAM                                   |
| `TX` / `uart_tx_clk` | UART frame sequencer + byte-level transmitter (115200 baud)                 |

## Repository structure

```text
├── *.vhd                   # VHDL sources
├── *_test.vhd / *_tb.vhd   # Testbenches
├── ipcore_dir/             # Xilinx Core Generator IP (Block Memory
                              Generator cores)
├── Nexys3.ucf              # Nexys 3 pin constraints
└── docs/                   # Diagrams, result screenshots, Python scripts
                              for visualization and ROM initiation.
```

## Hardware / software requirements

- Digilent Nexys 3 board (Spartan-6 XC6SLX16-CSG324)
- Xilinx ISE Design Suite 14.7 (WebPACK edition)
- Python 3 with `pyserial`, `numpy`, `matplotlib`

## Building and running

**1. Preload a test image into ROM:**

```bash
python3 image_to_coe.py your_image.jpg test.coe --width 80 --height 60
```

Load `test.coe` via the `img_rom` core's "Load Init File" option in Core Generator before synthesis.

**2. Simulate (optional but recommended):**

```bash
vhpcomp -work work pixel_pkg.vhd
vhpcomp -work work ipcore_dir/img_rom/img_rom.vhd
vhpcomp -work work ipcore_dir/frame_out/frame_out.vhd
vhpcomp -work work uart_tx_clk.vhd ctrl_fsm.vhd processing_top1.vhd TX.vhd top_level.vhd
vhpcomp -work work top_level_test.vhd
fuse -o sim work.top_level_test -mt off
./sim
```

> **Note:** ISim's `fuse` step requires GCC ≤ 13 (modern GCC 14+ breaks on implicit-declaration errors in ISim's generated C code). Use `update-alternatives` to temporarily switch compilers if needed.

**3. Synthesize, implement, and generate the bitstream** in ISE with `top_level` as the top module and `top_level.ucf` as constraints.

**4. Program the board**, then run the receiver:

```bash
python3 receive_frame.py --port /dev/ttyUSB0 --mode grayscale
#check your FPGA's USB port first
```

`--mode` must match whatever the DIP switches are set to on the board (`00`=grayscale, `01`=Sobel, `10`=median, `11`=passthrough).

## Known limitations

- **Single frame per reset.** A timing race between the processing and transmission stages over a shared output buffer causes image tearing under continuous, unattended looping. Root cause is understood (see report, §Discussion) and mitigated with a permanent single-frame gate — each capture requires pressing the board's reset button before running the receiver script. A full fix (double-buffering) is identified as future work.
- Resolution fixed at 80×60 due to the target device's on-chip memory budget (32 × 18Kb Block RAM blocks).
- Linux driver incompatibility: use `djtcgfg` command-line for programming the board

```bash
djtgcfg prog -d Nexys3 -i 0 -f /your_generated_bitstream_path
```

## Acknowledgments

Based on a reference document on FPGA-based image processing (unpublished, author not stated) provided during this internship.
