library(ggplot2)

# Load data
df<-read.delim("data.tab")

# Generate plot object
p <- ggplot(df, aes(x=reorder(sample_id, sample_id, function(x)-length(x)), y=reorder(label, -mismatches), colour=num_of_reads))
p <- p + geom_point()
p <- p + theme_bw()
p <- p + theme(axis.text.x=element_blank(), axis.ticks.x=element_blank()) + labs(x="Samples", y="species/order/mismatches", colour="#reads")
ggsave(plot=p, file="./Fig4.pdf", width=234, height=234, unit="mm")
