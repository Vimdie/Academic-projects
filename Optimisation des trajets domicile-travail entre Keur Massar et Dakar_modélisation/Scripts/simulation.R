# simulation.R
# Logic for the Simulation tab with enhanced A* implementation and route comparison

library(dplyr)
library(igraph)
library(leaflet)
library(plotly)
library(ggplot2)
library(tidyr)
library(visNetwork)
library(DT)

# ---- Fonction pour simuler des scénarios de trajet ----
simulate_travel_scenarios <- function(data, model, departure, vehicle, start, end) {
  tryCatch({
    departure <- as.numeric(departure)
    if (is.na(departure)) {
      stop("L'heure de départ n'est pas valide ou ne peut pas être convertie en numérique.")
    }
    
    message("Avant filtrage, nombre de lignes dans data : ", nrow(data))
    # Assouplir le filtrage sur departure_hour
    sim_data <- data %>%
      filter(
        vehicle_type == vehicle,
        departure_hour >= (departure - 0.25) & departure_hour <= (departure + 0.5),
        start_point == start,
        end_point == end
      ) %>%
      select(travel_time, congestion_time, route_length, traffic_volume, 
             congestion_density, fuel_consumption, route_selected, vehicle_type, 
             departure_hour, travel_cost, co2_emission, route_quality) %>%
      na.omit()
    
    message("Après filtrage, nombre de lignes dans sim_data : ", nrow(sim_data))
    all_routes <- c("Route_A38_Autoroute", "Route_Corniche", "Route_Rufisque", 
                    "Route_Thiaroye", "Route_Mixte")
    missing_routes <- setdiff(all_routes, unique(sim_data$route_selected))
    
    # Si aucune donnée après filtrage, utiliser toutes les routes disponibles
    if (nrow(sim_data) == 0) {
      message("Aucune donnée après filtrage strict. Utilisation des données sans filtrage horaire.")
      sim_data <- data %>%
        filter(
          vehicle_type == vehicle,
          start_point == start,
          end_point == end
        ) %>%
        select(travel_time, congestion_time, route_length, traffic_volume, 
               congestion_density, fuel_consumption, route_selected, vehicle_type, 
               departure_hour, travel_cost, co2_emission, route_quality) %>%
        na.omit()
      message("Après filtrage assoupli, nombre de lignes dans sim_data : ", nrow(sim_data))
    }
    
    # Vérifier que toutes les routes sont présentes
    if (length(missing_routes) > 0) {
      message("Ajout des routes manquantes avec des valeurs par défaut.")
      for (route in missing_routes) {
        default_row <- sim_data[1, ] # Prendre la première ligne comme base
        if (nrow(sim_data) == 0) {
          default_row <- data[1, ]
          default_row$travel_time <- mean(data$travel_time, na.rm = TRUE)
          default_row$congestion_time <- mean(data$congestion_time, na.rm = TRUE)
          default_row$route_length <- mean(data$route_length, na.rm = TRUE)
          default_row$travel_cost <- mean(data$travel_cost, na.rm = TRUE)
          default_row$co2_emission <- mean(data$co2_emission, na.rm = TRUE)
        }
        default_row$route_selected <- route
        default_row$route_quality <- data$route_quality[data$route_selected == route][1]
        sim_data <- rbind(sim_data, default_row)
      }
    }
    
    sim_data$route_selected <- as.factor(sim_data$route_selected)
    sim_data$vehicle_type <- as.factor(sim_data$vehicle_type)
    
    # Indicateur pour savoir si le modèle est utilisé
    use_model <- !is.null(model)
    
    if (use_model) {
      expected_route_levels <- levels(model$trainingData$route_selected)
      expected_vehicle_levels <- levels(model$trainingData$vehicle_type)
      
      sim_data$route_selected <- factor(sim_data$route_selected, levels = expected_route_levels)
      sim_data$vehicle_type <- factor(sim_data$vehicle_type, levels = expected_vehicle_levels)
      
      sim_data <- sim_data %>% na.omit()
      message("Après réencodage des facteurs, nombre de lignes dans sim_data : ", nrow(sim_data))
      if (nrow(sim_data) == 0) {
        message("Aucune donnée valide après réencodage des facteurs.")
        return(NULL)
      }
      
      sim_data$predicted_time <- tryCatch({
        predict(model, sim_data)
      }, error = function(e) {
        message("Erreur lors de la prédiction avec le modèle : ", e$message)
        message("Utilisation de travel_time comme approximation.")
        sim_data$travel_time
      })
    } else {
      sim_data$predicted_time <- sim_data$travel_time
      message("Aucun modèle entraîné, utilisation de travel_time comme approximation.")
    }
    
    if (all(is.na(sim_data$predicted_time))) {
      message("Erreur : predicted_time contient uniquement des NA.")
      return(NULL)
    }
    
    route_summary <- sim_data %>%
      group_by(route_selected) %>%
      summarise(
        avg_predicted_time = mean(predicted_time, na.rm = TRUE),
        avg_cost = mean(travel_cost, na.rm = TRUE),
        avg_co2 = mean(co2_emission, na.rm = TRUE),
        avg_congestion = mean(congestion_time, na.rm = TRUE),
        route_quality = first(na.omit(route_quality)),
        avg_route_length = mean(route_length, na.rm = TRUE),
        .groups = "drop"
      )
    
    message("Nombre de lignes dans route_summary : ", nrow(route_summary))
    message("Colonnes de route_summary : ", paste(names(route_summary), collapse = ", "))
    message("Routes dans route_summary : ", paste(unique(route_summary$route_selected), collapse = ", "))
    if (nrow(route_summary) == 0 || any(is.na(route_summary$avg_predicted_time))) {
      message("Erreur : route_summary est vide ou avg_predicted_time contient des NA.")
      return(NULL)
    }
    
    return(list(data = route_summary, use_model = use_model))
  }, error = function(e) {
    message("Erreur dans simulate_travel_scenarios : ", e$message)
    return(NULL)
  })
}

# ---- Amélioration de l'implémentation A* ----
optimize_route_astar <- function(data, start_point, end_point, weights = c(time = 0.5, cost = 0.3, co2 = 0.2)) {
  tryCatch({
    if (start_point == end_point) {
      message("Point de départ et d'arrivée identiques : ", start_point)
      return(list(
        optimal_route = start_point,
        optimal_time = 0,
        optimal_cost = 0,
        optimal_co2 = 0,
        path = c(start_point),
        route_metrics = data
      ))
    }
    
    required_cols <- c("route_selected", "avg_predicted_time", "avg_cost", "avg_co2", "avg_route_length", "route_quality")
    missing_cols <- setdiff(required_cols, names(data))
    if (length(missing_cols) > 0) {
      stop(paste("Colonnes manquantes dans les données d'entrée :", paste(missing_cols, collapse = ", ")))
    }
    
    # Vérifier que les poids sont valides
    if (sum(weights) < 0.01) {
      stop("La somme des poids ne peut pas être nulle.")
    }
    # Normaliser les poids
    weights <- weights / sum(weights)
    message("Poids normalisés : ", paste(weights, collapse = ", "))
    
    message("Colonnes de data dans optimize_route_astar : ", paste(names(data), collapse = ", "))
    if (nrow(data) == 0) {
      stop("Les données d'entrée sont vides.")
    }
    
    routes <- unique(as.character(data$route_selected))
    message("Routes uniques : ", paste(routes, collapse = ", "))
    
    all_vertices <- unique(c(start_point, end_point, routes))
    message("Sommets définis pour le graphe : ", paste(all_vertices, collapse = ", "))
    
    # Créer les données du graphe
    graph_data <- data %>%
      group_by(route_selected) %>%
      summarise(
        time_weight = mean(avg_predicted_time, na.rm = TRUE),
        cost_weight = mean(avg_cost, na.rm = TRUE),
        co2_weight = mean(avg_co2, na.rm = TRUE),
        distance = mean(avg_route_length, na.rm = TRUE),
        route_quality = first(na.omit(route_quality)),
        .groups = "drop"
      ) %>%
      mutate(route_selected = as.character(route_selected))
    
    if (any(is.na(graph_data$time_weight)) || any(is.na(graph_data$cost_weight)) || 
        any(is.na(graph_data$co2_weight)) || any(is.na(graph_data$route_quality))) {
      stop("Les métriques (time_weight, cost_weight, co2_weight, route_quality) contiennent des valeurs NA.")
    }
    
    # Normalisation des métriques
    max_time <- max(graph_data$time_weight, na.rm = TRUE)
    max_cost <- max(graph_data$cost_weight, na.rm = TRUE)
    max_co2 <- max(graph_data$co2_weight, na.rm = TRUE)
    
    if (max_time == 0 || max_cost == 0 || max_co2 == 0) {
      stop("Une ou plusieurs métriques maximales sont nulles, impossible de normaliser.")
    }
    
    graph_data <- graph_data %>%
      mutate(
        norm_time = time_weight / max_time,
        norm_cost = cost_weight / max_cost,
        norm_co2 = co2_weight / max_co2,
        combined_weight = weights["time"] * norm_time + 
          weights["cost"] * norm_cost + 
          weights["co2"] * norm_co2
      )
    
    # Créer les arêtes
    edge_list <- rbind(
      data.frame(
        from = start_point,
        to = routes,
        weight = 0,
        time = 0,
        cost = 0,
        co2 = 0,
        distance = 0,
        stringsAsFactors = FALSE
      ),
      data.frame(
        from = routes,
        to = end_point,
        weight = graph_data$combined_weight[match(routes, graph_data$route_selected)],
        time = graph_data$time_weight[match(routes, graph_data$route_selected)],
        cost = graph_data$cost_weight[match(routes, graph_data$route_selected)],
        co2 = graph_data$co2_weight[match(routes, graph_data$route_selected)],
        distance = graph_data$distance[match(routes, graph_data$route_selected)],
        stringsAsFactors = FALSE
      )
    ) %>% na.omit()
    
    if (nrow(edge_list) == 0) {
      stop("Aucune arête valide après suppression des NA.")
    }
    
    message("Arêtes du graphe : ", paste(capture.output(print(edge_list)), collapse = "\n"))
    
    # Heuristique améliorée intégrant les poids
    start_coords <- ZONES[[start_point]]
    end_coords <- ZONES[[end_point]]
    geo_distance <- sqrt((start_coords["lat"] - end_coords["lat"])^2 + 
                           (start_coords["lng"] - end_coords["lng"])^2) * 100
    
    heuristic <- function(node) {
      if (node == end_point) return(0)
      node_coords <- if (node %in% names(ZONES)) ZONES[[node]] else 
        c(lat = mean(c(start_coords["lat"], end_coords["lat"])), 
          lng = mean(c(start_coords["lng"], end_coords["lng"])))
      dist_to_end <- sqrt((node_coords["lat"] - end_coords["lat"])^2 + 
                            (node_coords["lng"] - end_coords["lng"])^2) * 100
      # Ajuster l'heuristique avec les poids
      min_weight <- min(graph_data$combined_weight, na.rm = TRUE)
      weighted_heuristic <- dist_to_end * min_weight * (weights["time"] + weights["cost"] + weights["co2"])
      return(weighted_heuristic)
    }
    
    # Algorithme A*
    open_set <- data.frame(node = start_point, g_score = 0, f_score = heuristic(start_point), 
                           stringsAsFactors = FALSE)
    came_from <- list()
    g_score <- setNames(rep(Inf, length(all_vertices)), all_vertices)
    g_score[start_point] <- 0
    f_score <- setNames(rep(Inf, length(all_vertices)), all_vertices)
    f_score[start_point] <- heuristic(start_point)
    
    time_score <- setNames(rep(0, length(all_vertices)), all_vertices)
    cost_score <- setNames(rep(0, length(all_vertices)), all_vertices)
    co2_score <- setNames(rep(0, length(all_vertices)), all_vertices)
    distance_score <- setNames(rep(0, length(all_vertices)), all_vertices)
    
    while (nrow(open_set) > 0) {
      current_idx <- which.min(open_set$f_score)
      current <- open_set$node[current_idx]
      message("Noeud courant : ", current, ", f_score : ", open_set$f_score[current_idx])
      
      if (current == end_point) {
        path <- c(end_point)
        while (path[1] %in% names(came_from)) {
          path <- c(came_from[[path[1]]], path)
        }
        if (length(path) < 2) {
          stop("Aucun chemin valide trouvé entre le point de départ et la destination.")
        }
        optimal_route <- path[2]
        message("Chemin optimal trouvé : ", paste(path, collapse = " -> "))
        return(list(
          optimal_route = optimal_route,
          optimal_time = time_score[end_point],
          optimal_cost = cost_score[end_point],
          optimal_co2 = co2_score[end_point],
          path = path,
          route_metrics = graph_data
        ))
      }
      
      open_set <- open_set[-current_idx, ]
      
      # Voisins
      neighbors <- edge_list[edge_list$from == current, ]
      for (i in 1:nrow(neighbors)) {
        neighbor <- neighbors$to[i]
        tentative_g_score <- g_score[current] + neighbors$weight[i]
        
        if (tentative_g_score < g_score[neighbor]) {
          came_from[[neighbor]] <- current
          g_score[neighbor] <- tentative_g_score
          f_score[neighbor] <- g_score[neighbor] + heuristic(neighbor)
          
          time_score[neighbor] <- time_score[current] + neighbors$time[i]
          cost_score[neighbor] <- cost_score[current] + neighbors$cost[i]
          co2_score[neighbor] <- co2_score[current] + neighbors$co2[i]
          distance_score[neighbor] <- distance_score[current] + neighbors$distance[i]
          
          message("Mise à jour voisin : ", neighbor, ", g_score : ", g_score[neighbor], 
                  ", f_score : ", f_score[neighbor])
          
          if (!neighbor %in% open_set$node) {
            open_set <- rbind(open_set, data.frame(
              node = neighbor,
              g_score = g_score[neighbor],
              f_score = f_score[neighbor],
              stringsAsFactors = FALSE
            ))
          }
        }
      }
    }
    
    stop("Aucun chemin trouvé entre le point de départ et la destination.")
  }, error = function(e) {
    message("Erreur dans l'optimisation A* : ", e$message)
    return(NULL)
  })
}

# ---- UI for Simulation tab ----
simulation_ui <- tabItem(
  tabName = "simulation",
  fluidRow(
    box(
      title = "Paramètres de Simulation", status = "warning", solidHeader = TRUE, width = 4,
      selectInput("sim_departure_hour", "Plage horaire de départ:",
                  choices = setNames(
                    seq(6, 8.75, by = 0.25),
                    sprintf("%02d:%02d - %02d:%02d",
                            floor(seq(6, 8.75, by = 0.25)),
                            (seq(6, 8.75, by = 0.25) %% 1) * 60,
                            floor(seq(6.25, 9, by = 0.25)),
                            (seq(6.25, 9, by = 0.25) %% 1) * 60)
                  ),
                  selected = 7),
      selectInput("sim_vehicle_type", "Type de véhicule:",
                  choices = c("Berline", "SUV", "Citadine", "Minibus"), 
                  selected = "Berline"),
      selectInput("sim_start_point", "Point de départ:", 
                  choices = names(ZONES), selected = "Keur Massar"),
      selectInput("sim_end_point", "Destination:", 
                  choices = names(ZONES), selected = "Dakar Plateau"),
      sliderInput("weight_time", "Poids Temps:", min = 0, max = 1, value = 0.5, step = 0.1),
      sliderInput("weight_cost", "Poids Coût:", min = 0, max = 1, value = 0.3, step = 0.1),
      sliderInput("weight_co2", "Poids CO2:", min = 0, max = 1, value = 0.2, step = 0.1),
      selectInput("opt_algorithm", "Algorithme d'optimisation:",
                  choices = c("A*", "Dijkstra"), selected = "A*"),
      actionButton("run_simulation", "Lancer la Simulation", class = "btn-primary"),
      br(), br(),
      actionButton("algorithm_info", "Info sur l'Algorithme", class = "btn-info")
    ),
    box(
      title = "Résultats de la Simulation", status = "success", solidHeader = TRUE, width = 8,
      uiOutput("dijkstra_message"),
      fluidRow(
        valueBoxOutput("sim_route", width = 3),
        valueBoxOutput("sim_travel_time", width = 3),
        valueBoxOutput("sim_cost", width = 3),
        valueBoxOutput("sim_co2", width = 3)
      ),
      fluidRow(
        box(
          title = "Graphe du Chemin Optimal", status = "primary", solidHeader = TRUE, width = 6,
          visNetworkOutput("optimal_path_graph", height = "400px")
        ),
        box(
          title = "Carte Géographique", status = "primary", solidHeader = TRUE, width = 6,
          leafletOutput("sim_optimal_map", height = "400px")
        )
      ),
      fluidRow(
        box(
          title = "Chemin Complet", status = "info", solidHeader = TRUE, width = 12,
          verbatimTextOutput("full_path_text"),
          textOutput("model_usage_info")
        )
      ),
      fluidRow(
        box(
          title = "Comparaison des Routes (par rapport à la route optimale)", status = "info", solidHeader = TRUE, width = 12,
          DTOutput("route_comparison_table")
        )
      )
    )
  )
)

# ---- Server logic for Simulation tab ----
simulation_server <- function(input, output, session, worker_data, model_results) {
  simulation_results <- reactiveVal(NULL)
  
  observeEvent(input$run_simulation, {
    message("Lancement de la simulation...")
    
    # Valider les poids
    total_weight <- input$weight_time + input$weight_cost + input$weight_co2
    if (total_weight < 0.01) {
      showNotification("La somme des poids (Temps, Coût, CO2) ne peut pas être nulle.", type = "error")
      simulation_results(NULL)
      return()
    }
    
    if (input$opt_algorithm == "Dijkstra") {
      simulation_results(NULL)
      showNotification("L'algorithme Dijkstra est en cours d'implémentation.", type = "message")
      return()
    }
    
    data <- worker_data()
    results <- model_results()
    
    message("Lancement de simulate_travel_scenarios...")
    sim_results <- simulate_travel_scenarios(
      data, results$model, input$sim_departure_hour, input$sim_vehicle_type, 
      input$sim_start_point, input$sim_end_point
    )
    
    if (!is.null(sim_results) && nrow(sim_results$data) > 0) {
      message("Données simulées disponibles, nombre de lignes :", nrow(sim_results$data))
      weights <- c(
        time = input$weight_time,
        cost = input$weight_cost,
        co2 = input$weight_co2
      )
      weights <- weights / sum(weights) # Normalisation
      message("Poids utilisés : ", paste(names(weights), weights, sep = "=", collapse = ", "))
      
      opt_result <- optimize_route_astar(sim_results$data, input$sim_start_point, input$sim_end_point, weights)
      
      if (!is.null(opt_result)) {
        opt_result$use_model <- sim_results$use_model
        simulation_results(opt_result)
        showNotification("Simulation terminée avec succès !", type = "message")
        message("Simulation réussie, route optimale :", opt_result$optimal_route)
      } else {
        simulation_results(NULL)
        showNotification("Erreur lors de l'optimisation. Vérifiez les données.", type = "error")
        message("Erreur dans l'optimisation.")
      }
    } else {
      simulation_results(NULL)
      showNotification("Aucune donnée disponible pour ces critères. Essayez un autre type de véhicule ou plage horaire.", type = "warning")
      message("Aucune donnée simulée disponible.")
    }
  })
  
  output$dijkstra_message <- renderUI({
    if (input$opt_algorithm == "Dijkstra") {
      div(
        style = "text-align: center; color: #FF4500; font-size: 18px; padding: 20px;",
        "L'algorithme Dijkstra est en cours d'implémentation. Veuillez sélectionner A* pour voir les résultats."
      )
    } else {
      NULL
    }
  })
  
  output$sim_route <- renderValueBox({
    results <- simulation_results()
    valueBox(
      value = if (!is.null(results)) results$optimal_route else "N/A",
      subtitle = "Route Optimale",
      icon = icon("route"),
      color = "yellow",
      width = NULL
    )
  })
  
  output$sim_travel_time <- renderValueBox({
    results <- simulation_results()
    valueBox(
      value = if (!is.null(results)) paste(round(results$optimal_time, 1), "min") else "N/A",
      subtitle = "Temps Optimal",
      icon = icon("clock"),
      color = "blue",
      width = NULL
    )
  })
  
  output$sim_cost <- renderValueBox({
    results <- simulation_results()
    valueBox(
      value = if (!is.null(results)) paste(round(results$optimal_cost, 0), "FCFA") else "N/A",
      subtitle = "Coût Optimal",
      icon = icon("money-bill"),
      color = "green",
      width = NULL
    )
  })
  
  output$sim_co2 <- renderValueBox({
    results <- simulation_results()
    valueBox(
      value = if (!is.null(results)) paste(round(results$optimal_co2, 0), "g") else "N/A",
      subtitle = "Émissions CO2",
      icon = icon("leaf"),
      color = "purple",
      width = NULL
    )
  })
  
  output$optimal_path_graph <- renderVisNetwork({
    results <- simulation_results()
    if (!is.null(results) && input$opt_algorithm == "A*") {
      nodes <- data.frame(
        id = results$path,
        label = results$path,
        color = ifelse(results$path == results$optimal_route, "#FFD700", "#1F77B4"),
        shape = ifelse(results$path %in% c(input$sim_start_point, input$sim_end_point), "diamond", "circle"),
        size = ifelse(results$path %in% c(input$sim_start_point, input$sim_end_point), 30, 20),
        stringsAsFactors = FALSE
      )
      
      edges <- data.frame(
        from = results$path[1:(length(results$path)-1)],
        to = results$path[2:length(results$path)],
        color = "#FF4500",
        width = 3,
        arrows = "to",
        label = sprintf("Temps: %.1f min\nCoût: %.0f FCFA\nCO2: %.0f g", 
                        results$optimal_time, results$optimal_cost, results$optimal_co2),
        stringsAsFactors = FALSE
      )
      
      visNetwork(nodes, edges) %>%
        visOptions(highlightNearest = TRUE, nodesIdSelection = FALSE) %>%
        visLayout(randomSeed = 42) %>%
        visNodes(physics = FALSE) %>%
        visEdges(smooth = FALSE) %>%
        visInteraction(navigationButtons = TRUE)
    }
  })
  
  output$sim_optimal_map <- renderLeaflet({
    results <- simulation_results()
    data <- worker_data()
    
    if (!is.null(results) && input$opt_algorithm == "A*") {
      optimal_route <- results$optimal_route
      route_data <- data[data$route_selected == optimal_route, ][1, ]
      
      route_colors <- c("Route_A38_Autoroute" = "#1F77B4", "Route_Corniche" = "#2CA02C",
                        "Route_Rufisque" = "#D62728", "Route_Thiaroye" = "#FF7F0E",
                        "Route_Mixte" = "#9467BD")
      
      map <- leaflet() %>%
        addProviderTiles(providers$CartoDB.Positron) %>%
        setView(lng = mean(c(ZONES[[input$sim_start_point]]["lng"], ZONES[[input$sim_end_point]]["lng"])), 
                lat = mean(c(ZONES[[input$sim_start_point]]["lat"], ZONES[[input$sim_end_point]]["lat"])), 
                zoom = 12) %>%
        addMarkers(lng = ZONES[[input$sim_start_point]]["lng"], lat = ZONES[[input$sim_start_point]]["lat"],
                   popup = input$sim_start_point,
                   icon = leaflet::makeIcon("https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png", iconWidth = 25)) %>%
        addMarkers(lng = ZONES[[input$sim_end_point]]["lng"], lat = ZONES[[input$sim_end_point]]["lat"],
                   popup = input$sim_end_point,
                   icon = leaflet::makeIcon("https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png", iconWidth = 25)) %>%
        addPolylines(
          lng = c(route_data$start_lng, route_data$end_lng),
          lat = c(route_data$start_lat, route_data$end_lat),
          color = route_colors[optimal_route],
          weight = 6,
          opacity = 1,
          popup = paste(
            "<b>Route Optimale:</b>", optimal_route, "<br>",
            "<b>Temps:</b>", round(results$optimal_time, 1), "min<br>",
            "<b>Coût:</b>", round(results$optimal_cost, 0), "FCFA<br>",
            "<b>CO2:</b>", round(results$optimal_co2, 0), "g"
          )
        )
      
      map
    }
  })
  
  output$full_path_text <- renderPrint({
    results <- simulation_results()
    if (!is.null(results) && input$opt_algorithm == "A*") {
      cat("Chemin complet : ", paste(results$path, collapse = " → "), "\n")
    } else {
      cat("Aucun chemin disponible. Veuillez lancer la simulation avec l'algorithme A*.\n")
    }
  })
  
  output$model_usage_info <- renderText({
    results <- simulation_results()
    if (!is.null(results) && input$opt_algorithm == "A*") {
      if (results$use_model) {
        "Résultats basés sur les prédictions du modèle entraîné (onglet Modélisation)."
      } else {
        "Résultats basés sur les données brutes (aucun modèle entraîné disponible)."
      }
    } else {
      ""
    }
  })
  
  output$route_comparison_table <- renderDT({
    results <- simulation_results()
    if (!is.null(results) && input$opt_algorithm == "A*" && !is.null(results$route_metrics) && nrow(results$route_metrics) > 0) {
      # Vérification des NA
      if (any(is.na(results$route_metrics))) {
        message("NA détectés dans route_metrics : ", paste(colnames(results$route_metrics)[colSums(is.na(results$route_metrics)) > 0], collapse = ", "))
        return(datatable(data.frame(Message = "Données invalides : valeurs manquantes détectées"), 
                         options = list(dom = "t"), rownames = FALSE))
      }
      
      route_metrics <- results$route_metrics %>%
        mutate(
          Temps = round(time_weight, 1),
          Coût = round(cost_weight, 0),
          CO2 = round(co2_weight, 0),
          Distance = round(distance, 1),
          Qualité = route_quality,
          `Diff. Temps (min)` = round(time_weight - results$optimal_time, 1),
          `Diff. Coût (FCFA)` = round(cost_weight - results$optimal_cost, 0),
          `Diff. CO2 (g)` = round(co2_weight - results$optimal_co2, 0)
        ) %>%
        select(Route = route_selected, Temps, Coût, CO2, Distance, Qualité, 
               `Diff. Temps (min)`, `Diff. Coût (FCFA)`, `Diff. CO2 (g)`) %>%
        mutate(
          Route = ifelse(Route == results$optimal_route, paste0("<strong>", Route, "</strong>"), Route),
          `Diff. Temps (min)` = as.numeric(`Diff. Temps (min)`),
          `Diff. Coût (FCFA)` = as.numeric(`Diff. Coût (FCFA)`),
          `Diff. CO2 (g)` = as.numeric(`Diff. CO2 (g)`)
        )
      
      # Log des données pour débogage
      message("Données de route_metrics pour le tableau : ", paste(capture.output(print(route_metrics)), collapse = "\n"))
      
      datatable(
        route_metrics,
        escape = FALSE,
        options = list(
          pageLength = 5,
          dom = "tip", # Ajoute recherche et pagination
          autoWidth = TRUE,
          columnDefs = list(
            list(className = "dt-center", targets = "_all")
          )
        ),
        rownames = FALSE
      )
    } else {
      message("Aucune donnée pour le tableau de comparaison")
      return(datatable(data.frame(Message = "Aucune donnée disponible pour la comparaison des routes"), 
                       options = list(dom = "t"), rownames = FALSE))
    }
  })
  
  observeEvent(input$algorithm_info, {
    showModal(modalDialog(
      title = paste("Informations sur l'algorithme:", input$opt_algorithm),
      HTML(get_algorithm_description(input$opt_algorithm)),
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Fermer")
    ))
  })
}

# ---- Description des algorithmes ----
get_algorithm_description <- function(algorithm) {
  if (algorithm == "A*") {
    return(
      "<h4>Algorithme A*</h4>
       <p><b>Description:</b> A* est un algorithme de recherche de chemin optimal qui utilise une heuristique pour guider la recherche vers la destination, réduisant le nombre de nœuds explorés.</p>
       <p><b>Utilisation dans ce cas:</b> Trouve la route optimale en minimisant un coût combiné (temps, coût, CO2) entre un point de départ et une destination, en passant par une route intermédiaire.</p>
       <p><b>Avantages:</b> Plus rapide que Dijkstra dans les graphes avec une heuristique bien définie, car il explore moins de nœuds.</p>
       <p><b>Limitations:</b> Nécessite une heuristique admissible pour garantir l'optimalité. Moins efficace sans heuristique informative.</p>"
    )
  } else if (algorithm == "Dijkstra") {
    return(
      "<h4>Algorithme de Dijkstra</h4>
       <p><b>Description:</b> Dijkstra est en cours d'implémentation. Veuillez utiliser l'algorithme A* pour l'instant.</p>"
    )
  } else {
    return("<p>Algorithme non reconnu.</p>")
  }
}