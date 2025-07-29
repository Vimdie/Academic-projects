# 03_solution_partielle.R

if (!requireNamespace("shiny", quietly = TRUE)) install.packages("shiny")
if (!requireNamespace("bslib", quietly = TRUE)) install.packages("bslib")
if (!requireNamespace("fontawesome", quietly = TRUE)) install.packages("fontawesome")

library(shiny)
library(bslib)
library(fontawesome)

ui <- fluidPage(
  theme = bs_theme(
    version    = 4,
    bootswatch = "flatly",
    primary    = "#003366",
    secondary  = "#9ecae1",
    base_font  = font_google("Montserrat")
  ),
  
  tags$style(HTML("
    .form-section { margin-top: 30px; }
    .form-header { color: #003366; border-bottom: 2px solid #9ecae1; padding-bottom: 5px; margin-bottom: 15px; }
    .well-panel { background: #f9f9f9; border-radius: 8px; padding: 20px; }
    .submit-btn { margin-top: 20px; }
  ")),
  
  # Logos & titre
  fluidRow(
    column(6, tags$img(src = "ANSD.jpg", height = "80px")),
    column(6, align = "right", tags$img(src = "ENSAE.png", height = "80px"))
  ),
  titlePanel("Questionnaire – Choix des séries scientifiques (Version améliorée)"),
  
  # Onglets
  tabsetPanel(
    id   = "main_tabs",
    type = "tabs",
    
    # -- SECTION I --
    tabPanel(
      title = tagList(icon("id-card"), "Identification"),
      div(class = "form-section",
          h3(class = "form-header", icon("user"), "SECTION I – Informations & Identification"),
          div(class = "well-panel",
              
              textInput("ia", "IA", value = ""),
              textInput("ief", "IEF", value = ""),
              textInput("etablissement", "Établissement scolaire", value = ""),
              
              # Type d’établissement : on remplace le "" par un texte plus explicite
              radioButtons(
                inputId  = "type_etab",
                label    = "Type d’établissement",
                choices  = c("Public", "Privé"),
                selected = character(0) # pas de choix coché par défaut
              ),
              
              textInput("superviseur", "Nom du superviseur", value = ""),
              textInput("enqueteur",   "Nom de l’enquêteur", value = ""),
              textInput("num_questionnaire", "Numéro du questionnaire", value = ""),
              
              dateInput(
                inputId = "date_interview",
                label   = "Date de l'interview",
                value   = NULL,
                format  = "dd/mm/yyyy"
              ),
              textInput("heure_debut", "Heure de début (hh:mm)", placeholder = "hh:mm"),
              numericInput("longitude", "Longitude", value = NA, step = 0.000001),
              numericInput("latitude",  "Latitude",  value = NA, step = 0.000001),
              textAreaInput("observations", "Observations du superviseur", rows = 3, placeholder = "..."),
              
              # Sexe : on retire "" et on met selected=character(0)
              radioButtons(
                inputId  = "sexe",
                label    = "Sexe",
                choices  = c("Homme", "Femme"),
                selected = character(0)
              ),
              
              # Âge : on garde un "" car c'est un selectInput, 
              # ainsi l'utilisateur peut voir un choix vide initial
              selectInput(
                inputId  = "age",
                label    = "Âge",
                choices  = c("", "< 13 ans", "[13;15[", "[15;17]", "> 17 ans"),
                selected = ""
              ),
              
              # Nationalité sénégalaise : idem, on enlève le "" 
              # car c'est un radioButtons
              radioButtons(
                inputId  = "nationalite_sn",
                label    = "Nationalité sénégalaise ?",
                choices  = c("Oui", "Non"),
                selected = character(0)
              ),
              
              conditionalPanel(
                condition = "input.nationalite_sn == 'Non'",
                selectInput(
                  "autre_nationalite", 
                  "Si non, quelle est ta nationalité ?", 
                  choices  = c("", "Guinéenne", "Malienne", "Mauritanienne", "Gambienne", "Autre"),
                  selected = ""
                ),
                selectInput(
                  "temps_senegal", 
                  "Depuis combien de temps es-tu au Sénégal ?",
                  choices  = c("", "Moins de 6 mois", "6–12 mois", "1–3 ans", "3 ans et plus", "Ne sais pas"),
                  selected = ""
                )
              )
          )
      )
    ),
    
    # -- SECTION II --
    tabPanel(
      title = tagList(icon("graduation-cap"), "Profil académique"),
      div(class = "form-section",
          h3(class = "form-header", icon("book"), "SECTION II – Profil académique"),
          div(class = "well-panel",
              selectInput(
                "moyenne_4e", 
                "II‑1 Moyenne en sciences (4e)",
                choices  = c("", "< 12/20", "[12;15[", "> 15/20"),
                selected = ""
              ),
              selectInput(
                "moyenne_3e", 
                "II‑2 Moyenne sciences (3e S1)",
                choices  = c("", "< 10", "[10;12[", "[12;14[", "[14;16[", "[16;20]"),
                selected = ""
              ),
              radioButtons(
                "niveau_science", 
                "II‑3 Niveau perçu",
                choices  = c("Excellent", "Bon", "Moyen", "Faible"),
                selected = character(0)
              ),
              radioButtons(
                "revision_science",
                "II‑4 Heures de révision/semaine",
                choices  = c("< 2h", "2–4h", "4–6h", "> 6h"),
                selected = character(0)
              ),
              radioButtons(
                "livres", 
                "II‑5 Livres au programme ?",
                choices  = c("Oui", "Non"),
                selected = character(0)
              ),
              radioButtons(
                "ressources", 
                "II‑7 Autres ressources ?",
                choices  = c("Oui", "Non"),
                selected = character(0)
              ),
              radioButtons(
                "difficulte", 
                "II‑8 Difficulté des sciences",
                choices  = c("Facile", "Modéré", "Difficile", "Très difficile"),
                selected = character(0)
              ),
              selectInput(
                "influence_notes", 
                "II‑9 Facteur positif de notes",
                choices  = c("", "Ressources pédagogiques", "Investissement personnel", "Difficultés d’adaptation"),
                selected = ""
              ),
              selectInput(
                "activite_pref", 
                "II‑10 Activité préférée",
                choices  = c("", "Vidéos et documentaires", "Lecture et écriture", "Résolution de problèmes", 
                             "Apprentissage des langues", "Autre"),
                selected = ""
              ),
              selectInput(
                "utilite_science",
                "II‑11 Utilité perçue",
                choices  = c("", "Très utile", "Utile", "Peu utile", "Inutile"),
                selected = ""
              ),
              selectInput(
                "importance_ecole",
                "II‑12 Importance de l'école",
                choices  = c("", "Très importante", "Importante", "Moyenne", "Faible"),
                selected = ""
              ),
              
              # Bouton soumission
              actionButton("submit", "Soumettre mes réponses", class = "btn btn-primary submit-btn")
          )
      )
    )
  ),
  
  # Affichage des résultats
  verbatimTextOutput("result")
)

# ==== SERVER ====
server <- function(input, output, session) {
  observeEvent(input$submit, {
    # Vérification des champs obligatoires
    required_fields <- list(
      IA           = input$ia,
      IEF          = input$ief,
      Etablissement= input$etablissement,
      TypeEtab     = input$type_etab,
      Superviseur  = input$superviseur,
      Enqueteur    = input$enqueteur,
      NumQuest     = input$num_questionnaire,
      DateInt      = input$date_interview,
      HeureDebut   = input$heure_debut,
      Long         = input$longitude,
      Lat          = input$latitude,
      Obs          = input$observations,
      Sexe         = input$sexe,
      Age          = input$age,
      NatSN        = input$nationalite_sn,
      Moy4e        = input$moyenne_4e,
      Moy3e        = input$moyenne_3e,
      Niveau       = input$niveau_science,
      Revision     = input$revision_science,
      Livres       = input$livres,
      Ressources   = input$ressources,
      Difficulte   = input$difficulte
      # etc.
    )
    
    # Détecte les champs vides ou N/A
    missing <- names(required_fields)[sapply(required_fields, function(x) {
      is.null(x) || x == "" || (is.numeric(x) && is.na(x))
    })]
    
    if (length(missing) > 0) {
      showModal(modalDialog(
        title = "Champs manquants",
        paste("Merci de renseigner :", paste(missing, collapse = ", ")),
        easyClose = TRUE
      ))
      return()
    }
    
    # Contrôles de cohérence simples
    if (input$age == "< 13 ans") {
      showModal(modalDialog("Tu ne peux pas être en 3e si tu as moins de 13 ans.", title = "Âge incohérent"))
      return()
    }
    if (input$moyenne_4e == "< 12/20" && input$moyenne_3e == "[16;20]") {
      showModal(modalDialog("Progression suspecte entre 4e et 3e.", title = "Incohérence"))
      return()
    }
    if (input$nationalite_sn == "Non" && input$autre_nationalite == "") {
      showModal(modalDialog("Merci de préciser ta nationalité.", title = "Nationalité manquante"))
      return()
    }
    
    # Récupération des réponses
    responses <- list(
      IA                   = input$ia,
      IEF                  = input$ief,
      Etablissement        = input$etablissement,
      Type_etablissement   = input$type_etab,
      Superviseur          = input$superviseur,
      Enqueteur            = input$enqueteur,
      Num_questionnaire    = input$num_questionnaire,
      Date_interview       = as.character(input$date_interview),
      Heure_debut          = input$heure_debut,
      Longitude            = input$longitude,
      Latitude             = input$latitude,
      Observations         = input$observations,
      Sexe                 = input$sexe,
      Age                  = input$age,
      Nationalite_SN       = input$nationalite_sn,
      Autre_nationalite    = if (input$nationalite_sn == "Non") input$autre_nationalite else NA,
      Temps_Senegal        = if (input$nationalite_sn == "Non") input$temps_senegal else NA,
      Moyenne_4e           = input$moyenne_4e,
      Moyenne_3e           = input$moyenne_3e,
      Niveau_science       = input$niveau_science,
      Temps_revision       = input$revision_science,
      Livres               = input$livres,
      Ressources           = input$ressources,
      Difficulte           = input$difficulte,
      Influence_notes      = input$influence_notes,
      Activite_preferee    = input$activite_pref,
      Utilite_sciences     = input$utilite_science,
      Importance_ecole     = input$importance_ecole
    )
    
    output$result <- renderPrint(responses)
    
    showModal(modalDialog(
      title     = "✅ Réponses enregistrées",
      "Merci pour votre participation !",
      easyClose = TRUE,
      footer    = modalButton("Fermer")
    ))
  })
}

shinyApp(ui, server)
