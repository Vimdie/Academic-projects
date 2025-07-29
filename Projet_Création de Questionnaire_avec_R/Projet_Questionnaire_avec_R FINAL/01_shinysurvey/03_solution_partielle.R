# 03_solution_partielle.R

# Chargement des packages nécessaires
if (!requireNamespace("shiny", quietly = TRUE))   install.packages("shiny")
if (!requireNamespace("bslib", quietly = TRUE))   install.packages("bslib")
if (!requireNamespace("shinyjs", quietly = TRUE)) install.packages("shinyjs")

library(shiny)
library(bslib)
library(shinyjs)

# UI
ui <- fluidPage(
  theme = bs_theme(
    bootswatch = "flatly",
    primary    = "#003366",
    base_font  = font_google("Montserrat")
  ),
  useShinyjs(),
  
  # Logos officiels
  fluidRow(
    column(6, tags$img(src = "ANSD.jpg",  height = "80px")),
    column(6, align = "right", tags$img(src = "ENSAE.png", height = "80px"))
  ),
  
  titlePanel("Questionnaire – Choix des séries scientifiques"),
  
  tabsetPanel(
    id   = "tabs",
    type = "tabs",
    
    # Onglet SECTION I
    tabPanel(
      title = "Identification",
      h3("SECTION I – Informations générales & identification"),
      wellPanel(
        textInput("identifiant_questionnaire",
                  "Identifiant du questionnaire",
                  value = ""),
        textInput("remplissage",
                  "Remplissage (Dép/Commune/N° Enquêteur/N°Quest)",
                  value = ""),
        textInput("date_interview",
                  "Date de l'interview (jj/mm/aaaa)",
                  placeholder = "jj/mm/aaaa"),
        textInput("heure_debut",
                  "Heure de début (hh:mm)",
                  placeholder = "hh:mm"),
        textInput("longitude",
                  "Longitude",
                  placeholder = "ex: -17.4500"),
        textInput("latitude",
                  "Latitude",
                  placeholder = "ex: 14.7645"),
        textAreaInput("observations",
                      "Observations du superviseur",
                      rows        = 3,
                      placeholder = "..."),
        
        # Identification du répondant
        radioButtons("sexe",
                     "I.2 Sexe du répondant :",
                     choices  = c("Homme", "Femme"),
                     selected = character(0),
                     inline   = TRUE),
        
        selectInput("age",
                    "I.3 Âge du répondant :",
                    choices  = c("", "< 13 ans", "[13;15[", "[15;17]", "> 17 ans"),
                    selected = ""),
        
        radioButtons("nationalite_sn",
                     "I.4 Nationalité sénégalaise ?",
                     choices  = c("Oui", "Non"),
                     selected = character(0),
                     inline   = TRUE),
        
        conditionalPanel(
          condition = "input.nationalite_sn == 'Non'",
          selectInput("autre_nationalite",
                      "I.5 Si non, quelle est ta nationalité ?",
                      choices  = c("", "Guinéenne", "Malienne", "Mauritanienne", 
                                   "Gambienne", "Autre"),
                      selected = "")
        ),
        
        selectInput("temps_senegal",
                    "I.6 Depuis combien de temps es-tu au Sénégal ?",
                    choices  = c("", "Moins de 6 mois", "Entre 6 mois et 1 an",
                                 "Entre 1 et 3 ans", "3 ans et plus", "Ne sais pas"),
                    selected = "")
      )
    ),
    
    # Onglet SECTION II
    tabPanel(
      title = "Profil académique",
      h3("SECTION II – Profil académique de l'élève"),
      wellPanel(
        selectInput("moyenne_4e",
                    "II‑1 Moyenne en sciences en classe de 4e :",
                    choices  = c("", "> 15/20", "[12;15[", "< 12/20"),
                    selected = ""),
        
        selectInput("moyenne_3e",
                    "II‑2 Moyenne du 1er semestre de 3e en sciences :",
                    choices  = c("", "< 10", "[10;12[", "[12;14[", "[14;16[", "[16;20]"),
                    selected = ""),
        
        radioButtons("niveau_science",
                     "II‑3 Comment juges-tu ton niveau en sciences ?",
                     choices  = c("Excellent", "Bon", "Moyen", "Faible"),
                     selected = character(0)),
        
        radioButtons("revision_science",
                     "II‑4 Temps de révision hebdomadaire :",
                     choices  = c("Moins de 2 h", "2 à 4 h", "4 à 6 h", "Plus de 6 h"),
                     selected = character(0)),
        
        radioButtons("livres_programme",
                     "II‑5 As‑tu des livres au programme ?",
                     choices  = c("Oui", "Non"),
                     selected = character(0),
                     inline    = TRUE),
        
        radioButtons("ressources_autres",
                     "II‑7 Utilises‑tu d'autres ressources ?",
                     choices  = c("Oui", "Non"),
                     selected = character(0),
                     inline    = TRUE),
        
        radioButtons("difficulte_sciences",
                     "II‑8 Comment trouves-tu les sciences ?",
                     choices  = c("Faciles", "Moyennement difficiles", "Très difficiles"),
                     selected = character(0)),
        
        radioButtons("amelioration_notes",
                     "II‑9 Tes notes peuvent-elles s'améliorer ?",
                     choices  = c("Oui", "Non"),
                     selected = character(0),
                     inline    = TRUE),
        
        radioButtons("utilite_sciences",
                     "II‑10 Utilité des sciences pour ton futur ?",
                     choices  = c("Très utiles", "Peu utiles", "Je ne sais pas"),
                     selected = character(0)),
        
        textAreaInput("importance_ecole",
                      "II‑11 Quelle importance l'école a-t-elle pour toi ?",
                      rows        = 3,
                      placeholder = "…")
      ),
      
      actionButton("submit", "Soumettre mes réponses",
                   class = "btn btn-success btn-lg"),
      br(), br(),
      verbatimTextOutput("result")
    )
  )
)

# Serveur
server <- function(input, output, session) {
  
  observeEvent(input$submit, {
    # (ici tu peux garder tes contrôles de saisie)
    
    # Récupération des réponses
    responses <- list(
      Identifiant_questionnaire = input$identifiant_questionnaire,
      Remplissage               = input$remplissage,
      Date_interview            = input$date_interview,
      Heure_debut               = input$heure_debut,
      Longitude                 = input$longitude,
      Latitude                  = input$latitude,
      Observations              = input$observations,
      Sexe                      = input$sexe,
      Âge                       = input$age,
      Nationalité_SN            = input$nationalite_sn,
      Autre_Nationalité         = if (input$nationalite_sn=="Non") input$autre_nationalite else NA,
      Temps_au_Sénégal          = input$temps_senegal,
      Moyenne_4e                = input$moyenne_4e,
      Moyenne_3e                = input$moyenne_3e,
      Niveau_sciences           = input$niveau_science,
      Temps_revision            = input$revision_science,
      Livres_au_programme       = input$livres_programme,
      Ressources_autres         = input$ressources_autres,
      Difficulte_sciences       = input$difficulte_sciences,
      Amelioration_notes        = input$amelioration_notes,
      Utilite_sciences          = input$utilite_sciences,
      Importance_ecole          = input$importance_ecole
    )
    
    output$result <- renderPrint({ responses })
    
    showModal(modalDialog(
      title     = "✅ Réponses enregistrées",
      "Merci pour votre participation ! Vos réponses ont bien été enregistrées.",
      easyClose = TRUE,
      footer    = modalButton("Fermer")
    ))
  })
}

# Lancement de l'application
shinyApp(ui = ui, server = server)
