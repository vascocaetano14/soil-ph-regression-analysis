#Projeto 2
#Questão 1

library(carData)
library(rrcov)
library(psych)
library(car)
library(ggplot2)
library(WRS2)

data("Soils")
var_cols <- c("pH", "N", "Dens", "P", "Ca", "Mg", "K", "Na", "Conduc")
my_data <- Soils[, var_cols]
my_data

#Estatísticas Descritivas Comparativas
Resumo_Estatístico <- describe(my_data)
Resumo_Estatístico

# Comparação: Média Clássica vs Winsorizada vs Mediana

winsorized_means <- apply(my_data, 2, winmean, tr=0.2) 
medianas <- apply(my_data, 2, median)
comp_medias <- round(rbind(
  Media_Classica = colMeans(my_data), 
  Media_Winsor   = winsorized_means, 
  Mediana        = medianas
), 3)
comp_medias

# Comparação Dispersão SD vs MAD
sds  <- apply(my_data, 2, sd)
sds
mads <- apply(my_data, 2, mad)
mads
comp_disp <- round(rbind(SD = sds, MAD = mads), 3)
comp_disp

# Boxplots com identificação de outliers
dev.new(title="Boxplots") 
par(mfrow=c(3,3)) 
for(col in names(my_data)) {
  valores_1 <- my_data[[col]]
  car::Boxplot(valores_1, main=col, col="lightblue", id.n=Inf, ylab="")
}
par(mfrow=c(1,1))

# QQ-Plots 
dev.new(title="QQ-Plots")
par(mfrow=c(3,3))
for(col in names(my_data)) {
  valores_2 <- my_data[[col]]
  car::qqPlot(valores_2, main=col, id=list(n=2), col.lines="red", ylab = "")
}
par(mfrow=c(1,1))

# Variância Multivariada
S <- cov(my_data)
S
R <- cor(my_data)
R
var_total <- sum(diag(S))  
var_generalizada <- det(S)
Var_Multivariada <- round(rbind(Var_Generalizada = det(S), Var_Total = sum(diag(S))), 2)

# Matriz de dispersão
dev.new(title="Pairs Plot")
psych::pairs.panels(my_data, 
                    smooth = FALSE, 
                    ellipses = FALSE, 
                    lm = TRUE, 
                    main = "Matriz de Dispersão (Soils)")

#Distâncias de Mahalanobis
mcd_fit <- covMcd(my_data, alpha=0.75) 
centro_rob <- mcd_fit$center
cov_rob    <- mcd_fit$cov
md_rob <- mahalanobis(my_data, center = centro_rob, cov = cov_rob)

cutoff <- qchisq(0.975, df = ncol(my_data))
outliers_idx <- which(md_rob > cutoff)

#Plot Mahalanobis
dev.new(title="Mahalanobis QQ-Plot")
car::qqPlot(md_rob, distribution="chisq", df=ncol(my_data),
            main="QQ-Plot: Distâncias de Mahalanobis (Robustas)",
            ylab="Mahalanobis Distance^2", pch=19, col="blue", 
            id=list(n=3))


#Questão 2

library(carData)
data("Soils")

dados_soils <- Soils[, c("pH", "N", "Dens", "P", "Ca", "Mg", "K", "Na", "Conduc")]

modelo_completo <- lm(pH ~ ., data = dados_soils)

modelo_2 <- update(modelo_completo, . ~ . - N)


modelo_3 <- update(modelo_2, . ~ . - P)
print("Modelo 3 (sem Fósforo)")
summary(modelo_3)

modelo_4 <- update(modelo_3, . ~ . - Mg)
print("Modelo 4 (sem Magnésio)")
summary(modelo_4)

modelo_5 <- update(modelo_4, . ~ . - K)
print("Modelo 5 (sem potássio)")
summary(modelo_5)

modelo_6 <- update(modelo_5, . ~ . - Dens)
print("Modelo 6 (sem Densidade)")
summary(modelo_6)


obs_interesse <- dados_soils[c(12, 24), ]

print("Observações 12 e 24")
print(obs_interesse)


IC_resultado <- predict(modelo_6, newdata = obs_interesse, interval = "confidence", level = 0.975)

print("Intervalo de confiança (97.5%)")
print(IC_resultado)


IP_resultado <- predict(modelo_6, newdata = obs_interesse, interval = "prediction", level = 0.975)

print("Intervalo de previsão (97.5%)")
print(IP_resultado)

#Tabela final 
fmt <- function(x) {
  format(round(x, 3), decimal.mark = ",", nsmall = 3)
}

tabela_final <- data.frame(
  `Valor Ajustado (ŷ)` = fmt(IC_resultado[, "fit"]),
  `Intervalo de Confiança (97,5%)` = paste0("[", fmt(IC_resultado[, "lwr"]), " ; ", fmt(IC_resultado[, "upr"]), "]"),
  `Intervalo de Previsão (97,5%)` = paste0("[", fmt(IP_resultado[, "lwr"]), " ; ", fmt(IP_resultado[, "upr"]), "]"),
  row.names = c("12","24"),
  check.names = FALSE 
)