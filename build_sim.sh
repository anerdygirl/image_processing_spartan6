#!/bin/bash


vhpcomp -work work pixel_pkg.vhd
vhpcomp -work work ipcore_dir/img_rom/img_rom.vhd
vhpcomp -work work ipcore_dir/frame_out/frame_out.vhd
vhpcomp -work work uart_tx_clk.vhd
vhpcomp -work work ctrl_fsm.vhd
vhpcomp -work work processing_top1.vhd
vhpcomp -work work TX.vhd
vhpcomp -work work top_level.vhd
vhpcomp -work work top_level_test.vhd

