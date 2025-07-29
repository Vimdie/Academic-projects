library(shiny)
library(shinyforms)

# ================================
#  Formulaire 1 : Section I – Identification 
# ================================
sectionIForm <- list(
  id = "sectionIForm",
  questions = list(
    list(
      id = "chef_name", 
      type = "text", 
      title = "Nom complet du chef de ménage", 
      mandatory = TRUE,
      hint = "Écrivez le nom tel qu’il apparaît sur la pièce d’identité"
    ),
    list(
      id = "chef_age", 
      type = "numeric", 
      title = "Âge du chef de ménage", 
      mandatory = TRUE
    ),
    list(
      id = "chef_nationalite",
      type = "text",
      title = "Nationalité du chef de ménage",
      mandatory = FALSE,
      hint = "Ex. : Sénégalaise, Malienne, etc."
    ),
    list(
      id = "chef_consent",
      type = "checkbox",
      title = "J’accepte que mes réponses soient utilisées à des fins statistiques"
    )
  ),
  storage = list(
    type = STORAGE_TYPES$FLATFILE,
    path = "responses_sectionI"
  ),
  name = "Section I – Identification du Chef de Ménage",
  password = "shinyforms",
  reset = TRUE,
  validations = list(
    list(
      condition = "nchar(input$chef_name) >= 3",
      message = "Le nom doit comporter au moins 3 caractères."
    ),
    list(
      condition = "input$chef_age >= 18 && input$chef_age <= 120",
      message = "L'âge du chef de ménage doit être compris entre 18 et 120 ans."
    ),
    list(
      condition = "input$chef_consent == TRUE",
      message = "Vous devez cocher la case d'acceptation."
    )
  )
)

# ================================
#  Formulaire 2 : Section II – Profil académique
# ================================
sectionIIForm <- list(
  id = "sectionIIForm",
  questions = list(
    list(
      id = "moyenne_4e",
      type = "text",
      title = "Moyenne en sciences en classe de 4e",
      mandatory = TRUE,
      hint = "Ex. : 15/20, 12/20..."
    ),
    list(
      id = "moyenne_3e",
      type = "text",
      title = "Moyenne sciences 1er semestre de 3e",
      mandatory = TRUE
    ),
    list(
      id = "revision_science",
      type = "numeric",
      title = "Heures de révision des sciences par semaine",
      mandatory = TRUE
    ),
    list(
      id = "niveau_science",
      type = "text",
      title = "Comment évalues-tu ton niveau en sciences ?",
      mandatory = TRUE,
      hint = "Ex. : Bon, Moyen, Faible, etc."
    )
  ),
  storage = list(
    type = STORAGE_TYPES$FLATFILE,
    path = "responses_sectionII"
  ),
  multiple = FALSE,
  validations = list(
    list(
      condition = "input$revision_science >= 0 && input$revision_science <= 70",
      message = "Le nombre d'heures de révision doit être compris entre 0 et 70."
    ),
    list(
      condition = "input$niveau_science != ''",
      message = "Merci de renseigner ton niveau en sciences."
    )
  )
)

# ================================
#  Interface utilisateur : deux onglets
# ================================
ui <- fluidPage(
  h1("Questionnaire EHCVM - shinyforms (Deux sections)"),
  tabsetPanel(
    tabPanel(
      "Section I - Identification",
      formUI(sectionIForm)
    ),
    tabPanel(
      "Section II - Profil académique",
      formUI(sectionIIForm)
    )
  )
)

# ================================
#  Serveur : on appelle formServer(...) pour chaque formulaire
# ================================
server <- function(input, output, session) {
  formServer(sectionIForm)
  formServer(sectionIIForm)
}

# ================================
#  Lancement de l'application
# ================================
shinyApp(ui, server)
