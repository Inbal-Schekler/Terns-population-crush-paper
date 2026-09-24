data = read.csv("data2.csv", header=TRUE) -> filename
attach(data)
str(data)

t.test(x_alb ~ type_alb)

wilcox.test(x_alb ~ type_alb)



boxplot(x ~ type, xlab="", ylab="מספר זוגות", cex.lab=1.5, cex.axis=1.5, col=c("orange","orange","red","red"), names=c("רכב","מצלמה/מגדל","רכב","מצלמה/מגדל"))

legend(0.5, 910, pt.cex=3.5, bty="n", c("שחפית גמדית","שחפית ים"), pch=22, col=c("black","black"), pt.bg=c("orange","red"), cex=1.5)

