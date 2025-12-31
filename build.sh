#!/bin/bash

version="2_0_0"

# Build old chronicle (Předválečná kronika)
echo "Building Předválečná kronika..."
pdflatex -output-directory=out stara_kronika_main.tex

out_file_stara="./out/predvalecna_kronika_v${version}.pdf"
cp ./out/stara_kronika_main.pdf $out_file_stara
echo "file: ${out_file_stara}"

# Build new chronicle (Současná kronika)
echo "Building Současná kronika..."
pdflatex -output-directory=out nova_kronika_main.tex

out_file_nova="./out/soucasna_kronika_v${version}.pdf"
cp ./out/nova_kronika_main.pdf $out_file_nova
echo "file: ${out_file_nova}"

echo "Both chronicles built successfully!"

