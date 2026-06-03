#!/bin/bash

while IFS=$'\t' read board shield snippet artifact args; do

  name=${artifact:-${shield:+$shield-}${board//\//_}-zmk}

  if [[ -z $board || -z $shield ]]; then continue; fi
  if [[ $# -gt 0 && ! " $@ " == *" $name "* ]]; then continue; fi

  args="$args -DSHIELD="$shield""
  args="$args -DZMK_CONFIG="$(pwd)/config""
  if [ -e ./extra_module/zephyr/module.yml ]; then

    args="$args -DZMK_EXTRA_MODULES="$(pwd)/extra_module""
  fi

  (
    echo start build $name
    rm -rf "./build/$name" "./output/$name".*
    west build -p always -d "./build/$name" -s zmk/app \
      -b "$board" ${snippet:+-S "$snippet"} -- $args &> "./output/$name.log"

    echo end build[$?] $name

    zephyr="./build/$name/zephyr"
    cat -s "$zephyr/zephyr.dts" &> "./output/$name.dts"
    cat -s "$zephyr/zephyr.dts.pre" &> "./output/$name.dts.pre"
    grep -v -e "^#" -e "^$" "$zephyr/.config" | sort &> "./output/$name.config"
    for zmk in "$zephyr"/zmk.*; do cp "$zmk" "./output/${name}${zmk##*/zmk}"; done
  ) &
done < <(yq -r '.include[] | [.board, .shield, .snippet, ."artifact-name", ."cmake-args"] | @tsv' ./build.yaml); wait
