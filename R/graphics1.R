graphicFlock <- function(filename){
  title <- unlist(strsplit(filename,"[.]"))
  test = read.csv(filename, sep = '\t', header=T)
  lcm <- test[test$tag=='lcm',]
  bfe <- test[test$tag=='bfe',]
  fp <- test[test$tag=='fp',]
  epsilon <- c(lcm$epsilon)
  epsilon1 <- c(bfe$epsilon)
  epsilon2 <- c(fp$epsilon)
  bfeflock <- c(bfe$time)
  lcmflock <- c(lcm$time)
  fpflock <- c(fp$time) 
  
  limit <- ceiling(max(bfeflock, lcmflock )) + 20
  
  namePDF <- paste0(title,".pdf")
  
  pdf(paste0(title[1],".pdf"))
  plot(epsilon, lcmflock, type="b",
    pch=15, lty=3, col="red", ylim=c(0, limit),
    main=paste0("Cambiando Epsilon\n [",title[1],"]"),
    xlab="Epsilon (m)", ylab="Tiempo de Procesamiento (s)")

  lines(epsilon1, bfeflock, type="b",
    pch=17, lty=2, col="blue")
  
  lines(epsilon2, fpflock, type="b",
        pch=18, lty=2, col="cyan")

  legend("topleft", inset=.05, title="Algoritmo", c("LCM","BFE", "FP"),
    lty=c(3, 2), pch=c(15, 17,18), col=c("red", "blue","cyan"))
  dev.off()
}