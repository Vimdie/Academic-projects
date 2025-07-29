# ==== ⬇️ INSTALLATION AUTOMATIQUE DES PACKAGES SI NÉCESSAIRE ====
required_packages <- c("shiny", "bslib", "shinyjs", "shinysurveys")
new_packages <- required_packages[!(required_packages %in% installed.packages()[, "Package"])]
if (length(new_packages)) install.packages(new_packages)
lapply(required_packages, library, character.only = TRUE)

# ==== ⬇️ DÉFINITION DES QUESTIONS AU FORMAT shinysurveys ====
# Ces questions sont inspirées des photos du questionnaire
questions <- data.frame(
  question = c(
    # ----------------------------
    # SECTION I : IDENTIFICATION
    # ----------------------------
    "IA", 
    "IEF", 
    "Établissement scolaire", 
    "Type d’établissement", 
    "Nom du superviseur", 
    "Nom de l’enquêteur", 
    "Numéro du questionnaire", 
    "Date de l'interview (jj/mm/2024)", 
    "Heure de début (h:min)", 
    "Longitude", 
    "Latitude", 
    "Observations du superviseur", 
    "I.1 Nom et prénoms du répondant", 
    "I.2 Sexe du répondant", 
    "I.3 Âge du répondant", 
    "I.4 Êtes‑vous de nationalité sénégalaise ?", 
    "I.5 De quelle nationalité êtes‑vous ?", 
    "I.5 (précisez)", 
    "I.6 Depuis combien de temps êtes‑vous au Sénégal ?",
    
    # ----------------------------
    # SECTION II : PROFIL ACADÉMIQUE DE L'ÉLÈVE
    # ----------------------------
    "II‑1 Quelle était ta moyenne générale en sciences en classe de 4e ?", 
    "II‑2 Quelle est ta moyenne du 1er semestre de 3e en sciences ?", 
    "II‑3 Comment juges‑tu ton niveau en sciences ?", 
    "II‑4 Combien de temps consacres‑tu par semaine à la révision des sciences ?", 
    "II‑5 As‑tu des livres au programme pour étudier les sciences ?", 
    "II‑7 Utilises‑tu d'autres ressources pour étudier les sciences ?", 
    "II‑8 Comment trouves‑tu les sciences ?", 
    "II‑9 Penses‑tu que tes notes en sciences peuvent être améliorées ?", 
    "II‑10 À quel point trouves‑tu les sciences utiles pour ton futur ?", 
    "II‑11 Quelle importance l'école a‑t‑elle pour toi ?"
  ),
  input_id = c(
    "ia", "ief", "etablissement", "type_etablissement", "superviseur", "enqueteur", "num_questionnaire",
    "date_interview", "heure_debut", "longitude", "latitude", "observation",
    "i1_nom_prenom", "i2_sexe", "i3_age", "i4_nationalite_sn", "i5_which_nation", "i5_precision", "i6_temps_sn",
    "ii1_moyenne_4eme", "ii2_moyenne_3eme", "ii3_jugement", "ii4_temps_semaine", "ii5_livres_programme",
    "ii7_ressources", "ii8_facilite_diff", "ii9_notes", "ii10_utilite", "ii11_opinion_ecole"
  ),
  input_type = c(
    "select", "text", "text", "select", "text", "text", "text",
    "text", "text", "text", "text", "text",
    "text", "select", "numeric", "select", "select", "text", "select",
    "select", "select", "select", "select", "select",
    "select", "select", "select", "select", "text"
  ),
  option = c(
    "1 - Dakar;2 - Pikine‑Guédiawaye;3 - Rufisque",    # IA
    NA,                                                 # IEF
    NA,                                                 # Établissement
    "1 - Public;2 - Privé",                             # Type d’établissement
    NA,                                                 # Nom superviseur
    NA,                                                 # Nom enquêteur
    NA,                                                 # Numéro questionnaire
    NA,                                                 # Date d'interview (utilisation de "text" car shinysurveys n'accepte pas 'date')
    NA,                                                 # Heure de début
    NA, NA, NA,                                        # Longitude, Latitude, Observation
    NA,                                                 # I.1 Nom et prénoms
    "Homme;Femme",                                      # I.2 Sexe
    NA,                                                 # I.3 Âge
    "Oui;Non",                                          # I.4 Nationalité sénégalaise
    "Guinéenne;Malienne;Mauritanienne;Gambienne;Autre",  # I.5 Nationalité (si non)
    NA,                                                 # I.5 précision
    "Moins de 6 mois;Entre 6 et 12 mois;Plus de 12 mois;Ne sais pas",  # I.6 Temps au Sénégal
    
    # SECTION II
    "15/20;10/20;5/20;Autre",                           # II‑1 Moyenne en 4e
    "12‑14;14‑16;16‑18;≥18;Autre",                      # II‑2 Moyenne du 1er semestre
    "Excellent;Bon;Moyen;Faible",                       # II‑3 Jugement niveau
    "Moins de 2 heures;2 à 4 heures;Plus de 4 heures",   # II‑4 Temps révision
    "Oui;Non",                                          # II‑5 Livres au programme
    "Oui;Non",                                          # II‑7 Autres ressources
    "Faciles;Moyennement difficiles;Très difficiles",  # II‑8 Difficulté des sciences
    "Oui;Non",                                          # II‑9 Amélioration possible des notes
    "Très utiles;Peu utiles;Je ne sais pas",            # II‑10 Utilité
    NA                                                  # II‑11 Importance de l'école (texte libre)
  ),
  required = rep(TRUE, 29),
  dependence = c(
    rep(NA, 16),
    "i4_nationalite_sn", "i4_nationalite_sn", "i4_nationalite_sn",
    rep(NA, 10)
  ),
  dependence_value = c(
    rep(NA, 16),
    "Non","Non","Non",
    rep(NA, 10)
  ),
  stringsAsFactors = FALSE
)

# Remarque : Pour la question "Date de l'interview", 
# comme le type 'date' n'est pas reconnu par shinysurveys, nous utilisons "text".
# Il en va de même pour l'"Heure de début", "Longitude" et "Latitude".

# ==== ⬇️ UI ====
ui <- fluidPage(
  theme = bs_theme(bootswatch = "flatly", primary = "#003366",
                   base_font = font_google("Montserrat")),
  useShinyjs(),
  
  tags$style(HTML("
    .question-card {
      background-color: #f9f9f9;
      border-radius: 10px;
      padding: 25px;
      box-shadow: 0px 2px 10px rgba(0,0,0,0.05);
      margin-bottom: 30px;
    }
    .question-card h4 {
      color: #003366;
      font-weight: bold;
      border-bottom: 2px solid #9ecae1;
      padding-bottom: 10px;
      margin-bottom: 25px;
    }
  ")),
  
  fluidRow(
    column(12, align = "center",
           h2("ENQUETE SUR LE CHOIX DES SERIES SCIENTIFIQUES EN 3E A DAKAR", style = "color:#003366"),
           p("Merci de répondre à ce questionnaire. Vos réponses resteront confidentielles.",
             style = "color:#003366")
    )
  ),
  br(),
  div(class = "question-card",
      surveyOutput(df = questions,
                   survey_title = "Enquête – Choix des séries scientifiques",
                   survey_description = NULL)
  ),
  br(),
  actionButton("submit", "Soumettre mes réponses", class = "btn btn-success btn-lg"),
  verbatimTextOutput("resultat")
)

# ==== ⬇️ SERVEUR ====
server <- function(input, output, session) {
  renderSurvey()
  
  observeEvent(input$submit, {
    res <- getSurveyData()
    res$timestamp <- Sys.time()
    
    # Stockage local dans la variable globale
    if (!exists("collected_responses", envir = .GlobalEnv))
      assign("collected_responses", list(), envir = .GlobalEnv)
    lst <- get("collected_responses", envir = .GlobalEnv)
    lst[[length(lst) + 1]] <- res
    assign("collected_responses", lst, envir = .GlobalEnv)
    
    output$resultat <- renderPrint({ res })
    
    showModal(modalDialog(
      title = "✅ Merci !",
      "Vos réponses ont bien été enregistrées.",
      easyClose = TRUE,
      footer = modalButton("Fermer")
    ))
  })
}

# ==== ⬇️ LANCEMENT DE L'APPLICATION ====
shinyApp(ui, server)
