graphicFlock <- function(filename){
  title <- unlist(strsplit(filename,"[.]"))
  test = read.csv(filename, sep = '\t', header=T)
  lcm <- test[test$tag=='lcm',]
  bfe <- test[test$tag=='bfe',]
  fp1 <- test[test$tag=='fp1',]
  fp2 <- test[test$tag=='fp2',]
  epsilon <- c(lcm$epsilon)
  epsilon1 <- c(bfe$epsilon)
  epsilon2 <- c(fp1$epsilon)
  epsilon3 <- c(fp2$epsilon)
  bfeflock <- c(bfe$time)
  lcmflock <- c(lcm$time)
  fp1flock <- c(fp1$time)
  fp2flock <- c(fp2$time)
  
  limit <- ceiling(max(bfeflock, lcmflock, fp1flock, fp2flock )) + 20
  
  namePDF <- paste0(title,".pdf")
  
  pdf(paste0(title[1],".pdf"))
  plot(epsilon, lcmflock, type="b",
    pch=15, lty=3, col="red", ylim=c(0, limit),
    main=paste0("Cambiando Epsilon\n [",title[1],"]"),
    xlab="Epsilon (m)", ylab="Tiempo de Procesamiento (s)")

  lines(epsilon1, bfeflock, type="b",
    pch=17, lty=2, col="blue")
  
  lines(epsilon2, fp1flock, type="b",
        pch=18, lty=2, col="cyan")
  
  lines(epsilon3, fp2flock, type="b",
        pch=19, lty=2, col="darkmagenta")

  legend("topleft", inset=.05, title="Algoritmo", c("LCMFlock","BFE", "FPFlockOffline", "FPFLockOnline"),
    lty=c(3, 2), pch=c(15, 17,18,19), col=c("red", "blue","cyan", "darkmagenta"))
  dev.off()
}