# modules/mod_sections.R
mod_sections_ui <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("add_section_panel")),
    
    conditionalPanel(
      condition = sprintf("output['%s']", ns("has_sections")),
      fluidRow(
        box(title = "✏ Modifier une section", width = 6, solidHeader = TRUE, status = "warning",
            selectInput(ns("section_to_edit"), "Choisissez une section à modifier", choices = c("Aucune")),
            textInput(ns("new_section_title"), "Nouveau titre de la section"),
            numericInput(ns("new_section_rank"), "Nouveau rang de la section", value = NA),
            actionButton(ns("update_section"), "💾 Mettre à jour la section"),
            verbatimTextOutput(ns("section_edit_msg"))
        )
      ),
      fluidRow(
        box(title = "🗑 Supprimer une section", width = 6, solidHeader = TRUE, status = "danger",
            selectInput(ns("section_to_delete"), "Sélectionnez une section à supprimer", choices = c("Aucune")),
            actionButton(ns("delete_section"), "❌ Supprimer la section"),
            verbatimTextOutput(ns("delete_msg"))
        )
      )
    )
  )
}

mod_sections_server <- function(id, title_validated) {
  moduleServer(id, function(input, output, session) {
    sections <- reactiveVal(data.frame(rank = numeric(), title = character(), stringsAsFactors = FALSE))
    last_section_message <- reactiveVal("")
    
    output$add_section_panel <- renderUI({
      req(title_validated())
      ns <- session$ns
      box(title = "Ajouter une section", width = 6, solidHeader = TRUE, status = "primary",
          textInput(ns("section_title"), "Titre de la section"),
          numericInput(ns("section_rank"), "Rang de la section", min = 1, value = 1),
          actionButton(ns("add_section"), "Ajouter la section"),
          br(), br(),
          verbatimTextOutput(ns("section_message"))
      )
    })
    
    observeEvent(input$add_section, {
      df <- sections()
      if (input$section_title %in% df$title) {
        last_section_message(paste0("❌ Une section avec le titre '", input$section_title, "' existe déjà."))
        return()
      }
      if (input$section_rank %in% df$rank) {
        last_section_message(paste0("❌ Une section avec le rang ", input$section_rank, " existe déjà."))
        return()
      }
      df <- rbind(df, data.frame(rank = input$section_rank, title = input$section_title, stringsAsFactors = FALSE))
      df <- df[order(df$rank), ]
      sections(df)
      last_section_message(paste0("✅ Vous avez bien ajouté la Section ", input$section_rank, " : ", input$section_title))
      
      updateTextInput(session, "section_title", value = "")
      updateNumericInput(session, "section_rank", value = 1)
    })
    
    output$section_message <- renderText({ last_section_message() })
    
    observe({
      section_titles <- sections()$title
      updateSelectInput(session, "section_to_edit", choices = c("Aucune", section_titles))
      updateSelectInput(session, "section_to_delete", choices = c("Aucune", section_titles))
    })
    
    observeEvent(input$update_section, {
      df <- sections()
      selected <- input$section_to_edit
      
      if (selected == "Aucune") return()
      
      idx <- which(df$title == selected)
      
      if (length(idx) == 1) {
        new_title <- input$new_section_title
        new_rank <- input$new_section_rank
        
        if (new_title != "" && !(new_title %in% df$title[-idx])) {
          df$title[idx] <- new_title
        } else {
          output$section_edit_msg <- renderText("❌ Titre invalide ou déjà utilisé.")
          return()
        }
        
        if (!is.na(new_rank) && !(new_rank %in% df$rank[-idx])) {
          df$rank[idx] <- new_rank
        } else {
          output$section_edit_msg <- renderText("❌ Rang invalide ou déjà utilisé.")
          return()
        }
        
        df <- df[order(df$rank), ]
        sections(df)
        updateSelectInput(session, "section_to_edit", choices = c("Aucune", df$title))
        output$section_edit_msg <- renderText(paste0("✅ Section mise à jour : ", new_title, " (rang ", new_rank, ")"))
        
        updateSelectInput(session, "section_to_edit", selected = "Aucune")
        updateTextInput(session, "new_section_title", value = "")
        updateNumericInput(session, "new_section_rank", value = NA)
      }
    })
    
    observeEvent(input$delete_section, {
      if (input$section_to_delete == "Aucune") {
        output$delete_msg <- renderText("❌ Veuillez choisir une section à supprimer.")
        return()
      }
      
      df <- sections()
      new_df <- df[df$title != input$section_to_delete, ]
      sections(new_df)
      
      updateSelectInput(session, "section_to_edit", choices = c("Aucune", new_df$title))
      updateSelectInput(session, "section_to_delete", choices = c("Aucune", new_df$title))
      output$delete_msg <- renderText(paste0("🗑 Section supprimée : ", input$section_to_delete))
      
      updateSelectInput(session, "section_to_delete", selected = "Aucune")
    })
    
    output$has_sections <- reactive({
      nrow(sections()) > 0
    })
    outputOptions(output, "has_sections", suspendWhenHidden = FALSE)
    
    return(list(sections = sections))
  })
}
