#!/bin/bash
# Bash script to assemble multiple blastn result files and assign taxonomic information using TogoGenome database taxonomy RDF
# License: MIT, Tazro Inutano Ohta, inutano@gmail.com
#
# Citation:
# Ohta T, Kawashima T, Shinozaki NO, Dobashi A, Hiraoka S, Hoshino T, Kanno K, Kataoka T, Kawashima S, Matsui M, Nemoto W, Nishijima S, Suganuma N, Suzuki H, Taguchi Y, Takenaka Y, Tanigawa Y, Tsuneyoshi M, Yoshitake K, Sato Y, Yamashita R, Arakawa K, Iwasaki W. Collaborative environmental DNA sampling from petal surfaces of flowering cherry Cerasus × yedoensis “Somei-yoshino” across the Japanese archipelago. Journal of Plant Research [Internet]. 2018 Feb 19;131(4):709–17. Available from: http://dx.doi.org/10.1007/s10265-018-1017-x
#
# Usage:
#  ./assemble_blast_result.sh <blast_result_tar>
# The blastn result file tar file used in the publication is available on https://github.com/inutano/ohanami-project-manuscript/tree/master/figure4
#
# To draw the plot, run dotplot.R with the output of this script "plastid.blastn.tax.tsv"
# or use Docker:
# docker run -it --rm -v $(pwd):/work -w /work bioconductor/release_base2:R3.5.2_Bioc3.8 Rscript --vanilla dotplot.R plastid.blastn.tax.tsv
#
set -eu

BLAST_RESULT_TAR="${1}"
BLAST_RESULT_DIR="$(dirname ${BLAST_RESULT_TAR})"

## Functions

# Get species name from nuccore id using TogoWS
get_organism() {
  local nuccore_id=${1}
  curl -s "http://togows.org/entry/ncbi-nuccore/${nuccore_id}/organism"
}

# SPARQL query to get taxonomic order for each
# Get taxonomy info for each organism from TogoGenome via SPARQL endpoint

# URL contains encoded SPARQL query; the original query is:
# select distinct ?parentLabel
# where {
#   graph <http://togogenome.org/graph/taxonomy> {
#     ?s a <http://ddbj.nig.ac.jp/ontologies/taxonomy/Taxon>;
#       rdfs:label ?label;
#       rdfs:subClassOf+ ?parent .
#     ?parent <http://ddbj.nig.ac.jp/ontologies/taxonomy/rank> ?rank;
#       rdfs:label ?parentLabel .
#     ?rank rdfs:label ?rankLabel
#     filter(?label = "${species}").
#     filter(?rankLabel = "order") .
#   }
# }
# limit 50

get_order() {
  local species=$(echo ${1} | sed -e 's: :+:')
  curl -s "http://togogenome.org/sparql?query=select+distinct+%3FparentLabel%0D%0Awhere+%7B%0D%0A++graph+%3Chttp%3A%2F%2Ftogogenome.org%2Fgraph%2Ftaxonomy%3E+%7B%0D%0A++++%3Fs+a+%3Chttp%3A%2F%2Fddbj.nig.ac.jp%2Fontologies%2Ftaxonomy%2FTaxon%3E%3B%0D%0A++++++rdfs%3Alabel+%3Flabel%3B%0D%0A++++++rdfs%3AsubClassOf%2B+%3Fparent+.+%0D%0A++++%3Fparent+%3Chttp%3A%2F%2Fddbj.nig.ac.jp%2Fontologies%2Ftaxonomy%2Frank%3E+%3Frank%3B%0D%0A++++++rdfs%3Alabel+%3FparentLabel+.%0D%0A++++%3Frank+rdfs%3Alabel+%3FrankLabel%0D%0A++++filter%28%3Flabel+%3D+%22${species}%22%29.%0D%0A++++filter%28%3FrankLabel+%3D+%22order%22%29+.%0D%0A++%7D%0D%0A%7D%0D%0Alimit+50&format=text%2Ftab-separated-values" | tail -n 1 | sed -e 's:"::g'
}

## Main

# Unarchive blast result
tar zxf "${BLAST_RESULT_TAR}" -C "${BLAST_RESULT_DIR}"

# Merge BLASTN hits against the Organelle Genome Resources with filename
# Filter sequences with 100 percent identity and alignment length >250
# ./plastid.blastn.tsv (3cols): filename, sseqid, number of reads
find "${BLAST_RESULT_DIR}" | grep "bln$" |\
while read file; do
  sample_id="$(basename ${file} | sed -e "s:-.*$::g")"
  cat ${file} |\
  awk -v id="${sample_id}" '$3 == 100 && $4 > 250 { print id "\t" $2 }' |\
  sort | uniq -c | awk '{ print $2 "\t" $3 "\t" $1 }' >> "./plastid.blastn.tsv"
done

# Create plastid definition list using TogoWS (http://togows.org)
# ./sseqid-tax.tsv (4cols): sseqid, organism name, taxonomic order, number of mismatches against the sequence of C. yedoensis
cat "./plastid.blastn.tsv" | cut -f 2 | sort -u |\
while read sseqid; do
  nuccore_id=$(echo ${sseqid} | awk -F'|' '{ print $2 }')
  organism="$(get_organism ${nuccore_id})"
  tax_order=$(get_order ${organism})
  num_mismatch=$(grep "${sseqid}" "./data/plastid.numMismatch-vs-Sakura.txt" | cut -f 2)
  if [[ ! -z "${num_mismatch}" ]]; then
    printf "${sseqid}\t${organism}\t${tax_order}\t${num_mismatch}\n" >> "./sseqid-tax.tsv"
  fi
done

# Merge BLASTN result files
# ./plastid.blastn.tax.tsv (5cols): sample id, sseqid, number of reads, species, order, #mismatches
printf "sample_id\tsseqid\tnum_of_reads\tspecies\torder\tmismatches\n" > "./plastid.blastn.tax.tsv"
cat "./plastid.blastn.tsv" | while read line; do
  sseqid="$(echo ${line} | awk '{ print $2 }')"
  tax_info="$(grep ${sseqid} "./sseqid-tax.tsv" | cut -f 2,3,4)"
  printf "${line}\t${tax_info}\n" |\
  awk -F'\t' 'NF == 6'
done >> "./plastid.blastn.tax.tsv"
