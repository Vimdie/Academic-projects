# app.R

library(shiny)
library(shinydashboard)
library(shinyWidgets)

# Chargement des modules
source("modules/mod_title.R")
source("modules/mod_sections.R")
source("modules/mod_questions.R")
source("modules/mod_preview.R")

ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "🛠 Générateur de Questionnaire"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Titre & Section", tabName = "config", icon = icon("cog")),
      menuItem("Ajouter une question", tabName = "add", icon = icon("plus")),
      menuItem("Aperçu", tabName = "preview", icon = icon("eye"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "config",
              mod_title_ui("title"),
              mod_sections_ui("sections")
      ),
      tabItem(tabName = "add",
              mod_questions_ui("questions")
      ),
      tabItem(tabName = "preview",
              mod_preview_ui("preview")
      )
    )
  )
)

server <- function(input, output, session) {
  # Module de gestion du titre
  title_r <- mod_title_server("title")
  # Module de gestion des sections; on transmet la validation du titre
  sections_r <- mod_sections_server("sections", title_r$title_validated)
  # Module de gestion des questions; il a besoin des sections existantes
  questions_r <- mod_questions_server("questions", sections_r$sections)
  # Module d'aperçu; il reçoit le titre, les questions et les sections
  mod_preview_server("preview", title_r$form_title, questions_r$questions, sections_r$sections)
}

shinyApp(ui, server)
