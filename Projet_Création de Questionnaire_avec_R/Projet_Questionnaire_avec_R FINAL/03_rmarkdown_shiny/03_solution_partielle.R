# app_03_solution_partielle_design.R
# =================================
# Version complète incluant toutes les questions Section I,
# design inspiré EHCVM, validations et onglets.


if (!requireNamespace("shiny",    quietly = TRUE)) install.packages("shiny")
if (!requireNamespace("shinyjs",  quietly = TRUE)) install.packages("shinyjs")
if (!requireNamespace("bslib",    quietly = TRUE)) install.packages("bslib")

library(shiny)
library(shinyjs)

ui <- fluidPage(
  useShinyjs(),
  
  # =====================
  # Feuille de style
  # =====================
  tags$head(
    tags$style(HTML("
      body { 
        background-color: #f2f9ff; 
        font-family: Tahoma, sans-serif; 
      }
      h2, h3 {
        font-family: 'Arial Black', Gadget, sans-serif; 
        color: #003366; 
        text-align: center; 
      }
      label { 
        font-weight: bold; 
      }
      .main-panel {
        max-width: 1100px;
        margin: auto;
        background-color: white;
        padding: 30px;
        border-radius: 10px;
        border: 3px solid #007BFF;
        box-shadow: 0 0 12px rgba(0,0,0,0.12);
      }
      .shiny-input-container {
        margin-bottom: 20px;
      }
      .btn-primary {
        background-color: #0057a4;
        border-color: #0057a4;
        font-weight: bold;
        padding: 10px 20px;
      }
      .nav-tabs > li > a {
        font-weight: bold;
        color: #0057a4 !important;
      }
    "))
  ),
  
  # =====================
  # Bandeau supérieur
  # =====================
  fluidRow(
    column(6, tags$img(src = "ANSD.jpg",  height = "80px")),
    column(6, align = "right", tags$img(src = "ENSAE.png", height = "80px"))
  ),
  br(),
  
  # =====================
  # Titre principal
  # =====================
  h2("Questionnaire - Choix des séries scientifiques (Version améliorée)"),
  br(),
  
  # =====================
  # Contenu principal
  # =====================
  div(class = "main-panel",
      
      # Onglets : Identification & Profil académique
      tabsetPanel(
        # 1) SECTION I : IDENTIFICATION
        tabPanel(
          title = strong("Identification"),
          
          br(),
          h3("SECTION I - Identification du répondant"),
          
          wellPanel(
            # -- Champs manquants --
            selectInput("ia", "IA", 
                        choices = c("", "1 - Dakar", "2 - Pikine-Guédiawaye", "3 - Rufisque"),
                        selected = ""),
            textInput("ief", "IEF", value = ""),
            textInput("etablissement", "Établissement scolaire", value = ""),
            
            radioButtons("type_etab", "Type d’établissement", 
                         choices = c("Public", "Privé"),
                         selected = character(0),
                         inline = TRUE),
            
            textInput("superviseur",     "Nom du superviseur",      value = ""),
            textInput("enqueteur",       "Nom de l’enquêteur",      value = ""),
            textInput("num_questionnaire","Numéro du questionnaire", value = ""),
            
            dateInput("date_interview",  "Date de l'interview",
                      value = NULL, format = "dd/mm/yyyy"),
            
            textInput("heure_debut", "Heure de début (hh:mm)", placeholder = "hh:mm"),
            
            numericInput("longitude", "Longitude", value = NA, step = 0.000001),
            numericInput("latitude",  "Latitude",  value = NA, step = 0.000001),
            
            textAreaInput("observations", "Observations du superviseur",
                          rows = 3, placeholder = "Saisir vos remarques..."),
            
            # -- Questions déjà existantes --
            textInput("nom", "Nom et prénom du répondant :"),
            
            radioButtons("sexe", "Quel est ton sexe ?", choices = c("Homme", "Femme"), 
                         inline = TRUE, selected = character(0)),
            
            selectInput("age", "Quel est ton âge ?", 
                        choices = c("", "< 13 ans", "[13;15[", "[15;17]", "> 17 ans"),
                        selected = ""),
            
            radioButtons("nationalite_sn", "Es-tu de nationalité sénégalaise ?",
                         choices = c("Oui", "Non"), inline = TRUE,
                         selected = character(0)),
            
            conditionalPanel(
              condition = "input.nationalite_sn == 'Non'",
              selectInput("autre_nationalite", "Si non, quelle est ta nationalité ?",
                          choices = c("", "Guinéenne", "Malienne", "Mauritanienne", "Gambienne", "Autre"),
                          selected = "")
            ),
            
            selectInput("temps_senegal", "Depuis combien de temps es-tu au Sénégal ?",
                        choices = c("", "Moins de 6 mois", "Entre 6 et 12 mois", 
                                    "Entre 1 et 3 ans", "Plus de 3 ans", "Ne sais pas"),
                        selected = "")
          )
        ),
        
        # 2) SECTION II : PROFIL ACADÉMIQUE
        tabPanel(
          title = strong("Profil académique"),
          
          br(),
          h3("SECTION II - Profil académique de l'élève"),
          
          wellPanel(
            selectInput("moyenne_4e", "Quelle était ta moyenne générale en sciences en classe de 4e ?",
                        choices = c("> 15/20", "[12/20 ; 15/20]", "< 12/20"),
                        selected = character(0)),
            
            selectInput("moyenne_3e", "Quelle est ta moyenne du premier semestre de 3e en sciences ?",
                        choices = c("< 10", "[10 ;12[", "[12 ;14[", "[14 ;16[", "[16 ;20]"),
                        selected = character(0)),
            
            radioButtons("niveau", "Comment juges-tu ton niveau général dans les matières scientifiques ?",
                         choices = c("Excellent", "Bon", "Moyen", "Faible"), 
                         selected = character(0)),
            
            radioButtons("temps_revision", "Combien de temps consacres-tu chaque semaine à la révision des matières scientifiques ?",
                         choices = c("Moins de 2 heures", "Entre 2 et 4 heures", "Entre 4 et 6 heures", "Plus de 6 heures"),
                         selected = character(0)),
            
            radioButtons("livres", "As-tu des livres au programme pour étudier les matières scientifiques ?",
                         choices = c("Oui", "Non"), selected = character(0)),
            conditionalPanel(
              condition = "input.livres == 'Non'",
              helpText("Passer directement à la question suivante.")
            ),
            
            radioButtons("ressources", "Utilises-tu d'autres ressources pour étudier les matières scientifiques ?",
                         choices = c("Oui", "Non", "Je n’en ai pas"),
                         selected = character(0)),
            
            radioButtons("perception", "Comment trouves-tu les matières scientifiques ?",
                         choices = c("Faciles", "Assez difficiles", "Difficiles", "Très difficiles"),
                         selected = character(0)),
            
            radioButtons("influence", "Qu’est-ce qui influence positivement tes notes en sciences ?",
                         choices = c("Les ressources pédagogiques", "Mon investissement personnel", "Les difficultés d’adaptation"),
                         selected = character(0)),
            
            radioButtons("activite", "Parmi ces activités, que préfères-tu ?",
                         choices = c("Vidéos / documentaires", "Lecture / écriture", 
                                     "Résolution de problèmes scientifiques", "Langues", 
                                     "Autre (à préciser)"),
                         selected = character(0)),
            
            radioButtons("importance", "Quelle importance l’école a pour toi ?",
                         choices = c("Médecine", "Ingénierie", "Droit"),
                         selected = character(0))
          )
        )
      ),
      
      br(),
      actionButton("submit", "Soumettre", class = "btn btn-primary"),
      br(), br(),
      
      # Affichage des réponses
      verbatimTextOutput("result")
  )
)

server <- function(input, output, session) {
  
  observeEvent(input$submit, {
    # ----- VALIDATIONS -----
    
    # 1) Nom >= 2 caractères
    if (nchar(input$nom) < 2) {
      showModal(modalDialog(
        title = "Erreur de saisie",
        "Le champ 'Nom' doit contenir au moins 2 caractères.",
        easyClose = TRUE
      ))
      return(NULL)
    }
    
    # 2) Âge < 13 ans => incohérent
    if (input$age == "< 13 ans") {
      showModal(modalDialog(
        title = "Âge incompatible",
        "Impossible d'être en 4e ou 3e si tu as moins de 13 ans.",
        easyClose = TRUE
      ))
      return(NULL)
    }
    
    # 3) Vérifier cohérence de progression
    if (input$moyenne_4e == "< 12/20" && input$moyenne_3e == "[16 ;20]") {
      showModal(modalDialog(
        title = "Cohérence des moyennes",
        "Passer de <12/20 en 4e à >16/20 en 3e semble anormalement élevé.",
        easyClose = TRUE
      ))
      return(NULL)
    }
    
    # ----- RÉCUPÉRATION DES RÉPONSES -----
    responses <- list(
      # Champs Section I
      IA            = input$ia,
      IEF           = input$ief,
      Etablissement = input$etablissement,
      Type_etab     = input$type_etab,
      Superviseur   = input$superviseur,
      Enqueteur     = input$enqueteur,
      Num_quest     = input$num_questionnaire,
      Date_interv   = as.character(input$date_interview),
      Heure_debut   = input$heure_debut,
      Longitude     = input$longitude,
      Latitude      = input$latitude,
      Observations  = input$observations,
      Nom           = input$nom,
      Sexe          = input$sexe,
      Age           = input$age,
      Nationalite_SN= input$nationalite_sn,
      Autre_Nat     = if (input$nationalite_sn == "Non") input$autre_nationalite else NA,
      Temps_SN      = input$temps_senegal,
      
      # Champs Section II
      Moyenne_4e    = input$moyenne_4e,
      Moyenne_3e    = input$moyenne_3e,
      Niveau        = input$niveau,
      Revision      = input$temps_revision,
      Livres        = input$livres,
      Ressources    = input$ressources,
      Perception    = input$perception,
      Influence     = input$influence,
      Activite      = input$activite,
      Importance    = input$importance
    )
    
    # Affichage dans la console
    output$result <- renderPrint({
      print(responses)
    })
    
    # ----- AFFICHAGE CONFIRMATION -----
    showModal(modalDialog(
      title     = "✅ Réponses enregistrées",
      "Merci pour votre participation ! Vos réponses ont bien été validées.",
      easyClose = TRUE,
      footer    = modalButton("Fermer")
    ))
  })
}

shinyApp(ui = ui, server = server)
