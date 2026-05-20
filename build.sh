#!/bin/bash

west update && west zephyr-export || exit

while read line; do

  board=$(echo $line | grep -oE 'board: [^: ]+' | awk -F ': ' '{print $2}')
  shield=$(echo $line | grep -oE 'shield: [^: ]+' | awk -F ': ' '{print $2}')
  snippet=$(echo $line | grep -oE 'snippet: [^: ]+' | awk -F ': ' '{print $2}')
  artificial=$(echo $line | grep -oE 'artificial-name: [^: ]+' | awk -F ': ' '{print $2}')
  
  name=${artificial:-$shield}
  if [[ -z $board || -z $shield ]]; then continue; fi
  if [[ $# -gt 0 && ! " $@ " == *" $name "* ]]; then continue; fi

  rm -rf ./build/$name ${OUTPUT_DIR:-.}/$name.*
  west build -d ./build/$name -s zmk/app -b $board ${snippet:+-S $snippet} -- -DSHIELD=$shield || continue
  
  mkdir -p ${OUTPUT_DIR:-.}
  for zmk in ./build/$name/zephyr/zmk.*; do cp $zmk ${OUTPUT_DIR:-.}/${name}${zmk##*/zmk}; done
done < <(tr -d '\n' < ${BUILD_YAML:-/dev/null} | xargs | sed 's/ - /\n/g;')
