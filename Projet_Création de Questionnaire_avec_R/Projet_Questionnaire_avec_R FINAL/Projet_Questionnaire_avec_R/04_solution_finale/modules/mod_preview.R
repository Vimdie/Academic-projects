# modules/mod_preview.R
mod_preview_ui <- function(id) {
  ns <- NS(id)
  tagList(
    # Style CSS personnalisé pour un rendu plus professionnel
    tags$style(HTML("
      .preview-title {
        font-size: 2em;
        margin-bottom: 20px;
        font-weight: bold;
      }
      .section-box {
        background-color: #f9f9f9;
        border: 1px solid #ddd;
        padding: 20px;
        margin-bottom: 30px;
        border-radius: 5px;
      }
      .section-title {
        font-size: 1.5em;
        font-weight: 600;
        margin-bottom: 10px;
      }
      .question-block {
        margin-bottom: 15px;
      }
    ")),
    
    fluidRow(
      column(width = 12,
             tags$div(class = "preview-title", textOutput(ns("dynamicTitle"))),
             uiOutput(ns("questionnaireUI")),
             br(),
             actionButton(ns("submitBtn"), "Soumettre", class = "btn btn-primary"),
             br(), br(),
             verbatimTextOutput(ns("submissionOutput"))
      )
    )
  )
}

mod_preview_server <- function(id, form_title, questions, sections = NULL) {
  moduleServer(id, function(input, output, session) {
    
    output$dynamicTitle <- renderText({
      req(form_title())
      form_title()
    })
    
    output$questionnaireUI <- renderUI({
      req(!is.null(questions()))
      if (nrow(questions()) == 0) {
        return(tags$em("Aucune question n’a été ajoutée."))
      }
      
      if (is.null(sections) || nrow(sections()) == 0) {
        return(tags$em("Aucune section n’a été définie. Veuillez configurer vos sections pour un aperçu structuré."))
      }
      
      # Récupérer et ordonner les sections
      sec_df <- sections()[order(sections()$rank), ]
      q_df   <- questions()
      
      ui_list <- list()
      
      for (s_idx in seq_len(nrow(sec_df))) {
        sec_info <- sec_df[s_idx, ]
        sec_title <- sec_info$title
        sec_rank  <- sec_info$rank
        
        q_section <- q_df[q_df$section == sec_title, ]
        if (nrow(q_section) == 0) next
        
        question_ui_list <- lapply(seq_len(nrow(q_section)), function(i) {
          row_data <- q_section[i, ]
          inputId <- paste0("q_", row.names(row_data)[1])
          
          label_display <- if (row_data$required) paste0(row_data$label, " *") else row_data$label
          
          cond <- if (row_data$conditional && !is.na(row_data$depend_on) && !is.na(row_data$depend_value)) {
            paste0("input.", row_data$depend_on, " == '", row_data$depend_value, "'")
          } else {
            NULL
          }
          
          choices_vec <- if (!is.na(row_data$choices) && row_data$type == "select") {
            unlist(strsplit(row_data$choices, ";"))
          } else character(0)
          
          input_ui <- switch(
            row_data$type,
            "text" = textInput(session$ns(inputId), label_display),
            "numeric" = {
              if (!is.na(row_data$unit) && nzchar(row_data$unit)) {
                numericInput(session$ns(inputId), paste0(label_display, " (", row_data$unit, ")"), value = NA)
              } else {
                numericInput(session$ns(inputId), label_display, value = NA)
              }
            },
            "select" = selectInput(session$ns(inputId), label_display, choices = choices_vec),
            "yesno"  = radioButtons(session$ns(inputId), label_display, choices = c("Oui", "Non"), inline = TRUE),
            "range"  = sliderInput(
              session$ns(inputId),
              label_display,
              min   = ifelse(!is.na(row_data$min), row_data$min, 0),
              max   = ifelse(!is.na(row_data$max), row_data$max, 100),
              value = c(row_data$min, row_data$max),
              step  = ifelse(!is.na(row_data$step), row_data$step, 1)
            ),
            textInput(session$ns(inputId), label_display)
          )
          
          question_div <- tags$div(class = "question-block", input_ui)
          
          if (!is.null(cond)) {
            conditionalPanel(
              condition = cond,
              question_div,
              ns = session$ns
            )
          } else {
            question_div
          }
        })
        
        section_box <- tags$div(class = "section-box",
                                tags$div(class = "section-title", paste0("SECTION ", sec_rank, " : ", sec_title)),
                                question_ui_list
        )
        
        ui_list[[length(ui_list) + 1]] <- section_box
      }
      
      do.call(tagList, ui_list)
    })
    
    observeEvent(input$submitBtn, {
      if (is.null(questions()) || nrow(questions()) == 0) {
        output$submissionOutput <- renderPrint("Aucune question, rien à soumettre.")
        return()
      }
      
      df <- questions()
      user_responses <- list()
      
      for (i in seq_len(nrow(df))) {
        row_id <- row.names(df)[i]
        inputId <- paste0("q_", row_id)
        user_responses[[df$label[i]]] <- input[[inputId]]
      }
      
      output$submissionOutput <- renderPrint({
        user_responses
      })
    })
    
  })
}
