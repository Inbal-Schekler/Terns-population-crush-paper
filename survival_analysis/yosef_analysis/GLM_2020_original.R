library(lme4)
library(Matrix)
library(rsq)
library(lmerTest)
library(MuMIn)

data = read.csv("data.csv", header=TRUE) -> filename
attach(data)
str(data)

shapiro.test(alb)
hist(alb)


### מודלים שלב א לכל 11 השנים עבור שחפית ים

m0 <- glm(hir ~ 1, family=gaussian, data=data)
summary(m0)
rsq(m0) # r^2

m1 <- glm(hir ~ predation, family=gaussian, data=data)
summary(m1)
rsq(m1) # r^2

m2 <- glm(hir ~ newcastle, family=gaussian, data=data)
summary(m2)
rsq(m2) # r^2

m3 <- glm(hir ~ predation + newcastle, family=gaussian, data=data)
summary(m3)
rsq(m3) # r^2

m4 <- glm(hir ~ temp37, family=gaussian, data=data)
summary(m4)
rsq(m4) # r^2

m5 <- glm(hir ~ predation + temp37, family=gaussian, data=data)
summary(m5)
rsq(m5) # r^2

m6 <- glm(hir ~ newcastle + temp37, family=gaussian, data=data)
summary(m6)
rsq(m6) # r^2

m7 <- glm(hir ~ predation + newcastle + temp37, family=gaussian, data=data)
summary(m7)
rsq(m7) # r^2

m8 <- glm(hir ~ temp12, family=gaussian, data=data)
summary(m8)
rsq(m8) # r^2

m9 <- glm(hir ~ predation + temp12, family=gaussian, data=data)
summary(m9)
rsq(m9) # r^2

m10 <- glm(hir ~ newcastle + temp12, family=gaussian, data=data)
summary(m10)
rsq(m10) # r^2

m11 <- glm(hir ~ predation + newcastle + temp12, family=gaussian, data=data)
summary(m11)
rsq(m11) # r^2

m12 <- glm(hir ~ meanMAXtemp, family=gaussian, data=data)
summary(m12)
rsq(m12) # r^2

m13 <- glm(hir ~ predation + meanMAXtemp, family=gaussian, data=data)
summary(m13)
rsq(m13) # r^2

m14 <- glm(hir ~ newcastle + meanMAXtemp, family=gaussian, data=data)
summary(m14)
rsq(m14) # r^2

m15 <- glm(hir ~ predation + newcastle + meanMAXtemp, family=gaussian, data=data)
summary(m15)
rsq(m15) # r^2

m16 <- glm(hir ~ meanMINtemp, family=gaussian, data=data)
summary(m16)
rsq(m16) # r^2

m17 <- glm(hir ~ predation + meanMINtemp, family=gaussian, data=data)
summary(m17)
rsq(m17) # r^2

m18 <- glm(hir ~ newcastle + meanMINtemp, family=gaussian, data=data)
summary(m18)
rsq(m18) # r^2

m19 <- glm(hir ~ predation + newcastle + meanMINtemp, family=gaussian, data=data)
summary(m19)
rsq(m19) # r^2

m20 <- glm(hir ~ rainMAY, family=gaussian, data=data)
summary(m20)
rsq(m20) # r^2

m21 <- glm(hir ~ predation + rainMAY, family=gaussian, data=data)
summary(m21)
rsq(m21) # r^2

m22 <- glm(hir ~ newcastle + rainMAY, family=gaussian, data=data)
summary(m22)
rsq(m22) # r^2

m23 <- glm(hir ~ predation + newcastle + rainMAY, family=gaussian, data=data)
summary(m23)
rsq(m23) # r^2

m24 <- glm(hir ~ rainJUN, family=gaussian, data=data)
summary(m24)
rsq(m24) # r^2

m25 <- glm(hir ~ predation + rainJUN, family=gaussian, data=data)
summary(m25)
rsq(m25) # r^2

m26 <- glm(hir ~ newcastle + rainJUN, family=gaussian, data=data)
summary(m26)
rsq(m26) # r^2

m27 <- glm(hir ~ predation + newcastle + rainJUN, family=gaussian, data=data)
summary(m27)
rsq(m27) # r^2




out.put <- model.sel(m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16,m17,m18,m19,m20,m21,m22,m23,m24,m25,m26,m27) 
out.put




### מודלים שלב א לכל 11 השנים עבור שחפית גמדית

m0 <- glm(alb ~ 1, family=gaussian, data=data)
summary(m0)
rsq(m0) # r^2

m1 <- glm(alb ~ predation, family=gaussian, data=data)
summary(m1)
rsq(m1) # r^2

m2 <- glm(alb ~ newcastle, family=gaussian, data=data)
summary(m2)
rsq(m2) # r^2

m3 <- glm(alb ~ predation + newcastle, family=gaussian, data=data)
summary(m3)
rsq(m3) # r^2

m4 <- glm(alb ~ temp37, family=gaussian, data=data)
summary(m4)
rsq(m4) # r^2

m5 <- glm(alb ~ predation + temp37, family=gaussian, data=data)
summary(m5)
rsq(m5) # r^2

m6 <- glm(alb ~ newcastle + temp37, family=gaussian, data=data)
summary(m6)
rsq(m6) # r^2

m7 <- glm(alb ~ predation + newcastle + temp37, family=gaussian, data=data)
summary(m7)
rsq(m7) # r^2

m8 <- glm(alb ~ temp12, family=gaussian, data=data)
summary(m8)
rsq(m8) # r^2

m9 <- glm(alb ~ predation + temp12, family=gaussian, data=data)
summary(m9)
rsq(m9) # r^2

m10 <- glm(alb ~ newcastle + temp12, family=gaussian, data=data)
summary(m10)
rsq(m10) # r^2

m11 <- glm(alb ~ predation + newcastle + temp12, family=gaussian, data=data)
summary(m11)
rsq(m11) # r^2

m12 <- glm(alb ~ meanMAXtemp, family=gaussian, data=data)
summary(m12)
rsq(m12) # r^2

m13 <- glm(alb ~ predation + meanMAXtemp, family=gaussian, data=data)
summary(m13)
rsq(m13) # r^2

m14 <- glm(alb ~ newcastle + meanMAXtemp, family=gaussian, data=data)
summary(m14)
rsq(m14) # r^2

m15 <- glm(alb ~ predation + newcastle + meanMAXtemp, family=gaussian, data=data)
summary(m15)
rsq(m15) # r^2

m16 <- glm(alb ~ meanMINtemp, family=gaussian, data=data)
summary(m16)
rsq(m16) # r^2

m17 <- glm(alb ~ predation + meanMINtemp, family=gaussian, data=data)
summary(m17)
rsq(m17) # r^2

m18 <- glm(alb ~ newcastle + meanMINtemp, family=gaussian, data=data)
summary(m18)
rsq(m18) # r^2

m19 <- glm(alb ~ predation + newcastle + meanMINtemp, family=gaussian, data=data)
summary(m19)
rsq(m19) # r^2

m20 <- glm(alb ~ rainMAY, family=gaussian, data=data)
summary(m20)
rsq(m20) # r^2

m21 <- glm(alb ~ predation + rainMAY, family=gaussian, data=data)
summary(m21)
rsq(m21) # r^2

m22 <- glm(alb ~ newcastle + rainMAY, family=gaussian, data=data)
summary(m22)
rsq(m22) # r^2

m23 <- glm(alb ~ predation + newcastle + rainMAY, family=gaussian, data=data)
summary(m23)
rsq(m23) # r^2

m24 <- glm(alb ~ rainJUN, family=gaussian, data=data)
summary(m24)
rsq(m24) # r^2

m25 <- glm(alb ~ predation + rainJUN, family=gaussian, data=data)
summary(m25)
rsq(m25) # r^2

m26 <- glm(alb ~ newcastle + rainJUN, family=gaussian, data=data)
summary(m26)
rsq(m26) # r^2

m27 <- glm(alb ~ predation + newcastle + rainJUN, family=gaussian, data=data)
summary(m27)
rsq(m27) # r^2




out.put <- model.sel(m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16,m17,m18,m19,m20,m21,m22,m23,m24,m25,m26,m27) 
out.put








data = read.csv("data1.csv", header=TRUE) -> filename
attach(data)
str(data)




### מודלים שלב ב, 9 שנים עבור שחפית ים

m0 <- glm(hir ~ 1, family=gaussian, data=data)
summary(m0)
rsq(m0) # r^2

m1 <- glm(hir ~ predation, family=gaussian, data=data)
summary(m1)
rsq(m1) # r^2

m2 <- glm(hir ~ albTWOyears, family=gaussian, data=data)
summary(m2)
rsq(m2) # r^2

m3 <- glm(hir ~ hirMASS, family=gaussian, data=data)
summary(m3)
rsq(m3) # r^2

m4 <- glm(hir ~ temp37, family=gaussian, data=data)
summary(m4)
rsq(m4) # r^2

m5 <- glm(hir ~ predation + albTWOyears, family=gaussian, data=data)
summary(m5)
rsq(m5) # r^2

m6 <- glm(hir ~ predation + hirMASS, family=gaussian, data=data)
summary(m6)
rsq(m6) # r^2

m7 <- glm(hir ~ predation + temp37, family=gaussian, data=data)
summary(m7)
rsq(m7) # r^2

m8 <- glm(hir ~ albTWOyears + hirMASS, family=gaussian, data=data)
summary(m8)
rsq(m8) # r^2

m9 <- glm(hir ~ albTWOyears + temp37, family=gaussian, data=data)
summary(m9)
rsq(m9) # r^2

m10 <- glm(hir ~ hirMASS + temp37, family=gaussian, data=data)
summary(m10)
rsq(m10) # r^2

m11 <- glm(hir ~ predation + albTWOyears + hirMASS, family=gaussian, data=data)
summary(m11)
rsq(m11) # r^2

m12 <- glm(hir ~ predation + albTWOyears + temp37, family=gaussian, data=data)
summary(m12)
rsq(m12) # r^2

m13 <- glm(hir ~ predation + hirMASS + temp37, family=gaussian, data=data)
summary(m13)
rsq(m13) # r^2

m14 <- glm(hir ~ albTWOyears + hirMASS + temp37, family=gaussian, data=data)
summary(m14)
rsq(m14) # r^2

m15 <- glm(hir ~ predation + albTWOyears + hirMASS + temp37, family=gaussian, data=data)
summary(m15)
rsq(m15) # r^2

m16 <- glm(hir ~ temp12, family=gaussian, data=data)
summary(m16)
rsq(m16) # r^2

m17 <- glm(hir ~ predation + temp12, family=gaussian, data=data)
summary(m17)
rsq(m17) # r^2

m18 <- glm(hir ~ albTWOyears + temp12, family=gaussian, data=data)
summary(m18)
rsq(m18) # r^2

m19 <- glm(hir ~ hirMASS + temp12, family=gaussian, data=data)
summary(m19)
rsq(m19) # r^2

m20 <- glm(hir ~ predation + albTWOyears + temp12, family=gaussian, data=data)
summary(m20)
rsq(m20) # r^2

m21 <- glm(hir ~ predation + hirMASS + temp12, family=gaussian, data=data)
summary(m21)
rsq(m21) # r^2

m22 <- glm(hir ~ albTWOyears + hirMASS + temp12, family=gaussian, data=data)
summary(m22)
rsq(m22) # r^2

m23 <- glm(hir ~ predation + albTWOyears + hirMASS + temp12, family=gaussian, data=data)
summary(m23)
rsq(m23) # r^2


out.put <- model.sel(m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16,m17,m18,m19,m20,m21,m22,m23) 
out.put







### מודלים שלב ב, 9 שנים עבור שחפית גמדית

m0 <- glm(alb ~ 1, family=gaussian, data=data)
summary(m0)
rsq(m0) # r^2

m1 <- glm(alb ~ predation, family=gaussian, data=data)
summary(m1)
rsq(m1) # r^2

m2 <- glm(alb ~ hirTWOyears, family=gaussian, data=data)
summary(m2)
rsq(m2) # r^2

m3 <- glm(alb ~ albMASS, family=gaussian, data=data)
summary(m3)
rsq(m3) # r^2

m4 <- glm(alb ~ meanMINtemp, family=gaussian, data=data)
summary(m4)
rsq(m4) # r^2

m5 <- glm(alb ~ predation + hirTWOyears, family=gaussian, data=data)
summary(m5)
rsq(m5) # r^2

m6 <- glm(alb ~ predation + albMASS, family=gaussian, data=data)
summary(m6)
rsq(m6) # r^2

m7 <- glm(alb ~ predation + meanMINtemp, family=gaussian, data=data)
summary(m7)
rsq(m7) # r^2

m8 <- glm(alb ~ hirTWOyears + albMASS, family=gaussian, data=data)
summary(m8)
rsq(m8) # r^2

m9 <- glm(alb ~ hirTWOyears + meanMINtemp, family=gaussian, data=data)
summary(m9)
rsq(m9) # r^2

m10 <- glm(alb ~ albMASS + meanMINtemp, family=gaussian, data=data)
summary(m10)
rsq(m10) # r^2

m11 <- glm(alb ~ predation + hirTWOyears + albMASS, family=gaussian, data=data)
summary(m11)
rsq(m11) # r^2

m12 <- glm(alb ~ predation + hirTWOyears + meanMINtemp, family=gaussian, data=data)
summary(m12)
rsq(m12) # r^2

m13 <- glm(alb ~ predation + albMASS + meanMINtemp, family=gaussian, data=data)
summary(m13)
rsq(m13) # r^2

m14 <- glm(alb ~ hirTWOyears + albMASS + meanMINtemp, family=gaussian, data=data)
summary(m14)
rsq(m14) # r^2

m15 <- glm(alb ~ predation + hirTWOyears + albMASS + meanMINtemp, family=gaussian, data=data)
summary(m15)
rsq(m15) # r^2

m16 <- glm(alb ~ meanMAXtemp, family=gaussian, data=data)
summary(m16)
rsq(m16) # r^2

m17 <- glm(alb ~ predation + meanMAXtemp, family=gaussian, data=data)
summary(m17)
rsq(m17) # r^2

m18 <- glm(alb ~ hirTWOyears + meanMAXtemp, family=gaussian, data=data)
summary(m18)
rsq(m18) # r^2

m19 <- glm(alb ~ albMASS + meanMAXtemp, family=gaussian, data=data)
summary(m19)
rsq(m19) # r^2

m20 <- glm(alb ~ predation + hirTWOyears + meanMAXtemp, family=gaussian, data=data)
summary(m20)
rsq(m20) # r^2

m21 <- glm(alb ~ predation + albMASS + meanMAXtemp, family=gaussian, data=data)
summary(m21)
rsq(m21) # r^2

m22 <- glm(alb ~ hirTWOyears + albMASS + meanMAXtemp, family=gaussian, data=data)
summary(m22)
rsq(m22) # r^2

m23 <- glm(alb ~ predation + hirTWOyears + albMASS + meanMAXtemp, family=gaussian, data=data)
summary(m23)
rsq(m23) # r^2



out.put <- model.sel(m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16,m17,m18,m19,m20,m21,m22,m23) 
out.put



