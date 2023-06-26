install.packages("ppclust")
install.packages("factoextra")
install.packages("dplyr")
install.packages("cluster")
install.packages("fclust")
install.packages("viridis")

require(ppclust)
require(factoextra)
require(dplyr)
require(cluster)
require(fclust)
library("viridis")

#Load Coal Cluster Data 
Coal <- read.csv("~/25-SPRING 2023-VOINOVICH PROJECT/Final/Coal mining cluster.csv", header=TRUE, stringsAsFactors=FALSE)

#View data
Coal

#create data frame X from Coal data, drop SOC_code
X<-data.frame(Coal[c(1:65),c(2:68)])

#View column correlation
cor(X[,1:67])

#C-mean fuzzy clustering wiht fuzziness level m=2
res.fcm <- fcm(X, centers=4, m=2)
#Write down and save the fuzzy clustering result
FuzzyCluster_Result_Mining<-as.data.frame(res.fcm$u)[,]
write.csv(FuzzyCluster_Result_Mining, "~/25-SPRING 2023-VOINOVICH PROJECT/Final/Coal mining fuzzy cluster results.csv", row.names=FALSE)


a<-res.fcm$v0
b<-res.fcm$v

#data visualization with prediction ellipses
res.fcm2 <- ppclust2(res.fcm, "kmeans")
fviz_cluster(res.fcm2, data = X, 
             ellipse.type = "norm",
             palette = "aaas",
             repel = TRUE)
