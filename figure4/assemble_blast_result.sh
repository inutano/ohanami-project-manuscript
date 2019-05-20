#!/bin/bash
# Usage:
#  ./assemble_blast_result.sh <blast_result_dir>
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
# Filter sequences with percent identity >98% and alignment length >250
# ./plastid.blastn.tsv (3cols): filename, sseqid
find "${BLAST_RESULT_DIR}" | grep "bln$" |\
while read file; do
  sample_id="$(basename ${file} | sed -e "s:-.*$::g")"
  cat ${file} |\
  awk -v id="${sample_id}" '$3 > 99 && $4 > 250 { print id "\t" $2 }' >> "./plastid.blastn.tsv"
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
    echo -e "${sseqid}\t${organism}\t${tax_order}\t${num_mismatch}" >> "./sseqid-tax.tsv"
  fi
done

# Merge BLASTN result files
# ./plastid.blastn.tax.tsv (5cols): sample id, sseqid, #mismatches, label (species/order/mismatches), number of reads
cat "./plastid.blastn.tsv" | while read line; do
  sseqid="$(echo ${line} | awk '{ print $2 }')"
  tax_info="$(grep ${sseqid} "./sseqid-tax.tsv" | cut -f 2,3,4)"
  if [[ ! -z "${tax_info}" ]]; then
    echo -e "${line}\t${tax_info}"
  fi
done | sort |\
awk '
  BEGIN{
    FS=OFS="\t";
    print "sample_id", "sseqid", "mismatches", "label", "num_of_reads"
  }{
    seq_count[$1 "\t" $2 "\t" $5 "\t" $3 " / " $4 " / " $5] += 1
  }
  END{
    for (seq in seq_count) {
      print seq "\t" seq_count[seq]
    }
  }
' >> "./plastid.blastn.tax.tsv"
