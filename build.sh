#!/bin/bash

while IFS=$'\t' read board shield snippet artifact; do

  name=${artifact:-${shield:+$shield-}${board//\//_}-zmk}

  if [[ -z $board || -z $shield ]]; then continue; fi
  if [[ $# -gt 0 && ! " $@ " == *" $name "* ]]; then continue; fi

  rm -rf ./build/$name ./output/$name.*  
  west build -p always -d ./build/$name -s zmk/app \
    -b "$board" ${snippet:+-S "$snippet"} -- -DSHIELD="$shield" || exit
  
  for zmk in ./build/$name/zephyr/zmk.*; do cp $zmk ./output/${name}${zmk##*/zmk}; done
done < <(yq -r '.include[] | [.board, .shield, .snippet, ."artifact-name"] | @tsv' ./build.yaml)
