# modules/mod_title.R
mod_title_ui <- function(id) {
  ns <- NS(id)
  fluidRow(
    box(title = "Nom du questionnaire", width = 6, solidHeader = TRUE, status = "primary",
        textInput(ns("form_title"), "Titre", value = ""),
        uiOutput(ns("title_buttons")),
        br(), br(),
        strong("Titre actuellement enregistré :"),
        verbatimTextOutput(ns("current_title"))
    )
  )
}

mod_title_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    form_title <- reactiveVal("")
    title_validated <- reactiveVal(FALSE)
    
    output$title_buttons <- renderUI({
      if (!title_validated()) {
        actionButton(session$ns("validate_title"), "✅ Valider le titre du questionnaire")
      } else {
        actionButton(session$ns("modify_title"), "✏ Modifier le titre du questionnaire")
      }
    })
    
    observeEvent(input$validate_title, {
      if (nzchar(input$form_title)) {
        form_title(input$form_title)
        title_validated(TRUE)
      }
    })
    
    observeEvent(input$modify_title, {
      if (nzchar(input$form_title)) {
        form_title(input$form_title)
      }
    })
    
    output$current_title <- renderText({
      if (form_title() == "") "Aucun titre défini." else form_title()
    })
    
    return(list(form_title = form_title, title_validated = title_validated))
  })
}
