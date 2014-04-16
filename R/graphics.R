filename <- "SJ25K60.csv"
test = read.csv(filename, sep = '\t', header=T)
lcm <- test[test$tag=='lcm',]
bfe <- test[test$tag=='bfe',]
epsilon <- c(lcm$epsilon)
bfeflock <- c(bfe$time)
lcmflock <- c(lcm$time)

opar <- par(no.readonly=TRUE)
par(lwd=2, cex=1.5, font.lab=2)
plot(epsilon, lcmflock, type="b",
     pch=15, lty=1, col="red", ylim=c(0, 250),
     main=filename,
     xlab="Epsilon", ylab="Time")

lines(epsilon, bfeflock, type="b",
  pch=17, lty=2, col="blue")

abline(h=c(30), lwd=1.5, lty=2, col="gray")

library(Hmisc)

minor.tick(nx=3, ny=3, tick.ratio=0.5)

legend("topleft", inset=0.05, title="Flock Type", c("A","B"),
lty=c(1, 2), pch=c(15, 17), col=c("red", "blue"))

par(opar)

