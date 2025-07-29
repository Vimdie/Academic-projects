# 📄 Documentation – Implémentation du questionnaire via `shinyforms`

## 🎯 Objectif

Ce projet vise à reproduire numériquement une partie du **questionnaire EHCVM** en utilisant le package R `shinyforms`, notamment les sections sur :

-   🧍‍♂️ **Identification du chef de ménage**
-   🎓 **Profil académique de l'élève**

L’objectif est d’évaluer la capacité de `shinyforms` à créer des **formulaires structurés, validés et stockés automatiquement**, sans nécessiter de manipulation avancée du backend.

------------------------------------------------------------------------

## 📦 Présentation de `shinyforms`

`shinyforms` est un package R développé par [Dean Attali](https://github.com/daattali) qui permet de créer facilement des formulaires interactifs dans Shiny, avec :

-   Champs obligatoires\
-   Validations personnalisées\
-   Stockage automatique des réponses\
-   Interface simple à mettre en place

📦 Installation :

``` r
devtools::install_github("daattali/shinyforms")
```

------------------------------------------------------------------------

## 🖼️ Questionnaire papier reproduit

Le formulaire a été reconstruit à partir des pages suivantes du questionnaire papier :

![Page 1](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/1.png)\
![Page 2](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/2.png)\
![Page 3](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/3.png)\
![Page 4](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/4.png)\
![Page 5](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/5.png)

------------------------------------------------------------------------

## 🧪 Implémentation utilisée

### ✅ Script de base : `01_questionnaire_base.R`

Deux formulaires distincts sont définis :

### **Formulaire 1 – Identification**

``` r
sectionIForm <- list(
  id = "sectionIForm",
  questions = list(
    list(id = "chef_name", type = "text", title = "Nom complet du chef de ménage", mandatory = TRUE,
         hint = "Écrivez le nom tel qu’il apparaît sur la pièce d’identité"),
    list(id = "chef_age", type = "numeric", title = "Âge du chef de ménage", mandatory = TRUE),
    list(id = "chef_nationalite", type = "text", title = "Nationalité du chef de ménage", mandatory = FALSE,
         hint = "Ex. : Sénégalaise, Malienne, etc."),
    list(id = "chef_consent", type = "checkbox", title = "J’accepte que mes réponses soient utilisées à des fins statistiques")
  ),
  storage = list(type = STORAGE_TYPES$FLATFILE, path = "responses_sectionI"),
  name = "Section I – Identification du Chef de Ménage",
  password = "shinyforms",
  reset = TRUE,
  validations = list(
    list(condition = "nchar(input$chef_name) >= 3", message = "Le nom doit comporter au moins 3 caractères."),
    list(condition = "input$chef_age >= 18 && input$chef_age <= 120", message = "L'âge doit être compris entre 18 et 120 ans."),
    list(condition = "input$chef_consent == TRUE", message = "Vous devez cocher la case d'acceptation.")
  )
)
```

### **Formulaire 2 – Profil académique**

``` r
sectionIIForm <- list(
  id = "sectionIIForm",
  questions = list(
    list(id = "moyenne_4e", type = "text", title = "Moyenne en sciences en classe de 4e", mandatory = TRUE,
         hint = "Ex. : 15/20, 12/20..."),
    list(id = "moyenne_3e", type = "text", title = "Moyenne sciences 1er semestre de 3e", mandatory = TRUE),
    list(id = "revision_science", type = "numeric", title = "Heures de révision des sciences par semaine", mandatory = TRUE),
    list(id = "niveau_science", type = "text", title = "Comment évalues-tu ton niveau en sciences ?", mandatory = TRUE,
         hint = "Ex. : Bon, Moyen, Faible, etc.")
  ),
  storage = list(type = STORAGE_TYPES$FLATFILE, path = "responses_sectionII"),
  multiple = FALSE,
  validations = list(
    list(condition = "input$revision_science >= 0 && input$revision_science <= 70", message = "Le nombre d'heures de révision doit être compris entre 0 et 70."),
    list(condition = "input$niveau_science != ''", message = "Merci de renseigner ton niveau en sciences.")
  )
)
```

📥 Chaque formulaire est affiché dans un onglet via `tabsetPanel()`.

------------------------------------------------------------------------

## 🧠 Fonctionnalités prises en charge

| Fonctionnalité              | Supportée | Détail                                                 |
|-----------------------------------------|----------------|----------------|
| Champs obligatoires         | ✅        | `mandatory = TRUE`                                     |
| Validations conditionnelles | ✅        | Via `formInfo$validations`                             |
| Sauvegarde des réponses     | ✅        | `.csv` dans un dossier local                           |
| Séparation en onglets       | ✅        | Grâce à `tabsetPanel()`                                |
| Formulaire réinitialisable  | ✅        | `reset = TRUE`                                         |
| Sécurité basique            | ✅        | Accès admin via URL + mot de passe                     |
| Multi-formulaire            | ✅        | Plusieurs formulaires utilisables dans un seul `app.R` |

------------------------------------------------------------------------

## ⚠️ Limites du package `shinyforms`

| Limite                        | Observée ? | Détail                                                     |
|----------------------------------------|----------------|----------------|
| Types d’input limités         | ✅         | Pas de `selectInput`, `radioButtons`, `dateInput` natifs   |
| Pas de logique conditionnelle | ✅         | Impossible d’afficher une question en fonction d’une autre |
| Pas de sections visuelles     | ✅         | Pas de séparation visuelle entre blocs de questions        |
| Pas de support d’images       | ✅         | Impossible d’ajouter des logos ou illustrations            |
| Interface peu personnalisable | ✅         | Pas de CSS intégré ni d’options de layout avancé           |
| Pas de stockage en base       | ✅         | Pas de connexion à une base de données                     |

------------------------------------------------------------------------

## 🚀 Améliorations apportées dans `03_solution_partielle.R`

Afin de surmonter les limites du script `01_questionnaire_base.R` et de `shinyforms` :

### ✅ Ce que nous avons intégré :

-   🧭 **Navigation par onglet** : conservée pour la clarté
-   🧱 **Séparation claire en sections** avec `h3()` et `wellPanel()`
-   🎛️ **Champs vides par défaut**, même pour les `radioButtons`
-   ✅ **Validations supplémentaires** (ex : cohérence âge/niveau)
-   🎨 **Design personnalisé** : `bslib`, couleurs, structure, icônes
-   🧩 **Affichage conditionnel manuel** pour certaines questions
-   📦 **Stockage structuré** dans des listes R (facile à exporter)

------------------------------------------------------------------------

## 🧰 Dossier & structure du projet

```         
02_shinyforms/
│
├── 01_questionnaire_base.R        # Script de base shinyforms
├── 02_documentation.md            # Cette documentation
├── 03_solution_partielle.R        # Version améliorée (design, logique, validations)
├── responses_sectionI/            # Réponses Section I (auto-créé)
├── responses_sectionII/           # Réponses Section II (auto-créé)
├── Screenshots du Questionnaire à reproduire/
│   ├── 1.png
│   ├── 2.png
│   ├── 3.png
│   ├── 4.png
│   └── 5.png
└── Logo/
    ├── ANSD.jpg
    └── ENSAE.png
```

------------------------------------------------------------------------

## ✅ Conclusion

`shinyforms` est **plus robuste que `shinysurveys`** en termes de logique métier, mais reste limité pour des questionnaires complexes :

-   Idéal pour des formulaires **rapides, validés, administrables**
-   Moins adapté si vous souhaitez une interface **graphique riche, interactive et personnalisable**

Notre fichier `03_solution_partielle.R` montre **comment dépasser ces limites** tout en gardant la logique de base de shinyforms.
