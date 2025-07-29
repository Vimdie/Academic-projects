# Vérifier et installer remotes
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

# Vérifier et installer shiny
if (!requireNamespace("shiny", quietly = TRUE)) {
  install.packages("shiny")
}

# Vérifier et installer shinysurveys depuis GitHub
if (!requireNamespace("shinysurveys", quietly = TRUE)) {
  remotes::install_github("jdtrat/shinysurveys")
}

# Charger les packages
library(shiny)
library(shinysurveys)

# Définir les questions du questionnaire EHCVM avec une bonne séparation des options
questions <- data.frame(
  question = c(
    "Quel est le sexe du chef de ménage ?",
    "Quel est l'âge du chef de ménage ?",
    "Quel est le niveau d'instruction le plus élevé atteint par le chef de ménage ?",
    "Quelle est la principale source de revenus du ménage ?",
    "Combien de personnes vivent dans ce ménage ?"
  ),
  option = c(
    "Homme;Femme",                                  # Options séparées par un point-virgule
    "< 18 ans;18-35 ans;35-50 ans;> 50 ans",         # Exemple de tranches d'âge (ajustez si nécessaire)
    "Aucun;Primaire;Secondaire;Supérieur",          # Options pour le niveau d'instruction
    "Agriculture;Commerce;Salariat;Aide familiale;Autre", # Options pour la source de revenu
    "1;2;3;4;5;Plus de 5"                           # Options pour la taille du ménage
  ),
  input_type = c(
    "select",    # Menu déroulant pour le sexe
    "select",    # Menu déroulant pour l'âge (peut être numérique, ici pour l'exemple on utilise select)
    "select",    # Menu déroulant pour le niveau d'instruction
    "select",    # Menu déroulant pour la source de revenus
    "select"     # Menu déroulant pour la taille du ménage
  ),
  input_id = c(
    "sexe_chef",
    "age_chef",
    "niveau_instruction",
    "source_revenu",
    "taille_menage"
  ),
  # Pour cet exemple, on n'implémente pas de dépendances conditionnelles
  dependence = NA,
  dependence_value = NA,
  required = TRUE,
  stringsAsFactors = FALSE
)

# Interface utilisateur
ui <- fluidPage(
  titlePanel("Questionnaire EHCVM - Version shinysurveys"),
  surveyOutput(questions),
  actionButton("submit", "Soumettre"),
  verbatimTextOutput("result")
)

# Serveur de l'application
server <- function(input, output, session) {
  renderSurvey()  # Génère le formulaire basé sur le data frame questions
  
  observeEvent(input$submit, {
    responses <- parseSurveyData()  # Récupère les réponses soumises
    output$result <- renderPrint(responses)
  })
}

# Lancer l'application Shiny
shinyApp(ui = ui, server = server)
