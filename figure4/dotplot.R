# R script to draw figure4 of OMG-seq manuscript
# Citation:
# Ohta T, Kawashima T, Shinozaki NO, Dobashi A, Hiraoka S, Hoshino T, Kanno K, Kataoka T, Kawashima S, Matsui M, Nemoto W, Nishijima S, Suganuma N, Suzuki H, Taguchi Y, Takenaka Y, Tanigawa Y, Tsuneyoshi M, Yoshitake K, Sato Y, Yamashita R, Arakawa K, Iwasaki W. Collaborative environmental DNA sampling from petal surfaces of flowering cherry Cerasus × yedoensis “Somei-yoshino” across the Japanese archipelago. Journal of Plant Research [Internet]. 2018 Feb 19;131(4):709–17. Available from: http://dx.doi.org/10.1007/s10265-018-1017-x
#
# Usage:
#  Rscript --vanilla dotplot.R data.tsv
#
# Run assemble_blast_result.sh with blastn result files tar available on https://github.com/inutano/ohanami-project-manuscript/tree/master/figure4 to make the input data
#

# Install ggplot2 if missing
if (!require("ggplot2")) {
  install.packages("ggplot2", repos="https://cran.ism.ac.jp/")
}
library("ggplot2")

# Load data
argv <- commandArgs(trailingOnly=T)
df <- read.delim(argv[1])
df$label <- paste(df$species, df$order, df$mismatches, sep=" / ")
numberOfSamples <- length(unique(df$sample_id))

# Generate plot object
p <- ggplot(df, aes(x=reorder(sample_id, sample_id, function(x)-length(x)), y=reorder(label, -mismatches), colour=log10(num_of_reads)))
p <- p + geom_point()
p <- p + theme_bw()
p <- p + theme(axis.text.x=element_blank(), axis.ticks.x=element_blank())
p <- p + labs(x=paste("Samples (total:", numberOfSamples, ")", sep=""), y="species / order / mismatches", colour="#reads (log10)")

# Save plot
ggsave(plot=p, file="./Fig4.pdf", width=702, height=234, unit="mm")
