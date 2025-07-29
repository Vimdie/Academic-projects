# modules/mod_questions.R
mod_questions_ui <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      box(
        title = "Nouvelle question", width = 12, solidHeader = TRUE, status = "info",
        uiOutput(ns("edit_mode_note")),
        textInput(ns("label"), "Texte de la question"),
        selectInput(ns("response_type"), "Type de réponse",
                    choices = c("Texte libre" = "text", "Nombre" = "numeric", 
                                "Choix multiple" = "select", "Oui / Non" = "yesno",
                                "Intervalle (ex: revenu)" = "range")),
        uiOutput(ns("section_select")),
        checkboxInput(ns("required"), "Obligatoire", TRUE),
        # Options pour "select"
        conditionalPanel(
          condition = sprintf("input['%s'] == 'select'", ns("response_type")),
          textInput(ns("choices"), "Choix (séparés par ;) ex: rouge;bleu;vert")
        ),
        # Options pour "range"
        conditionalPanel(
          condition = sprintf("input['%s'] == 'range'", ns("response_type")),
          numericInput(ns("min"), "Valeur minimale", value = 0),
          numericInput(ns("max"), "Valeur maximale", value = 100),
          numericInput(ns("step"), "Pas", value = 1)
        ),
        # Nouvelles options pour "numeric"
        conditionalPanel(
          condition = sprintf("input['%s'] == 'numeric'", ns("response_type")),
          textInput(ns("unit"), "Unité", placeholder = "ex: € ou kg, laisser vide pour aucune"),
          selectInput(ns("value_type"), "Type de valeur",
                      choices = c("Entier naturel" = "natural",
                                  "Entier relatif" = "integer",
                                  "Nombre réel" = "real"))
        ),
        checkboxInput(ns("conditional"), "Cette question dépend-elle d'une autre ?", value = FALSE),
        conditionalPanel(
          condition = sprintf("input['%s'] == true", ns("conditional")),
          uiOutput(ns("depend_on_selector")),
          textInput(ns("depend_value"), "Afficher si la réponse est…")
        ),
        conditionalPanel(
          condition = sprintf("output['%s'] == false", ns("editing_mode")),
          actionButton(ns("add_q"), "➕ Ajouter la question")
        ),
        conditionalPanel(
          condition = sprintf("output['%s'] == true", ns("editing_mode")),
          actionButton(ns("update_q"), "✅ Sauvegarder les modifications")
        )
      )
    ),
    conditionalPanel(
      condition = sprintf("output['%s']", ns("has_questions")),
      fluidRow(
        box(
          title = "📋 Aperçu des questions ajoutées", width = 12, solidHeader = TRUE, status = "success",
          tableOutput(ns("questionsTable"))
        )
      ),
      fluidRow(
        box(
          title = "🛠 Modifier une question existante", width = 6, solidHeader = TRUE, status = "warning",
          uiOutput(ns("question_selector")),
          verbatimTextOutput(ns("update_msg"))
        ),
        box(
          title = "🗑 Supprimer une question", width = 6, solidHeader = TRUE, status = "danger",
          selectInput(ns("delete_question"), "Sélectionnez une question à supprimer", choices = c("Aucune")),
          actionButton(ns("delete_q"), "❌ Supprimer la question"),
          verbatimTextOutput(ns("delete_msg"))
        )
      )
    )
  )
}

mod_questions_server <- function(id, sections) {
  moduleServer(id, function(input, output, session) {
    library(stringi)
    
    selected_question_index <- reactiveVal(NULL)
    questions <- reactiveVal(data.frame(
      section = character(), 
      label = character(), 
      type = character(),
      required = logical(), 
      choices = character(),
      min = numeric(), 
      max = numeric(), 
      step = numeric(),
      conditional = logical(), 
      depend_on = character(), 
      depend_value = character(),
      unit = character(), 
      value_type = character(),
      stringsAsFactors = FALSE
    ))
    
    reset_fields <- function() {
      updateTextInput(session, "label", value = "")
      updateSelectInput(session, "response_type", selected = "text")
      updateSelectInput(session, "section", selected = sections()$title[1])
      updateCheckboxInput(session, "required", value = TRUE)
      updateTextInput(session, "choices", value = "")
      updateNumericInput(session, "min", value = 0)
      updateNumericInput(session, "max", value = 100)
      updateNumericInput(session, "step", value = 1)
      updateCheckboxInput(session, "conditional", value = FALSE)
      updateTextInput(session, "depend_value", value = "")
      updateSelectInput(session, "depend_on_select", choices = questions()$label)
      updateTextInput(session, "unit", value = "")          # Correction : unit est un champ textuel
      updateSelectInput(session, "value_type", selected = "natural")
      updateSelectInput(session, "edit_question", selected = "Aucune")
      updateSelectInput(session, "delete_question", selected = "Aucune")
    }
    
    clean_string <- function(txt) {
      txt <- tolower(txt)
      txt <- gsub(" ", "", txt)
      txt <- stringi::stri_trans_general(txt, "Latin-ASCII")
      return(txt)
    }
    
    output$editing_mode <- reactive({
      !is.null(selected_question_index())
    })
    outputOptions(output, "editing_mode", suspendWhenHidden = FALSE)
    
    output$has_questions <- reactive({
      nrow(questions()) > 0
    })
    outputOptions(output, "has_questions", suspendWhenHidden = FALSE)
    
    output$section_select <- renderUI({
      selectInput(session$ns("section"), "Section de rattachement", choices = sections()$title)
    })
    
    observeEvent(input$add_q, {
      new_row <- data.frame(
        section = input$section,
        label = input$label,
        type = input$response_type,
        required = input$required,
        choices = ifelse(input$response_type == "select", input$choices, NA),
        min = ifelse(input$response_type == "range", input$min, NA),
        max = ifelse(input$response_type == "range", input$max, NA),
        step = ifelse(input$response_type == "range", input$step, NA),
        conditional = input$conditional,
        depend_on = ifelse(input$conditional, input$depend_on_select, NA),
        depend_value = ifelse(input$conditional, input$depend_value, NA),
        unit = ifelse(input$response_type == "numeric", input$unit, NA),
        value_type = ifelse(input$response_type == "numeric", input$value_type, NA),
        stringsAsFactors = FALSE
      )
      
      # Nettoyage et vérification de doublon sur label, type et section
      label_clean <- clean_string(new_row$label)
      type_new <- new_row$type
      section_new <- new_row$section
      
      is_similar_question <- FALSE
      if (nrow(questions()) > 0) {
        is_similar_question <- any(apply(questions(), 1, function(row) {
          label_existing <- clean_string(row[["label"]])
          type_existing <- row[["type"]]
          section_existing <- row[["section"]]
          dist <- utils::adist(label_clean, label_existing)
          (dist < 3) && (type_existing == type_new) && (section_existing == section_new)
        }))
      }
      
      if (nrow(questions()) > 0 && is_similar_question) {
        showModal(modalDialog(
          title = "❌ Doublon détecté",
          paste0("Une question très similaire existe déjà dans la section « ", section_new, " »."),
          easyClose = TRUE,
          footer = modalButton("OK")
        ))
        return()
      }
      
      questions(rbind(questions(), new_row))
      reset_fields()
    })
    
    observeEvent(input$update_q, {
      idx <- selected_question_index()
      if (!is.null(idx)) {
        df <- questions()
        df[idx, ] <- data.frame(
          section = input$section,
          label = input$label,
          type = input$response_type,
          required = input$required,
          choices = ifelse(input$response_type == "select", input$choices, NA),
          min = ifelse(input$response_type == "range", input$min, NA),
          max = ifelse(input$response_type == "range", input$max, NA),
          step = ifelse(input$response_type == "range", input$step, NA),
          conditional = input$conditional,
          depend_on = ifelse(input$conditional, input$depend_on_select, NA),
          depend_value = ifelse(input$conditional, input$depend_value, NA),
          unit = ifelse(input$response_type == "numeric", input$unit, NA),
          value_type = ifelse(input$response_type == "numeric", input$value_type, NA),
          stringsAsFactors = FALSE
        )
        questions(df)
        selected_question_index(NULL)
        reset_fields()
      }
    })
    
    observeEvent(input$delete_q, {
      if (input$delete_question == "Aucune") {
        output$delete_msg <- renderText("❌ Veuillez choisir une question à supprimer.")
        return()
      }
      
      df <- questions()
      new_df <- df[df$label != input$delete_question, ]
      questions(new_df)
      
      updateSelectInput(session, "edit_question", choices = c("Aucune", new_df$label))
      updateSelectInput(session, "delete_question", choices = c("Aucune", new_df$label))
      output$delete_msg <- renderText(paste0("🗑 Question supprimée : ", input$delete_question))
      reset_fields()
    })
    
    output$questionsTable <- renderTable({ questions() })
    
    output$depend_on_selector <- renderUI({
      selectInput(session$ns("depend_on_select"), "Question déclencheur", choices = questions()$label)
    })
    
    output$question_selector <- renderUI({
      if (nrow(questions()) == 0) return(NULL)
      selectInput(session$ns("edit_question"), "Sélectionnez une question à modifier",
                  choices = c("Aucune", questions()$label), selected = "Aucune")
    })
    
    observe({
      updateSelectInput(session, "delete_question", choices = c("Aucune", questions()$label))
    })
    
    observeEvent(input$edit_question, {
      if (input$edit_question == "Aucune") {
        selected_question_index(NULL)
        return()
      }
      idx <- which(questions()$label == input$edit_question)[1]
      selected_question_index(idx)
      q <- questions()[idx, ]
      
      updateTextInput(session, "label", value = q$label)
      updateSelectInput(session, "response_type", selected = q$type)
      updateSelectInput(session, "section", selected = q$section)
      updateCheckboxInput(session, "required", value = q$required)
      updateTextInput(session, "choices", value = q$choices)
      updateNumericInput(session, "min", value = q$min)
      updateNumericInput(session, "max", value = q$max)
      updateNumericInput(session, "step", value = q$step)
      updateCheckboxInput(session, "conditional", value = q$conditional)
      updateTextInput(session, "depend_value", value = q$depend_value)
      updateSelectInput(session, "depend_on_select", selected = q$depend_on)
      if(q$type == "numeric"){
        updateTextInput(session, "unit", value = q$unit)
        updateSelectInput(session, "value_type", selected = q$value_type)
      }
    })
    
    output$edit_mode_note <- renderUI({
      if (!is.null(selected_question_index())) {
        tags$div(style = "color: red;", "🖊 Mode édition actif : vous modifiez une question existante.")
      }
    })
    
    return(list(questions = questions))
  })
}
