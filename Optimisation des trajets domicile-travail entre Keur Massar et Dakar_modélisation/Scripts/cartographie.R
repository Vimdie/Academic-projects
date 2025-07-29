# cartographie.R
# Logic for the Cartographie tab

# ---- UI for Cartographie tab ----
cartographie_ui <- tabItem(
  tabName = "map",
  fluidRow(
    box(
      title = "Entrées Utilisateur", status = "info", solidHeader = TRUE, width = 4,
      selectInput("start_point", "Point de départ:", 
                  choices = names(ZONES), selected = "Keur Massar"),
      selectInput("end_point", "Destination:", 
                  choices = names(ZONES), selected = "Dakar Plateau"),
      actionButton("update_map", "Actualiser la Carte", class = "btn-primary")
    ),
    box(
      title = "Carte Interactive des Trajets",
      status = "primary", solidHeader = TRUE, width = 8,
      leafletOutput("interactive_map", height = "600px")
    )
  )
)

# ---- Server logic for Cartographie tab ----
cartographie_server <- function(input, output, session, worker_data) {
  output$interactive_map <- renderLeaflet({
    data <- worker_data()
    
    routes_to_show <- sample(unique(data$route_selected), min(5, length(unique(data$route_selected))))
    data <- data[data$route_selected %in% routes_to_show, ]
    
    data <- data %>%
      group_by(route_selected) %>%
      slice_head(n = 1) %>%
      ungroup()
    
    route_colors <- c("Route_A38_Autoroute" = "#1F77B4", "Route_Corniche" = "#2CA02C",
                      "Route_Rufisque" = "#D62728", "Route_Thiaroye" = "#FF7F0E",
                      "Route_Mixte" = "#9467BD")
    
    map <- leaflet(data) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = mean(c(ZONES[[input$start_point]]["lng"], ZONES[[input$end_point]]["lng"])), 
              lat = mean(c(ZONES[[input$start_point]]["lat"], ZONES[[input$end_point]]["lat"])), 
              zoom = 12) %>%
      addMarkers(lng = ZONES[[input$start_point]]["lng"], lat = ZONES[[input$start_point]]["lat"],
                 popup = input$start_point, 
                 icon = leaflet::makeIcon("https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png", iconWidth = 25)) %>%
      addMarkers(lng = ZONES[[input$end_point]]["lng"], lat = ZONES[[input$end_point]]["lat"],
                 popup = input$end_point, 
                 icon = leaflet::makeIcon("https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png", iconWidth = 25))
    
    for (i in 1:nrow(data)) {
      map <- map %>%
        addPolylines(
          lng = c(data$start_lng[i], data$end_lng[i]),
          lat = c(data$start_lat[i], data$end_lat[i]),
          color = route_colors[data$route_selected[i]],
          weight = 4,
          opacity = 0.8,
          popup = paste(
            "<b>Travailleur:</b>", data$worker_id[i], "<br>",
            "<b>Route:</b>", data$route_selected[i], "<br>",
            "<b>Temps:</b>", data$travel_time[i], "min<br>",
            "<b>Congestion:</b>", data$congestion_time[i], "min<br>",
            "<b>Coût:</b>", data$travel_cost[i], "FCFA"
          )
        )
    }
    
    map
  })
  
  observeEvent(input$update_map, {
    output$interactive_map <- renderLeaflet({
      data <- worker_data()
      
      routes_to_show <- sample(unique(data$route_selected), min(5, length(unique(data$route_selected))))
      data <- data[data$route_selected %in% routes_to_show, ]
      
      data <- data %>%
        group_by(route_selected) %>%
        slice_head(n = 1) %>%
        ungroup()
      
      route_colors <- c("Route_A38_Autoroute" = "#1F77B4", "Route_Corniche" = "#2CA02C",
                        "Route_Rufisque" = "#D62728", "Route_Thiaroye" = "#FF7F0E",
                        "Route_Mixte" = "#9467BD")
      
      map <- leaflet(data) %>%
        addProviderTiles(providers$CartoDB.Positron) %>%
        setView(lng = mean(c(ZONES[[input$start_point]]["lng"], ZONES[[input$end_point]]["lng"])), 
                lat = mean(c(ZONES[[input$start_point]]["lat"], ZONES[[input$end_point]]["lat"])), 
                zoom = 12) %>%
        addMarkers(lng = ZONES[[input$start_point]]["lng"], lat = ZONES[[input$start_point]]["lat"],
                   popup = input$start_point, 
                   icon = leaflet::makeIcon("https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png", iconWidth = 25)) %>%
        addMarkers(lng = ZONES[[input$end_point]]["lng"], lat = ZONES[[input$end_point]]["lat"],
                   popup = input$end_point, 
                   icon = leaflet::makeIcon("https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png", iconWidth = 25))
      
      for (i in 1:nrow(data)) {
        map <- map %>%
          addPolylines(
            lng = c(data$start_lng[i], data$end_lng[i]),
            lat = c(data$start_lat[i], data$end_lat[i]),
            color = route_colors[data$route_selected[i]],
            weight = 4,
            opacity = 0.8,
            popup = paste(
              "<b>Travailleur:</b>", data$worker_id[i], "<br>",
              "<b>Route:</b>", data$route_selected[i], "<br>",
              "<b>Temps:</b>", data$travel_time[i], "min<br>",
              "<b>Congestion:</b>", data$congestion_time[i], "min<br>",
              "<b>Coût:</b>", data$travel_cost[i], "FCFA"
            )
          )
      }
      
      map
    })
  })
}