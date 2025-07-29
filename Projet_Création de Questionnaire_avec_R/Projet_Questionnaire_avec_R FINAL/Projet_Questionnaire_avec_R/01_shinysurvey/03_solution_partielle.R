# Chargement des packages nécessaires
if (!requireNamespace("shiny", quietly = TRUE)) {
  install.packages("shiny")
}

library(shiny)

# UI
ui <- fluidPage(
  
  # Logos officiels
  fluidRow(
    column(6, tags$img(src = "ANSD.jpg", height = "80px")),
    column(6, align = "right", tags$img(src = "ENSAE.png", height = "80px"))
  ),
  
  titlePanel("Questionnaire - Choix des séries scientifiques (Version améliorée)"),
  
  ## SECTION I : IDENTIFICATION DU RÉPONDANT
  h3("SECTION I - Identification du répondant"),
  wellPanel(
    radioButtons("sexe", "Quel est ton sexe ?", choices = c("Homme", "Femme"), inline = TRUE),
    selectInput("age", "Quel est ton âge ?", choices = c("< 13 ans", "[13;15[", "[15;17]", "> 17 ans")),
    radioButtons("nationalite_sn", "Es-tu de nationalité sénégalaise ?", choices = c("Oui", "Non"), inline = TRUE),
    
    conditionalPanel(
      condition = "input.nationalite_sn == 'Non'",
      selectInput("autre_nationalite", "Si non, quelle est ta nationalité ?",
                  choices = c("", "Guinéenne", "Malienne", "Mauritanienne", "Gambienne", "Autre"))
    ),
    
    selectInput("temps_senegal", "Depuis combien de temps es-tu au Sénégal ?",
                choices = c("Moins de 6 mois", "Entre 6 mois et 1 an", "Entre 1 et 3 ans", "3 ans et plus", "Ne sais pas"))
  ),
  
  ## SECTION II : PROFIL ACADÉMIQUE
  h3("SECTION II - Profil académique de l'élève"),
  wellPanel(
    selectInput("moyenne_4e", "Quelle était ta moyenne en sciences en classe de 4e ?",
                choices = c("> 15/20", "[12/20;15/20]", "< 12/20")),
    
    selectInput("moyenne_3e", "Quelle est ta moyenne du 1er semestre de 3e en sciences ?",
                choices = c("< 10", "[10;12[", "[12;14[", "[14;16[", "[16;20]")),
    
    radioButtons("niveau_science", "Comment juges-tu ton niveau général en sciences ?",
                 choices = c("Excellent", "Bon", "Moyen", "Faible")),
    
    radioButtons("revision_science", "Combien de temps consacres-tu à la révision des sciences par semaine ?",
                 choices = c("Moins de 2 heures", "2 à 4 heures", "4 à 6 heures", "Plus de 6 heures"))
  ),
  
  actionButton("submit", "Soumettre"),
  br(), br(),
  verbatimTextOutput("result")
)

# Serveur
server <- function(input, output, session) {
  
  observeEvent(input$submit, {
    
    # CONTRÔLES DE SAISIE
    
    if (input$age == "< 13 ans") {
      showModal(modalDialog(
        title = "Âge incohérent",
        "Tu ne peux pas être en 3e si tu as moins de 13 ans.",
        easyClose = TRUE
      ))
      return()
    }
    
    if (input$moyenne_4e == "< 12/20" && input$moyenne_3e == "[16;20]") {
      showModal(modalDialog(
        title = "Progression suspecte",
        "Ta progression semble trop forte pour être cohérente.",
        easyClose = TRUE
      ))
      return()
    }
    
    if (input$nationalite_sn == "Non" && input$autre_nationalite == "") {
      showModal(modalDialog(
        title = "Nationalité manquante",
        "Merci de préciser ta nationalité.",
        easyClose = TRUE
      ))
      return()
    }
    
    # Récupération des réponses
    responses <- list(
      Sexe = input$sexe,
      Âge = input$age,
      Nationalité_SN = input$nationalite_sn,
      Autre_Nationalité = if (input$nationalite_sn == "Non") input$autre_nationalite else NA,
      Temps_au_Sénégal = input$temps_senegal,
      Moyenne_4e = input$moyenne_4e,
      Moyenne_3e = input$moyenne_3e,
      Niveau_sciences = input$niveau_science,
      Temps_revision = input$revision_science
    )
    
    output$result <- renderPrint({ print(responses) })
    
    showModal(modalDialog(
      title = "✅ Réponses enregistrées",
      "Merci pour votre participation ! Vos réponses ont bien été enregistrées.",
      easyClose = TRUE,
      footer = modalButton("Fermer")
    ))
  })
}

# Lancer l'application
shinyApp(ui = ui, server = server)
