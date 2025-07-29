# global.R
# Shared libraries, data, and functions for the Shiny app

# ---- Chargement des bibliothèques ----
library(shiny)           # Framework Shiny pour applications web interactives
library(shinydashboard)  # Interface de tableau de bord
library(DT)              # Tableaux interactifs
library(leaflet)         # Cartes interactives
library(plotly)          # Visualisations interactives
library(dplyr)           # Manipulation de données
library(ggplot2)         # Création de graphiques
library(lubridate)       # Gestion des dates et heures
library(httr)            # Requêtes HTTP
library(jsonlite)        # Manipulation JSON
library(sf)              # Données spatiales
library(osmdata)         # Données OpenStreetMap
library(osrm)            # Routing with OSRM
library(caret)           # Entraînement de modèles
library(igraph)          # Algorithmes de graphes
library(corrplot)        # Visualisation de corrélations
library(randomForest)    # Modèle Random Forest
library(e1071)           # Modèle SVM
library(visNetwork)      # Visualisation de graphes interactifs

# ---- Définition des zones géographiques ----
ZONES <- list(
  "Keur Massar" = c(lat = 14.7843, lng = -17.3213),
  "Dakar Plateau" = c(lat = 14.6937, lng = -17.4441),
  "Pikine" = c(lat = 14.7646, lng = -17.3907),
  "Rufisque" = c(lat = 14.7158, lng = -17.2733),
  "Guédiawaye" = c(lat = 14.7750, lng = -17.3847),
  "Yoff" = c(lat = 14.7627, lng = -17.4757)
)

# ---- Fonction pour générer des données réalistes ----
generate_realistic_data <- function(n_workers = 200, start_point, end_point) {
  set.seed(50)  # Fixer la graine pour reproductibilité
  
  worker_ids <- paste0("W", sprintf("%03d", 1:n_workers))
  
  routes <- data.frame(
    route_name = c("Route_A38_Autoroute", "Route_Corniche", "Route_Rufisque", 
                   "Route_Thiaroye", "Route_Mixte"),
    base_distance = c(20, 25, 30, 22, 27),
    base_quality = c("Excellent", "Bon", "Moyen", "Mauvais", "Bon"),
    congestion_factor = c(0.8, 1.2, 1.5, 1.3, 1.0)
  )
  route_probs <- c(0.40, 0.25, 0.15, 0.10, 0.10)
  
  data <- data.frame(
    worker_id = worker_ids,
    route_selected = sample(routes$route_name, n_workers, replace = TRUE, prob = route_probs),
    departure_time = sample(seq(from = as.POSIXct("2025-07-20 06:00:00", tz = "UTC"), 
                                to = as.POSIXct("2025-07-20 09:00:00", tz = "UTC"), 
                                by = "5 min"), n_workers, replace = TRUE),
    vehicle_type = sample(c("Berline", "SUV", "Citadine", "Minibus"), 
                          n_workers, replace = TRUE, prob = c(0.45, 0.25, 0.20, 0.10)),
    income_level = sample(c("Faible", "Moyen", "Élevé"), 
                          n_workers, replace = TRUE, prob = c(0.35, 0.50, 0.15)),
    start_point = start_point,  # Ajouté pour correspondre au filtrage
    end_point = end_point       # Ajouté pour correspondre au filtrage
  )
  
  data$departure_hour <- hour(data$departure_time) + minute(data$departure_time) / 60
  
  data <- data %>%
    left_join(routes, by = c("route_selected" = "route_name")) %>%
    mutate(
      route_length = base_distance + rnorm(n_workers, 0, 1.5),
      route_quality = base_quality
    )
  
  data$travel_time <- pmax(15, round(
    data$route_length * (1 + data$congestion_factor) * 1.5 +
      ifelse(hour(data$departure_time) %in% c(7, 8), 15, 0) +
      ifelse(data$route_quality == "Mauvais", 10, 0) +
      rnorm(n_workers, 0, 3)
  ))
  
  data$congestion_time <- pmax(0, round(
    data$travel_time * (0.1 + 0.2 * data$congestion_factor) +
      ifelse(hour(data$departure_time) %in% c(7, 8), 8, 0) +
      rnorm(n_workers, 0, 2)
  ))
  
  data$traffic_volume <- round(
    800 * data$congestion_factor +
      ifelse(hour(data$departure_time) %in% c(7, 8), 300, 0) +
      rnorm(n_workers, 0, 50)
  )
  
  data$congestion_density <- pmin(1, pmax(0, 
                                          data$traffic_volume / (1500 + 500 * (data$route_quality == "Excellent"))
  ))
  
  data$fuel_consumption <- round(
    case_when(
      data$vehicle_type == "Berline" ~ rnorm(n_workers, 8, 1),
      data$vehicle_type == "SUV" ~ rnorm(n_workers, 10, 1.5),
      data$vehicle_type == "Citadine" ~ rnorm(n_workers, 6, 0.8),
      data$vehicle_type == "Minibus" ~ rnorm(n_workers, 12, 2)
    ), 1
  )
  
  data$travel_cost <- round(
    data$route_length * (data$fuel_consumption / 100) * 800 +
      ifelse(data$route_selected == "Route_A38_Autoroute", 500, 0) +
      rnorm(n_workers, 0, 100)
  )
  
  data$co2_emission <- round(
    data$route_length * (data$fuel_consumption / 100) * 2300
  )
  
  start_coords <- ZONES[[start_point]]
  end_coords <- ZONES[[end_point]]
  data$start_lat <- start_coords["lat"] + rnorm(n_workers, 0, 0.005)
  data$start_lng <- start_coords["lng"] + rnorm(n_workers, 0, 0.005)
  data$end_lat <- end_coords["lat"] + rnorm(n_workers, 0, 0.003)
  data$end_lng <- end_coords["lng"] + rnorm(n_workers, 0, 0.003)
  
  message("Colonnes générées :", paste(names(data), collapse = ", "))
  message("Type de departure_time :", class(data$departure_time))
  if (anyNA(data$departure_time)) {
    message("Valeurs NA détectées dans departure_time :", sum(is.na(data$departure_time)))
  }
  message("Résumé de travel_time :", summary(data$travel_time))
  
  return(data)
}

# ---- Fonction pour la description des algorithmes d'optimisation ----
get_algorithm_description <- function(algorithm) {
  if (algorithm == "A*") {
    return(
      "<h4>Algorithme A*</h4>
       <p><b>Description :</b> A* est un algorithme de recherche de chemin qui utilise une heuristique pour guider la recherche vers le nœud cible, combinant le coût réel depuis le départ (g) et une estimation du coût restant (h).</p>
       <p><b>Utilisation dans ce cas :</b> Trouve le chemin optimal entre le point de départ et la destination en minimisant une combinaison de temps, coût et émissions CO2, en utilisant une heuristique basée sur une approximation de la distance.</p>
       <p><b>Avantages :</b> Efficace pour les graphes avec de nombreux nœuds, grâce à l'heuristique qui réduit le nombre de nœuds explorés.</p>
       <p><b>Limitations :</b> La performance dépend de la qualité de l'heuristique. Une heuristique mal choisie peut ralentir l'algorithme.</p>"
    )
  } else if (algorithm == "Dijkstra") {
    return(
      "<h4>Algorithme de Dijkstra</h4>
       <p><b>Description :</b> Dijkstra est un algorithme de recherche de chemin qui explore tous les nœuds du graphe pour trouver le chemin avec le coût minimal, en utilisant uniquement le coût réel (pas d'heuristique).</p>
       <p><b>Utilisation dans ce cas :</b> Optimise le trajet en minimisant une combinaison pondérée de temps, coût et émissions CO2, en explorant systématiquement les routes possibles.</p>
       <p><b>Avantages :</b> Garantit la solution optimale pour les graphes avec des poids non négatifs. Simple à implémenter.</p>
       <p><b>Limitations :</b> Peut être plus lent qu'A* sur de grands graphes, car il explore tous les nœuds sans heuristique.</p>"
    )
  } else {
    return("<p>Algorithme non reconnu.</p>")
  }
}