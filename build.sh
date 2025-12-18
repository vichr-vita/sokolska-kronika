#!/bin/bash

version="1_2_0"

pdflatex -output-directory=out main.tex


out_file="./out/sokolska_kronika_v${version}.pdf"
cp ./out/main.pdf $out_file
echo "file: ${out_file}"

