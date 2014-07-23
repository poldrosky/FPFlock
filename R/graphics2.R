graphicFlock <- function(filename){
  title <- unlist(strsplit(filename,"[.]"))
  title1 <- substr(title[1], 1, nchar(title[1])-2)
  test = read.csv(filename, sep = '\t', header=T)
  lcm <- test[test$tag=='lcm',]
  fp1 <- test[test$tag=='fp1',]
  fp2 <- test[test$tag=='fp2',]
  epsilon <- c(lcm$epsilon)
  epsilon2 <- c(fp1$epsilon)
  epsilon3 <- c(fp2$epsilon)
  lcmflock <- c(lcm$time)
  fp1flock <- c(fp1$time)
  fp2flock <- c(fp2$time)
  
  limit <- ceiling(max(lcmflock, fp1flock, fp2flock )) + 20
  
  namePDF <- paste0(title,".pdf")
  
  pdf(paste0(title[1],".pdf"))
  plot(epsilon, lcmflock, type="b",
    pch=15, lty=3, col="red", ylim=c(0, limit),
    main=paste0("Cambiando Epsilon\n [",title1,"]"),
    xlab="Epsilon (m)", ylab="Tiempo de Procesamiento (s)")

  lines(epsilon2, fp1flock, type="b",
        pch=18, lty=2, col="cyan")
  
  lines(epsilon3, fp2flock, type="b",
        pch=19, lty=2, col="darkmagenta")

  legend("topleft", inset=.05, title="Algoritmo", c("LCMFlock", "FPFlockOffline", "FPFLockOnline"),
    lty=c(3, 2), pch=c(15, 17,18,19), col=c("red","cyan", "darkmagenta"))
  dev.off()
}