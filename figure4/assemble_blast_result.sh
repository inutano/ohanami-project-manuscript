#!/bin/bash
# Usage:
#  ./assemble_blast_result.sh <blast_result_dir>

BLAST_RESULT_DIR="${1}"

## TODO
## Create "joint.pl.list" from blast result files using API
## Remove text beforehand like sed lines below

# Merge BLASTN result files
ls "${BLAST_RESULT_DIR}" |\
  while read file; do
    cat ${file} |\
    awk --assign fname="${file}" 'BEGIN{ OFS="\t" } $3 > 98 && $4 > 250 { print fname,$2,$3 }' | sort -u
  done |\
  while read line; do
    id=`echo ${line} | cut -f 2`
    sp=`grep ${id} list/joint.pl.list | awk -F '|' '{ print $5 }'`
    if [[ ! -z "${sp}" ]]; then
      echo $l "\t" $sp
    fi
  done > pl.tab

## TODO
## Decode SPARQL query and load into variable

# Generate species order
cat pl.loc.tab | \
  tail +2 |\
  awk -F '\t' '{ print $4 }' |\
  sort -u |\
  sed -e 's:,.*$::g' |\
  sed -e 's:plastid.*$::g' |\
  sed -e 's:voucher.*$::g' |\
  sed -e 's:genotype.*$::g' |\
  sed -e 's:complete.*$::g' |\
  sed -e 's:chloroplast.*$::g' |\
  sed -e 's:^ *::g' -e 's: *$::g' |\
  sed -e 's:culture*::g' |\
  sed -e 's:-collection.*$::g' |\
  sed -e 's:subsp.*$::g' |\
  sort -u |\
  while read sname; do
    s=`echo $sname | sed -e 's: :+:'`
    order=`curl -s "http://togogenome.org/sparql?query=select+distinct+%3FparentLabel%0D%0Awhere+%7B%0D%0A++graph+%3Chttp%3A%2F%2Ftogogenome.org%2Fgraph%2Ftaxonomy%3E+%7B%0D%0A++++%3Fs+a+%3Chttp%3A%2F%2Fddbj.nig.ac.jp%2Fontologies%2Ftaxonomy%2FTaxon%3E%3B%0D%0A++++++rdfs%3Alabel+%3Flabel%3B%0D%0A++++++rdfs%3AsubClassOf%2B+%3Fparent+.+%0D%0A++++%3Fparent+%3Chttp%3A%2F%2Fddbj.nig.ac.jp%2Fontologies%2Ftaxonomy%2Frank%3E+%3Frank%3B%0D%0A++++++rdfs%3Alabel+%3FparentLabel+.%0D%0A++++%3Frank+rdfs%3Alabel+%3FrankLabel%0D%0A++++filter%28%3Flabel+%3D+%22${s}%22%29.%0D%0A++++filter%28%3FrankLabel+%3D+%22order%22%29+.%0D%0A++%7D%0D%0A%7D%0D%0Alimit+50&format=text%2Ftab-separated-values" |\
      tail -n 1 |\
      sed -e 's:"::g'`
    echo $sname "\t" $order
  done > "species_order.txt"

# Generate data for visualization
cat pl.data.tab |\
  awk 'BEGIN{FS=OFS="\t"}{ print $1, $5, $6, $14, $15 }' |\
  while read line; do
    sname=`echo ${line} |\
      awk -F '\t' '{ print $2 }' |\
        sed -e 's:,.*$::g' |\
        sed -e 's:plastid.*$::g' |\
        sed -e 's:voucher.*$::g' |\
        sed -e 's:genotype.*$::g' |\
        sed -e 's:complete.*$::g' |\
        sed -e 's:chloroplast.*$::g' |\
        sed -e 's:^ *::g' -e 's: *$::g' |\
        sed -e 's:culture*::g' |\
        sed -e 's:-collection.*$::g' |\
        sed -e 's:subsp.*$::g'`
    order=`grep ${sname} "../species_order.txt" | cut -f 2 | sed -e 's: ::g'`
    echo ${line} "\t" ${sname} "\t" ${order}
  done |\
  awk 'BEGIN{FS=OFS="\t"} NF == 7 { print $0, $6 " / " $7 " / " $5 }' \
    > ../data.tab
