args <- commandArgs(trailingOnly = TRUE)
r <- data.frame()
s <- data.frame()
for (arg in args) {
	a <- strsplit(sub(".log", "", arg), "-")
  a <- a[[1]]
	type <- a[[2]]
	scale = as.numeric(a[[3]])

	con <- file(arg, open = "r")
	while (length(line <- readLines(con, n = 1, warn = FALSE)) > 0) {
		if (startsWith(line, "# ")) {
			if (startsWith(line, "# achieved ops/s: ")) {
				actual <- as.numeric(sub("# achieved ops/s: ", "", line))
			}
		} else {
			v <- read.table(text = line)
      page = v[,1]
      time_type = toString(v[,2])
      pct = as.factor(v[,3])
      time = as.numeric(v[,4])
      if (identical(time_type, "sojourn")) {
        s <- rbind(s, data.frame(type=type, op=page, pct=pct, sjrn=time, scale=scale, actual=actual))
      } else {
        r <- rbind(r, data.frame(type=type, op=page, pct=pct, rmt=time, scale=scale, actual=actual))
      }
		}
	}
	close(con)
}

r = r[r$pct != 100,]
s = s[s$pct != 100,]
# r = r[r$pct != 99,]
# s = s[s$pct != 99,]
# r = r[r$pct == 95,]
# s = s[s$pct == 95,]
# r = r[r$pct == 50,]
# s = s[s$pct == 50,]
# t = t[t$workers == 1,]
# t = t[t$target <= 400000,]

#t$batchsize <- factor(t$batchsize, levels = t$batchsize[order(t$batchsize)])
#t$max <- factor(t$max, levels = t$max[order(t$max)])
#
#t$sjrn <- pmin(t$sjrn, 500) # otherwise ggplot tries to plot all the way to 100k
library(ggplot2)

options(scipen=10000)
p <- ggplot(data=r[r$pct == 50,], aes(x=actual, y=rmt, color=op, linetype=type, shape=type))
# p <- p + coord_trans(x = "identity", y = "identity", limy=c(0, 3000))
p <- p + facet_grid(~ pct, labeller = label_both)
p <- p + geom_point(size = 0.7, alpha = 0.8) + geom_line()
p <- p + xlab("achieved ops/s") + ylab("batch processing time (ms)")
ggsave('plot-batch-50.png',plot=p,width=10,height=4)

p <- ggplot(data=s[s$pct == 50,], aes(x=actual, y=sjrn, color=op, linetype=type, shape=type))
# p <- p + coord_trans(x = "identity", y = "identity", limy=c(0, 3000))
p <- p + facet_grid(~ pct, labeller = label_both)
p <- p + geom_point(size = 0.7, alpha = 0.8) + geom_line()
p <- p + xlab("achieved ops/s") + ylab("sojourn time (ms)")
ggsave('plot-sjrn-50.png',plot=p,width=10,height=4)

p <- ggplot(data=r[r$pct == 95,], aes(x=actual, y=rmt, color=op, linetype=type, shape=type))
# p <- p + coord_trans(x = "identity", y = "identity", limy=c(0, 3000))
p <- p + facet_grid(~ pct, labeller = label_both)
p <- p + geom_point(size = 0.7, alpha = 0.8) + geom_line()
p <- p + xlab("achieved ops/s") + ylab("batch processing time (ms)")
ggsave('plot-batch-95.png',plot=p,width=10,height=4)

p <- ggplot(data=s[s$pct == 95,], aes(x=actual, y=sjrn, color=op, linetype=type, shape=type))
# p <- p + coord_trans(x = "identity", y = "identity", limy=c(0, 3000))
p <- p + facet_grid(~ pct, labeller = label_both)
p <- p + geom_point(size = 0.7, alpha = 0.8) + geom_line()
p <- p + xlab("achieved ops/s") + ylab("sojourn time (ms)")
ggsave('plot-sjrn-95.png',plot=p,width=10,height=4)

p <- ggplot(data=r[r$pct == 99,], aes(x=actual, y=rmt, color=op, linetype=type, shape=type))
# p <- p + coord_trans(x = "identity", y = "identity", limy=c(0, 3000))
p <- p + facet_grid(~ pct, labeller = label_both)
p <- p + geom_point(size = 0.7, alpha = 0.8) + geom_line()
p <- p + xlab("achieved ops/s") + ylab("batch processing time (ms)")
ggsave('plot-batch-99.png',plot=p,width=10,height=4)

p <- ggplot(data=s[s$pct == 99,], aes(x=actual, y=sjrn, color=op, linetype=type, shape=type))
# p <- p + coord_trans(x = "identity", y = "identity", limy=c(0, 3000))
p <- p + facet_grid(~ pct, labeller = label_both)
p <- p + geom_point(size = 0.7, alpha = 0.8) + geom_line()
p <- p + xlab("achieved ops/s") + ylab("sojourn time (ms)")
ggsave('plot-sjrn-99.png',plot=p,width=10,height=4)
