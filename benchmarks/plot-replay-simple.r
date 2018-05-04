args <- commandArgs(trailingOnly = TRUE)
t <- data.frame()
for (arg in args) {
	a <- strsplit(sub(".log", "", arg), "-")
  a <- a[[1]]
	type <- a[[1]]
	read_count = as.numeric(a[[2]])
	row_count = as.numeric(a[[3]])

	con <- file(arg, open = "r")
	while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0) {
		if (!startsWith(line, "# ")) {
			v <- read.table(text = line)
			t <- rbind(t, data.frame(op=type, pct=as.factor(v[,2]), rmt=as.numeric(v[,3]), read_count=read_count, row_count=row_count))
		}
	}
	close(con)
}

# Filter out the 100th percentile:
t = t[t$pct != 100,]
# t = t[t$votes < 10000000,]
# t
# t = t[t$pct == 95,]
# t = t[t$workers == 1,]

#t$batchsize <- factor(t$batchsize, levels = t$batchsize[order(t$batchsize)])
#t$max <- factor(t$max, levels = t$max[order(t$max)])
#
#t$sjrn <- pmin(t$sjrn, 500) # otherwise ggplot tries to plot all the way to 100k
library(ggplot2)

# options(scipen=10000)
p <- ggplot(data=t, aes(x=read_count, y=rmt, color=pct, linetype=op, shape=op))
p <- p + scale_x_continuous(trans="log2")
# p <- p + coord_trans(x = "identity", y = "identity", limy=c(0, 1500))
p <- p + facet_grid(row_count ~ ., labeller = label_both)
p <- p + geom_point(size = 0.7, alpha = 0.8) + geom_line()
p <- p + xlab("rows") + ylab("read latency (µs)")
ggsave('plot-read.png', plot=p, width=10, height=4)
ggsave('plot-read.svg', plot=p, width=10, height=4)
