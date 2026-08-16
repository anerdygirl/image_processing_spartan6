#!/usr/bin/bash

mkdir -p ~/image_processing_spartan6/ipcore_dir/$1
cp ~/image_processing_spartan6/ipcore_dir/tmp/_cg/$1.vhd ~/image_processing_spartan6/ipcore_dir/$1/
cp ~/image_processing_spartan6/ipcore_dir/tmp/_cg/$1.vho ~/image_processing_spartan6/ipcore_dir/$1/
cp ~/image_processing_spartan6/ipcore_dir/tmp/_cg/$1.ngc ~/image_processing_spartan6/ipcore_dir/$1/
cp ~/image_processing_spartan6/ipcore_dir/tmp/_cg/$1.xco ~/image_processing_spartan6/ipcore_dir/$1/
cp /home/fafaaa/image_processing_spartan6/ipcore_dir/tmp/_cg/$1.mif  ~/image_processing_spartan6/ipcore_dir/$1/
