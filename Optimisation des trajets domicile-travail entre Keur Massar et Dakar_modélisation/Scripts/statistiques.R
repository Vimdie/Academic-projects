# statistiques.R
# Logic for the Statistiques Descriptives tab

# ---- UI for Statistiques tab ----
statistiques_ui <- tabItem(
  tabName = "stats",
  fluidRow(
    box(
      title = "Base de Données des Travailleurs", status = "primary", solidHeader = TRUE, width = 12,
      DT::dataTableOutput("worker_database")
    )
  ),
  fluidRow(
    box(
      title = "Résumé des Données", status = "info", solidHeader = TRUE, width = 6,
      verbatimTextOutput("data_summary")
    ),
    box(
      title = "Contrôles de Données", status = "warning", solidHeader = TRUE, width = 6,
      actionButton("refresh_data", "Actualiser les Données", class = "btn-primary"),
      br(), br(),
      downloadButton("download_data", "Télécharger CSV", class = "btn-success"),
      br(), br(),
      numericInput("n_workers", "Nombre de travailleurs:", value = 200, min = 50, max = 1000)
    )
  ),
  fluidRow(
    box(
      title = "Analyse Temporelle", status = "primary", solidHeader = TRUE, width = 6,
      plotlyOutput("time_analysis", height = "400px"),
      p("Analyse des temps de trajet moyens par heure de départ, avec distinction des heures de pointe.")
    ),
    box(
      title = "Corrélation des Variables", status = "warning", solidHeader = TRUE, width = 6,
      plotOutput("correlation_plot", height = "400px"),
      p("Corrélations entre temps de trajet, congestion, distance et autres variables clés.")
    )
  ),
  fluidRow(
    box(
      title = "Distribution des Temps de Trajet", status = "info", solidHeader = TRUE, width = 6,
      plotlyOutput("travel_time_dist", height = "400px"),
      p("Histogramme des temps de trajet avec médiane et moyenne.")
    ),
    box(
      title = "Analyse par Route et Véhicule", status = "success", solidHeader = TRUE, width = 6,
      plotlyOutput("route_vehicle_analysis", height = "400px"),
      p("Comparaison des temps de trajet par route et type de véhicule.")
    )
  ),
  fluidRow(
    box(
      title = "Indicateurs Clés", status = "primary", solidHeader = TRUE, width = 12,
      valueBoxOutput("avg_travel_time"),
      valueBoxOutput("optimal_route"),
      valueBoxOutput("congestion_impact"),
      valueBoxOutput("avg_cost")
    )
  )
)

# ---- Server logic for Statistiques tab ----
statistiques_server <- function(input, output, session, worker_data) {
  output$worker_database <- DT::renderDataTable({
    data <- worker_data()
    DT::datatable(
      data, 
      options = list(scrollX = TRUE, pageLength = 15),
      filter = "top",
      rownames = FALSE
    )
  })
  
  output$data_summary <- renderPrint({
    data <- worker_data()
    summary(data[, c("travel_time", "congestion_time", "route_length", 
                     "traffic_volume", "congestion_density", "travel_cost", "co2_emission")])
  })
  
  output$download_data <- downloadHandler(
    filename = function() {
      paste0("trajets_dakar_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(worker_data(), file, row.names = FALSE)
    }
  )
  
  output$time_analysis <- renderPlotly({
    data <- worker_data()
    data$departure_hour <- as.numeric(format(data$departure_time, "%H")) + 
      as.numeric(format(data$departure_time, "%M"))/60
    
    time_summary <- data %>%
      group_by(departure_hour = round(departure_hour, 1), route_selected) %>%
      summarise(avg_travel_time = mean(travel_time, na.rm = TRUE), .groups = "drop")
    
    p <- ggplot(time_summary, aes(x = departure_hour, y = avg_travel_time, 
                                  color = route_selected, group = route_selected)) +
      geom_line(size = 1.2) +
      geom_point(size = 2.5) +
      scale_color_manual(values = c("Route_A38_Autoroute" = "#1F77B4", "Route_Corniche" = "#2CA02C",
                                    "Route_Rufisque" = "#D62728", "Route_Thiaroye" = "#FF7F0E",
                                    "Route_Mixte" = "#9467BD")) +
      labs(title = "Temps de Trajet par Heure et Route",
           x = "Heure de Départ", y = "Temps Moyen (min)") +
      theme_minimal(base_size = 12) +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold"),
        legend.title = element_text(face = "bold")
      )
    
    ggplotly(p, tooltip = c("x", "y", "route_selected"))
  })
  
  output$correlation_plot <- renderPlot({
    data <- worker_data()
    numeric_data <- data %>%
      select(travel_time, congestion_time, route_length, traffic_volume, 
             congestion_density, fuel_consumption, travel_cost, co2_emission)
    
    cor_matrix <- cor(numeric_data, use = "complete.obs")
    corrplot::corrplot(
      cor_matrix, method = "color", type = "upper", 
      order = "hclust", tl.cex = 0.9, tl.col = "black", 
      col = colorRampPalette(c("#D62728", "#FFFFFF", "#2CA02C"))(200),
      addCoef.col = "black", number.cex = 0.7
    )
  })
  
  output$travel_time_dist <- renderPlotly({
    data <- worker_data()
    
    p <- ggplot(data, aes(x = travel_time, fill = route_selected)) +
      geom_histogram(binwidth = 3, alpha = 0.7, position = "dodge") +
      geom_vline(aes(xintercept = mean(travel_time, na.rm = TRUE)), color = "black", linetype = "dashed", size = 1) +
      geom_vline(aes(xintercept = median(travel_time, na.rm = TRUE)), color = "blue", linetype = "dotted", size = 1) +
      scale_fill_manual(values = c("Route_A38_Autoroute" = "#1F77B4", "Route_Corniche" = "#2CA02C",
                                   "Route_Rufisque" = "#D62728", "Route_Thiaroye" = "#FF7F0E",
                                   "Route_Mixte" = "#9467BD")) +
      labs(title = "Distribution des Temps de Trajet par Route",
           x = "Temps de Trajet (min)", y = "Fréquence") +
      theme_minimal(base_size = 12) +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold"),
        legend.title = element_text(face = "bold")
      )
    
    ggplotly(p, tooltip = c("x", "count", "route_selected"))
  })
  
  output$route_vehicle_analysis <- renderPlotly({
    data <- worker_data()
    
    p <- ggplot(data, aes(x = route_selected, y = travel_time, fill = vehicle_type)) +
      geom_boxplot(alpha = 0.7) +
      scale_fill_manual(values = c("Berline" = "#1F77B4", "SUV" = "#FF7F0E", 
                                   "Citadine" = "#2CA02C", "Minibus" = "#D62728")) +
      labs(title = "Temps de Trajet par Route et Type de Véhicule",
           x = "Route", y = "Temps de Trajet (min)") +
      theme_minimal(base_size = 12) +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(hjust = 0.5, face = "bold"),
        legend.title = element_text(face = "bold")
      )
    
    ggplotly(p, tooltip = c("x", "y", "vehicle_type"))
  })
  
  output$avg_travel_time <- renderValueBox({
    data <- worker_data()
    avg_time <- round(mean(data$travel_time, na.rm = TRUE), 1)
    valueBox(
      value = as.character(avg_time),
      subtitle = "Temps Moyen de Trajet",
      icon = icon("clock"),
      color = "blue"
    )
  })
  
  output$optimal_route <- renderValueBox({
    data <- worker_data()
    optimal <- data %>%
      group_by(route_selected) %>%
      summarise(avg_time = mean(travel_time, na.rm = TRUE)) %>%
      arrange(avg_time) %>%
      slice(1)
    
    valueBox(
      value = as.character(optimal$route_selected),
      subtitle = paste0("Route Optimale (", round(optimal$avg_time, 1), " min)"),
      icon = icon("route"),
      color = "green"
    )
  })
  
  output$congestion_impact <- renderValueBox({
    data <- worker_data()
    congestion_pct <- round(mean(data$congestion_time, na.rm = TRUE) / mean(data$travel_time, na.rm = TRUE) * 100, 1)
    
    valueBox(
      value = as.character(congestion_pct),
      subtitle = "Impact de la Congestion",
      icon = icon("traffic-light"),
      color = "red"
    )
  })
  
  output$avg_cost <- renderValueBox({
    data <- worker_data()
    avg_cost <- round(mean(data$travel_cost, na.rm = TRUE), 0)
    valueBox(
      value = as.character(avg_cost),
      subtitle = "Coût Moyen du Trajet",
      icon = icon("money-bill"),
      color = "purple"
    )
  })
  
  output$optimization_results <- renderPrint({
    data <- worker_data()
    route_analysis <- data %>%
      group_by(route_selected) %>%
      summarise(
        avg_time = mean(travel_time, na.rm = TRUE),
        avg_congestion = mean(congestion_time, na.rm = TRUE),
        avg_cost = mean(travel_cost, na.rm = TRUE),
        count = n(),
        route_quality = first(route_quality)
      ) %>%
      arrange(avg_time)
    
    cat("RECOMMANDATIONS D'OPTIMISATION:\n\n")
    cat("1. Route la plus rapide:", route_analysis$route_selected[1], 
        "(", round(route_analysis$avg_time[1], 1), " min, Qualité:", route_analysis$route_quality[1], ")\n")
    cat("2. Route la moins congestionnée:", 
        route_analysis$route_selected[which.min(route_analysis$avg_congestion)], 
        "(", round(route_analysis$avg_congestion[which.min(route_analysis$avg_congestion)], 1), " min)\n")
    cat("3. Route la moins coûteuse:", 
        route_analysis$route_selected[which.min(route_analysis$avg_cost)], 
        "(", round(route_analysis$avg_cost[which.min(route_analysis$avg_cost)], 0), " FCFA)\n")
    cat("\nAXES D'AMÉLIORATION:\n")
    cat("- Réduire la congestion sur", route_analysis$route_selected[which.max(route_analysis$avg_congestion)], "\n")
    cat("- Optimiser les feux de circulation sur les routes secondaires\n")
    cat("- Encourager l'étalement des heures de départ avant 7h ou après 8h30\n")
  })
}