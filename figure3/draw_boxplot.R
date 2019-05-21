# draw_histogram.R for Ohanami Project Manuscript figure 3
#
# Citation:
# Ohta T, Kawashima T, Shinozaki NO, Dobashi A, Hiraoka S, Hoshino T, Kanno K, Kataoka T, Kawashima S, Matsui M, Nemoto W, Nishijima S, Suganuma N, Suzuki H, Taguchi Y, Takenaka Y, Tanigawa Y, Tsuneyoshi M, Yoshitake K, Sato Y, Yamashita R, Arakawa K, Iwasaki W. Collaborative environmental DNA sampling from petal surfaces of flowering cherry Cerasus × yedoensis “Somei-yoshino” across the Japanese archipelago. Journal of Plant Research [Internet]. 2018 Feb 19;131(4):709–17. Available from: http://dx.doi.org/10.1007/s10265-018-1017-x
#
# Usage:
#  Rscript draw_boxplot.R assembled.csv
#

# Install ggplot2 if missing
# ggplot2
if (!require("ggplot2")) {
  install.packages("ggplot2", repos="https://cran.ism.ac.jp/")
}
library("ggplot2")

# Read file and transpose
argv <- commandArgs(trailingOnly=T)
df.temp <- read.csv(argv[1], row.names=1)
df <- data.frame(t(df.temp))

# Check number of lines
nrow(df)

# Check summary
summary(df)

# Set function to align labels
give.n <- function(x){ return(c(y = median(x)-.1, label = length(x))) }

# Create ggplot object
p <- ggplot(stack(lapply(df, as.numeric)), aes(x = reorder(ind, -values, FUN=mean), y = values))
p <- p + geom_boxplot(outlier.size=.5)
p <- p + scale_y_log10()
p <- p + stat_summary(fun.data = give.n, geom = "text", size = 2)
p <- p + theme_bw()
p <- p + theme(axis.text.x = element_text(angle = 45, hjust = 1))
p <- p + labs(x = "Phylum", y = "Number of assigned reads per sample (log10)")
p <- p + annotate("text", label=paste("#samples:", nrow(df), sep=" "), x=length(colnames(df))*0.9, y=max(df)*0.8)

# Save in the file
ggsave(file="./figure3.pdf", plot=p, width=170, units="mm")
