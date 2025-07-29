
# app.R
# Main Shiny application file to define UI and launch server

source("global.R")
source("cartographie.R")
source("statistiques.R")
source("modelisation.R")
source("simulation.R")

# ---- Interface utilisateur (UI) ----
ui <- dashboardPage(
  dashboardHeader(title = "Optimisation Trajets à Dakar"),
  dashboardSidebar(
    sidebarMenu(
      id = "sidebar",
      menuItem("Cartographie", tabName = "map", icon = icon("map"), selected = TRUE),
      menuItem("Statistiques Descriptives", tabName = "stats", icon = icon("chart-bar")),
      menuItem("Modélisation", tabName = "modeling", icon = icon("brain")),
      menuItem("Simulation", tabName = "simulation", icon = icon("chart-line"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .modal-lg { width: 80%; max-width: 900px; }
        .modal-body { font-size: 14px; }
        .modal-body h4 { color: #1F77B4; }
        .modal-body p { margin-bottom: 10px; }
        .value-box { 
          height: 120px; 
          box-shadow: 0 4px 8px rgba(0,0,0,0.1); 
          transition: transform 0.2s; 
          border-radius: 8px; 
          display: flex; 
          align-items: center; 
          justify-content: center; 
          font-size: 16px; 
        }
        .value-box .inner { text-align: center; }
        .value-box:hover { transform: scale(1.05); }
        .box { 
          border-radius: 8px; 
          box-shadow: 0 4px 12px rgba(0,0,0,0.15); 
        }
        .btn-primary { 
          background-color: #1F77B4; 
          border-color: #1F77B4; 
        }
        .btn-primary:hover { 
          background-color: #155A8A; 
          border-color: #155A8A; 
        }
        .btn-info { 
          background-color: #17A2B8; 
          border-color: #17A2B8; 
        }
        .btn-info:hover { 
          background-color: #117A8B; 
          border-color: #117A8B; 
        }
      "))
    ),
    tabItems(
      cartographie_ui,
      statistiques_ui,
      modelisation_ui,
      simulation_ui
    )
  )
)

# ---- Serveur Shiny ----
server <- function(input, output, session) {
  worker_data <- reactive({
    message("Initialisation de worker_data...")
    n_workers <- if (is.null(input$n_workers)) 200 else input$n_workers
    start_point <- if (is.null(input$start_point)) "Keur Massar" else input$start_point
    end_point <- if (is.null(input$end_point)) "Dakar Plateau" else input$end_point
    generate_realistic_data(n_workers, start_point, end_point)
  })
  
  model_trained <- reactiveVal(FALSE)
  model_results <- reactiveVal(NULL)
  
  observeEvent(input$refresh_data, {
    worker_data <<- reactive({
      n_workers <- if (is.null(input$n_workers)) 200 else input$n_workers
      start_point <- if (is.null(input$start_point)) "Keur Massar" else input$start_point
      end_point <- if (is.null(input$end_point)) "Dakar Plateau" else input$end_point
      generate_realistic_data(n_workers, start_point, end_point)
    })
    model_trained(FALSE)
    model_results(NULL)
    showNotification("Données actualisées. Veuillez réentraîner le modèle si nécessaire.", type = "message")
    message("Données actualisées, model_trained réinitialisé à FALSE")
  })
  
  cartographie_server(input, output, session, worker_data)
  statistiques_server(input, output, session, worker_data)
  modelisation_server(input, output, session, worker_data, model_trained, model_results)
  simulation_server(input, output, session, worker_data, model_results)
}

# ---- Lancement de l'application Shiny ----
shinyApp(ui = ui, server = server)
