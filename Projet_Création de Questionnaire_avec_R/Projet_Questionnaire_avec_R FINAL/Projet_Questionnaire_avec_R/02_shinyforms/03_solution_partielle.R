# Vérification des packages
if (!requireNamespace("shiny", quietly = TRUE)) install.packages("shiny")
library(shiny)

# UI
ui <- fluidPage(
  
  # Affichage des logos
  fluidRow(
    column(6, tags$img(src = "ANSD.jpg", height = "80px")),
    column(6, align = "right", tags$img(src = "ENSAE.png", height = "80px"))
  ),
  
  titlePanel("Questionnaire - Choix des séries scientifiques (Version améliorée sans shinyforms)"),
  
  h3("SECTION I - Identification du répondant"),
  wellPanel(
    textInput("nom", "Nom et prénom du répondant :"),
    radioButtons("sexe", "Quel est ton sexe ?", choices = c("Homme", "Femme"), inline = TRUE),
    selectInput("age", "Quel est ton âge ?", choices = c("< 13 ans", "[13;15[", "[15;17]", "> 17 ans")),
    radioButtons("nationalite_sn", "Es-tu de nationalité sénégalaise ?", choices = c("Oui", "Non"), inline = TRUE),
    
    conditionalPanel(
      condition = "input.nationalite_sn == 'Non'",
      selectInput("autre_nationalite", "Si non, quelle est ta nationalité ?",
                  choices = c("", "Guinéenne", "Malienne", "Mauritanienne", "Gambienne", "Autre"))
    ),
    
    selectInput("temps_senegal", "Depuis combien de temps es-tu au Sénégal ?",
                choices = c("Moins de 6 mois", "Entre 6 et 12 mois", "Entre 1 et 3 ans", "Plus de 3 ans", "Ne sais pas"))
  ),
  
  h3("SECTION II - Profil académique de l'élève"),
  wellPanel(
    selectInput("moyenne_4e", "Quelle était ta moyenne générale dans les matières scientifiques en classe de 4e ?",
                choices = c("> 15/20", "[12/20 ; 15/20]", "< 12/20")),
    
    selectInput("moyenne_3e", "Quelle est ta moyenne du premier semestre de 3e dans les matières scientifiques ?",
                choices = c("< 10", "[10 ; 12[", "[12 ; 14[", "[14 ; 16[", "[16 ; 20]")),
    
    radioButtons("niveau", "Comment juges-tu ton niveau général dans les matières scientifiques ?",
                 choices = c("Excellent", "Bon", "Moyen", "Faible")),
    
    radioButtons("temps_revision", "Combien de temps consacres-tu chaque semaine à la révision des matières scientifiques ?",
                 choices = c("Moins de 2 heures", "Entre 2 et 4 heures", "Entre 4 et 6 heures", "Plus de 6 heures")),
    
    radioButtons("livres", "As-tu des livres au programme pour étudier les matières scientifiques ?",
                 choices = c("Oui", "Non")),
    
    conditionalPanel(
      condition = "input.livres == 'Non'",
      helpText("Passer directement à la question II-7.")
    ),
    
    radioButtons("ressources", "Utilises-tu d'autres ressources pour étudier les matières scientifiques ?",
                 choices = c("Oui", "Non", "Je n’en ai pas")),
    
    radioButtons("perception", "Comment trouves-tu les matières scientifiques ?",
                 choices = c("Faciles", "Assez difficiles", "Difficiles", "Très difficiles")),
    
    radioButtons("influence", "Qu’est-ce qui influence positivement tes notes en sciences ?",
                 choices = c("Les ressources pédagogiques", "Mon investissement personnel", "Les difficultés d’adaptation")),
    
    radioButtons("activite", "Parmi ces activités, que préfères-tu ?",
                 choices = c("Vidéos / documentaires", "Lecture / écriture", "Résolution de problèmes scientifiques", 
                             "Langues", "Autre (à préciser)")),
    
    radioButtons("importance", "Quelle importance l’école a pour toi ?",
                 choices = c("Médecine", "Ingénierie", "Droit"))
  ),
  
  # Soumission
  actionButton("submit", "Soumettre"),
  br(), br(),
  verbatimTextOutput("result")
)

# Serveur
server <- function(input, output, session) {
  observeEvent(input$submit, {
    
    # CONTRÔLES DE SAISIE
    if (is.null(input$nom) || nchar(input$nom) < 3) {
      showModal(modalDialog(
        title = "Nom invalide",
        "Merci d’indiquer un nom valide (au moins 3 caractères).",
        easyClose = TRUE
      ))
      return()
    }
    
    if (input$age == "< 13 ans") {
      showModal(modalDialog(
        title = "Âge incohérent",
        "Tu ne peux pas être en 3e si tu as moins de 13 ans.",
        easyClose = TRUE
      ))
      return()
    }
    
    if (input$moyenne_4e == "< 12/20" && input$moyenne_3e == "[16 ; 20]") {
      showModal(modalDialog(
        title = "Progression suspecte",
        "La progression entre la 4e et la 3e semble incohérente.",
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
      Nom = input$nom,
      Sexe = input$sexe,
      Âge = input$age,
      Nationalité_SN = input$nationalite_sn,
      Autre_Nationalité = if (input$nationalite_sn == "Non") input$autre_nationalite else NA,
      Temps_au_Sénégal = input$temps_senegal,
      Moyenne_4e = input$moyenne_4e,
      Moyenne_3e = input$moyenne_3e,
      Niveau_sciences = input$niveau,
      Temps_revision = input$temps_revision,
      Livres_programme = input$livres,
      Ressources = input$ressources,
      Perception = input$perception,
      Influence = input$influence,
      Activité_préférée = input$activite,
      Importance_école = input$importance
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

# Lancement
shinyApp(ui = ui, server = server)
