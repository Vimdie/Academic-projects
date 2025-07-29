# modelisation.R
# Logic for the Modélisation tab and modeling functions

# ---- Modeling functions ----
train_and_evaluate_model <- function(data, model_type, train_split) {
  tryCatch({
    required_cols <- c("travel_time", "congestion_time", "route_length", 
                       "traffic_volume", "congestion_density", 
                       "fuel_consumption", "route_selected", 
                       "vehicle_type", "departure_hour")
    
    if (nrow(data) == 0) {
      stop("Les données sont vides (aucune ligne).")
    }
    
    missing_cols <- setdiff(required_cols, names(data))
    if (length(missing_cols) > 0) {
      stop(paste("Colonnes manquantes :", paste(missing_cols, collapse = ", ")))
    }
    
    numeric_cols <- c("travel_time", "congestion_time", "route_length", 
                      "traffic_volume", "congestion_density", "fuel_consumption", "departure_hour")
    for (col in numeric_cols) {
      if (!is.numeric(data[[col]])) {
        stop(paste("La colonne", col, "doit être numérique."))
      }
      if (anyNA(data[[col]])) {
        message(paste("Valeurs NA détectées dans", col, ":", sum(is.na(data[[col]])), "lignes"))
      }
    }
    
    model_data <- data %>%
      select(travel_time, congestion_time, route_length, traffic_volume, 
             congestion_density, fuel_consumption, route_selected, vehicle_type, 
             departure_hour) %>%
      na.omit()
    
    if (nrow(model_data) < 10) {
      stop(paste("Trop peu de données après suppression des NA :", nrow(model_data), "lignes restantes."))
    }
    
    if (length(unique(model_data$route_selected)) < 2) {
      stop("La variable route_selected doit avoir au moins 2 niveaux distincts.")
    }
    if (length(unique(model_data$vehicle_type)) < 2) {
      stop("La variable vehicle_type doit avoir au moins 2 niveaux distincts.")
    }
    
    model_data$route_selected <- as.factor(model_data$route_selected)
    model_data$vehicle_type <- as.factor(model_data$vehicle_type)
    
    set.seed(42)
    train_idx <- createDataPartition(model_data$travel_time, p = train_split, list = FALSE)
    train_data <- model_data[train_idx, ]
    test_data <- model_data[-train_idx, ]
    
    if (nrow(train_data) < 5) {
      stop(paste("Trop peu de données pour l'entraînement :", nrow(train_data), "lignes."))
    }
    if (nrow(test_data) < 5) {
      stop(paste("Trop peu de données pour le test :", nrow(test_data), "lignes."))
    }
    
    message("Résumé des données avant entraînement :")
    message("Nombre de lignes :", nrow(model_data))
    message("Colonnes :", paste(names(model_data), collapse = ", "))
    message("Niveaux de route_selected :", paste(levels(model_data$route_selected), collapse = ", "))
    message("Niveaux de vehicle_type :", paste(levels(model_data$vehicle_type), collapse = ", "))
    
    ctrl <- trainControl(method = "cv", number = 5, verboseIter = FALSE)
    
    model <- NULL
    if (model_type == "Random Forest") {
      model <- train(
        travel_time ~ ., data = train_data, method = "rf",
        trControl = ctrl, tuneLength = 2, ntree = 50
      )
    } else if (model_type == "Régression Linéaire") {
      model <- train(
        travel_time ~ ., data = train_data, method = "lm",
        trControl = ctrl
      )
    } else if (model_type == "SVM") {
      model <- train(
        travel_time ~ ., data = train_data, method = "svmRadial",
        trControl = ctrl, tuneLength = 2, 
        tuneGrid = expand.grid(sigma = c(0.1, 0.5), C = c(1, 10))
      )
    } else {
      stop("Modèle non supporté. Choisissez 'Random Forest', 'Régression Linéaire' ou 'SVM'.")
    }
    
    predictions <- predict(model, test_data)
    
    rmse <- sqrt(mean((test_data$travel_time - predictions)^2, na.rm = TRUE))
    mae <- mean(abs(test_data$travel_time - predictions), na.rm = TRUE)
    r2 <- cor(test_data$travel_time, predictions, use = "complete.obs")^2
    
    return(list(
      model = model,
      predictions = predictions,
      actual = test_data$travel_time,
      rmse = rmse,
      mae = mae,
      r2 = r2,
      trainingData = train_data
    ))
  }, error = function(e) {
    message("Erreur lors de l'entraînement du modèle : ", e$message)
    return(NULL)
  })
}

render_model_summary <- function(results, model_type) {
  if (!is.null(results)) {
    if (model_type == "Random Forest") {
      print(results$model)
    } else if (model_type == "Régression Linéaire") {
      summary(results$model)
    } else if (model_type == "SVM") {
      print(results$model)
    }
  } else {
    cat("Erreur lors de l'entraînement ou aucun modèle entraîvé. Vérifiez les données et réessayez.")
  }
}

render_model_performance <- function(results) {
  if (!is.null(results)) {
    cat("RMSE:", round(results$rmse, 2), "min\n")
    cat("MAE:", round(results$mae, 2), "min\n")
    cat("R²:", round(results$r2, 3), "\n")
  } else {
    cat("Aucune performance disponible. Entraînez d'abord un modèle.")
  }
}

render_model_predictions <- function(results) {
  if (!is.null(results)) {
    pred_data <- data.frame(
      Actual = results$actual,
      Predicted = results$predictions
    )
    
    p <- ggplot(pred_data, aes(x = Actual, y = Predicted)) +
      geom_point(alpha = 0.6, color = "#1F77B4") +
      geom_abline(intercept = 0, slope = 1, color = "#D62728", linetype = "dashed") +
      labs(title = "Prédictions vs Valeurs Réelles",
           x = "Temps Réel (min)", y = "Temps Prédit (min)") +
      theme_minimal(base_size = 12) +
      theme(plot.title = element_text(hjust = 0.5, face = "bold"))
    
    ggplotly(p, tooltip = c("x", "y"))
  }
}

get_model_description <- function(model_type) {
  if (model_type == "Random Forest") {
    return(
      "<h4>Random Forest</h4>
       <p><b>Description:</b> Random Forest est un algorithme d'apprentissage supervisé basé sur l'agrégation de multiples arbres de décision. Chaque arbre est construit sur un sous-ensemble aléatoire des données et des variables, ce qui réduit le surajustement et améliore la robustesse.</p>
       <p><b>Utilisation dans ce cas:</b> Prédit le temps de trajet en utilisant des variables comme la longueur de la route, la congestion, et l'heure de départ. Les arbres capturent les interactions complexes entre ces variables.</p>
       <p><b>Avantages:</b> Gère bien les variables catégorielles, robuste aux valeurs aberrantes, et capture les non-linéarités.</p>
       <p><b>Limitations:</b> Peut être lent sur de grandes bases de données et moins interprétable que les modèles linéaires.</p>"
    )
  } else if (model_type == "Régression Linéaire") {
    return(
      "<h4>Régression Linéaire</h4>
       <p><b>Description:</b> La régression linéaire modélise la relation entre la variable cible (temps de trajet) et les prédicteurs comme une combinaison linéaire.</p>
       <p><b>Utilisation dans ce cas:</b> Prédit le temps de trajet en supposant une relation linéaire avec des variables comme la longueur de la route et la congestion.</p>
       <p><b>Avantages:</b> Simple, rapide, et facile à interpréter. Les coefficients indiquent l'impact de chaque variable.</p>
       <p><b>Limitations:</b> Ne capture pas les relations non linéaires ou les interactions complexes entre variables.</p>"
    )
  } else if (model_type == "SVM") {
    return(
      "<h4>Support Vector Machine (SVM)</h4>
       <p><b>Description:</b> SVM utilise un noyau (ici radial) pour transformer les données dans un espace de dimension supérieure, où une frontière de décision optimale est trouvée.</p>
       <p><b>Utilisation dans ce cas:</b> Prédit le temps de trajet en capturant des relations non linéaires entre les variables comme la congestion et l'heure de départ.</p>
       <p><b>Avantages:</b> Efficace pour les données non linéaires et robuste avec des données bruitées.</p>
       <p><b>Limitations:</b> Sensible au choix du noyau et aux hyperparamètres. Moins interprétable.</p>"
    )
  } else {
    return("<p>Modèle non reconnu.</p>")
  }
}

# ---- UI for Modélisation tab ----
modelisation_ui <- tabItem(
  tabName = "modeling",
  fluidRow(
    box(
      title = "Modélisation Prédictive", status = "primary", solidHeader = TRUE, width = 8,
      h4("Modèle de Prédiction du Temps de Trajet"),
      verbatimTextOutput("model_summary"),
      br(),
      plotlyOutput("model_predictions", height = "400px")
    ),
    box(
      title = "Paramètres du Modèle", status = "info", solidHeader = TRUE, width = 4,
      selectInput("model_type", "Type de Modèle:",
                  choices = c("Random Forest", "Régression Linéaire", "SVM"),
                  selected = "Random Forest"),
      sliderInput("train_split", "Proportion d'entraînement:",
                  min = 0.6, max = 0.9, value = 0.8, step = 0.1),
      actionButton("train_model", "Entraîner le Modèle", class = "btn-primary"),
      br(), br(),
      actionButton("model_info", "Info sur le Modèle", class = "btn-info")
    )
  ),
  fluidRow(
    box(
      title = "Performance du Modèle", status = "success", solidHeader = TRUE, width = 12,
      verbatimTextOutput("model_performance")
    )
  )
)

# ---- Server logic for Modélisation tab ----
modelisation_server <- function(input, output, session, worker_data, model_trained, model_results) {
  observeEvent(input$train_model, {
    data <- worker_data()
    message("Lancement de l'entraînement pour le modèle :", input$model_type)
    results <- train_and_evaluate_model(data, input$model_type, input$train_split)
    if (!is.null(results)) {
      model_results(results)
      model_trained(TRUE)
      showNotification("Modèle entraîné avec succès !", type = "message")
      message("model_trained défini à TRUE")
    } else {
      model_results(NULL)
      model_trained(FALSE)
      showNotification("Erreur lors de l'entraînement du modèle. Vérifiez les données.", type = "error")
      message("model_trained défini à FALSE")
    }
  })
  
  output$model_summary <- renderPrint({
    render_model_summary(model_results(), input$model_type)
  })
  
  output$model_performance <- renderPrint({
    render_model_performance(model_results())
  })
  
  output$model_predictions <- renderPlotly({
    render_model_predictions(model_results())
  })
  
  observeEvent(input$model_info, {
    showModal(modalDialog(
      title = paste("Informations sur le modèle:", input$model_type),
      HTML(get_model_description(input$model_type)),
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Fermer")
    ))
  })
}