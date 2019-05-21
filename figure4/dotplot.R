# R script to draw figure4 of OMG-seq manuscript https://doi.org/10.1007/s10265-018-1017-x
# Usage:
#  Rscript --vanilla dotplot.R data.tab

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
