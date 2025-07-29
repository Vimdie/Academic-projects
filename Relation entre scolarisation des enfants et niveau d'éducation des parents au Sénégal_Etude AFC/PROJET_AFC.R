
# 1. Définition du répertoire de travail
#_______________________________________
install.packages("gplots")
 
# 2. Chargement des packages nécessaires
#_______________________________________
  
  # Chargement des librairies
  # Mais d'abord télécharger les packages s'ils ne sont pas encore installés
  library(readxl)       # Permet d'importer les données
  library(haven)
  library(tidyverse)    # Permet de manipuler les matrices
  library(FactoMineR)   # Permet de faire l'analyse factorielle
  library(factoextra)   # Permet de les représentations de l'Analyse factorielle
  library(gplots)       # Permet une représentation graphique du tableau de contingence
  library(corrplot)
  
# 3. Exportation de la base de données
#_____________________________________
  
  Data_CA <- read_dta("C:/Users/ANSD/Desktop/projet AFC/baseAF.dta")
  
  str(Data_CA)     # structure des données
  head(Data_CA)    # premières lignes
  summary(Data_CA) # résumé statistique
  
  # créer un tableau de contingence
  tab_cont <- table(Data_CA$niveau_edu_p, Data_CA$education_formelle)
  print(tab_cont)
  
  
  #nombre d'observation
  nb_total <- sum(tab_cont)
  #affichage
  cat("Nombre total d'observations :", nb_total, "\n")
  ******ne pas exécuter
  Data_CA  <- Data_CA %>% remove_rownames %>% column_to_rownames(var="niveau_edu_p/education_formelle")
  View(tab_cont) 
  # La base contient deux variables
  
  # Une visualisation graphique du tableau de contingence
  data <- as.table(as.matrix (tab_cont))  #pour les besoins de la fonction balloonplot
  balloonplot(t(data), label = FALSE, show.margins = FALSE)
  
# 3. Statistiques descriptives classiques
#________________________________________
  
  Data <- read_dta("C:/Users/ANSD/Desktop/projet AFC/baseAF.dta")
  
  # Le mode de la variable "niveau_edu_p"
  table(Data$niveau_edu_p)
  names(which.max(table(Data$niveau_edu_p)))
  
  # Le mode de la variable "education_formelle"
  table(Data$education_formelle)
  names(which.max(table(Data$education_formelle)))
  
  # La statistique du Chi-2
  Vars <- table(Data$education_formelle, Data$niveau_edu_p)
  res <- chisq.test(Vars)
  res$statistic
  # test du khi-deux
  
  # Création du tableau de contingence
  Vars <- table(Data$education_formelle, Data$niveau_edu_p)
  
  # Test du Chi-deux
  res <- chisq.test(Vars)
  
  # Affichage des résultats
  cat("=== Résultats du test du Chi-deux ===\n")
  cat("Statistique Chi-deux :", round(res$statistic, 4), "\n")
  cat("Degrés de liberté    :", res$parameter, "\n")
  cat("P-value              :", signif(res$p.value, 4), "\n\n")
  
  # Interprétation automatique
  if (res$p.value < 0.05) {
    cat("📌 Interprétation : Il existe une association significative entre\n")
    cat("la raison de non scolarisation et le niveau d'éducation des parents.\n")
    cat("→ On rejette l'hypothèse d'indépendance (au seuil de 5%).\n")
  } else {
    cat("📌 Interprétation : Aucune association significative détectée.\n")
    cat("→ On ne rejette pas l'hypothèse d'indépendance.\n")
  }
  
  
# 4. L'analyse factorielle des correspondances
#_____________________________________________
  
  # 4.1 Mise en oeuvre de l'AFC
  #----------------------------
  CA_result <- CA (tab_cont, ncp =6 , graph = FALSE)
  
  # 4.2 Analyse des valeurs propres
  #--------------------------------
  eig.value <- CA_result$eig
  eig.value = as.data.frame(eig.value)
  eig.value$dimension = seq.int(from=1, to=2, by=1)
  View(eig.value)
  ggplot(eig.value, aes(x=dimension, y=`percentage of variance`)) +
        geom_bar(fill="#FFA500",stat = "identity") +
        geom_point() +
        geom_line() + 
        scale_x_discrete(breaks=seq.int(from=1, to=10, by=1)) +
        ggtitle("Diagramme des valeurs propres") +
        xlab("Dimensions") +
        ylab("Valeurs propres")
  
  # 4.3 Analyse du nuage de la variable "niveau_edu_p"
  #---------------------------------------------
  row <- get_ca_row(CA_result)
  
  # Nuage des modalités
  fviz_ca_row(CA_result,repel = TRUE,axes = c(1, 2))
  library(corrplot)
  #Contribution des modalités a la formation des axes
  corrplot(row$contrib[,1:5], is.corr=FALSE)
  fviz_contrib(CA_result, choice = "row", axes = 1:2)
  fviz_ca_row(CA_result, col.row = "contrib",
              gradient.cols = c("#FC4E07", "#E7B800","#00AFBB"),repel = TRUE)
  
  # Qualite de representation des modalités
  corrplot(row$cos2[,1:2], is.corr=FALSE)
  fviz_cos2(CA_result, choice = "row", axes = 1:2)
  fviz_ca_row(CA_result, col.row = "cos2", gradient.rows = c("#FC4E07", "#E7B800","#00AFBB"),
              repel = TRUE) 
  
  # 4.4 Analyse du nuage de la variable "education_formelle"
  #-------------------------------------------------
  col <- get_ca_col(CA_result)
  
  # Nuage des modalités
  fviz_ca_col(CA_result,repel = TRUE,axes = c(1, 2))
  
  #Contribution des modalités a la formation des axes
  corrplot(col$contrib[,1:5], is.corr=FALSE)
  fviz_contrib(CA_result, choice = "col", axes = 1:2)
  fviz_ca_col(CA_result, col.col = "contrib",
              gradient.cols = c("#FC4E07", "#E7B800","#00AFBB"),repel = TRUE)
  
  # Qualite de representation des modalités
  corrplot(col$cos2[,1:2], is.corr=FALSE)
  fviz_cos2(CA_result, choice = "col", axes = 1:2)
  fviz_ca_col(CA_result, col.col = "cos2", gradient.rows = c("#FC4E07", "#E7B800","#00AFBB"),
              repel = TRUE) 

  # 4.5 Analyse des deux nuages
  #----------------------------
  fviz_ca_biplot(CA_result, repel = TRUE)

****************************************************************************************************         

  
 