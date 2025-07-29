# Documentation Shinyforms

## 📌 Présentation générale

`shinyforms` est un package R qui permet de **créer des formulaires de type Google Form dans Shiny** en utilisant une syntaxe simple et des modules prêts à l’emploi. Il facilite la collecte de données utilisateur sans manipulation complexe du backend.

## 📌 Installation

Le package n’est pas disponible sur CRAN, il faut donc l’installer via GitHub :

```r
# install.packages("devtools")
devtools::install_github("daattali/shinyforms")
```

## 📌 Objectif du package

Développé par **Dean Attali**, `shinyforms` permet aux utilisateurs de Shiny de :

- Créer des formulaires simplement
- Gérer des réponses sauvegardées localement
- Ajouter des validations personnalisées
- Structurer des questionnaires complexes sans avoir à écrire du HTML ou du JavaScript

👉 Idéal pour des enquêtes, sondages, inscriptions, retours utilisateurs, etc.

---

## 📌 Exemple utilisé dans ce projet

Nous avons essayé de reproduire une partie du **questionnaire sur le choix des séries scientifiques en classe de 3ème à Dakar**, fourni sous forme papier, à l'aide de shinyforms.

### 🖼️ Questionnaire source :

![Page 1](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/1.png)  
![Page 2](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/2.png)  
![Page 3](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/3.png)  
![Page 4](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/4.png)  
![Page 5](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/5.png)

---

## 📌 Script Shinyforms utilisé

Nous avons utilisé ce script basé sur un exemple officiel pour reproduire le formulaire :

```r
library(shiny)
library(shinyforms)

questions <- list(
  list(id = "nom", type = "text", title = "Nom et prénom du répondant", mandatory = TRUE),
  list(id = "age", type = "numeric", title = "Quel est ton âge ?"),
  list(id = "nationalite", type = "text", title = "Es-tu de nationalité sénégalaise ?"),
  list(id = "avis", type = "text", title = "Quelle importance l'école a pour toi ?"),
  list(id = "terms", type = "checkbox", title = "Je confirme avoir répondu honnêtement")
)

formInfo <- list(
  id = "choixserie",
  questions = questions,
  storage = list(
    type = STORAGE_TYPES$FLATFILE,
    path = "responses"
  ),
  name = "Questionnaire - Choix des séries scientifiques",
  password = "shinyforms",
  reset = TRUE,
  validations = list(
    list(condition = "nchar(input$nom) >= 3", message = "Le nom doit contenir au moins 3 caractères"),
    list(condition = "input$terms == TRUE", message = "Vous devez accepter la condition")
  )
)

ui <- fluidPage(
  h2("Questionnaire - Choix des séries scientifiques"),
  formUI(formInfo)
)

server <- function(input, output, session) {
  formServer(formInfo)
}

shinyApp(ui = ui, server = server)
```

🗂️ **Remarque importante** : à chaque fois qu’un formulaire est exécuté, **un dossier de stockage local des réponses** est automatiquement créé selon le chemin défini dans `formInfo$storage$path`. Les réponses sont enregistrées dans ce dossier sous forme de fichiers `.csv`.

---

## 📌 Logos institutionnels

Nous avons prévu d’ajouter les **logos de l’ANSD** et de **l’ENSAE** au début du questionnaire.  
**❗ Limite actuelle : shinyforms ne permet pas d’insérer directement des images ou des éléments HTML dans l’interface du formulaire.**  
Ce point sera noté comme une limite importante du package.

---

## 📌 Fonctionnalités principales prises en charge

| Fonctionnalité                    | Supportée | Détails                                                                 |
|----------------------------------|-----------|------------------------------------------------------------------------|
| Champs obligatoires              | ✅         | Grâce à l’argument `mandatory = TRUE`                                  |
| Stockage des réponses            | ✅         | Via fichiers `.csv` dans un dossier dédié                              |
| Validations conditionnelles      | ✅         | À l’aide de `validations` : contrôle de la cohérence des saisies       |
| Multi-formulaires                | ✅         | Plusieurs formulaires dans un même app via `tabsetPanel()`             |
| Réinitialisation du formulaire   | ✅         | Possibilité d’ajouter un bouton `reset = TRUE`                         |
| Accès administrateur sécurisé    | ✅         | Accès aux réponses via l’URL `?admin=1` + mot de passe                 |

🆚 **À la différence de `shinysurveys`**, `shinyforms` permet de **mettre en place des contrôles de saisie personnalisés** (ex : plage d'âge, saisie numérique, cocher une case obligatoire). C’est un avantage essentiel dans la construction de formulaires robustes.

---

## 📌 Limites observées

Voici les limites constatées lors de notre projet :

- ❌ Pas de prise en charge des types `select`, `radio`, `dropdown`
- ❌ Pas de logique conditionnelle (questions qui apparaissent selon la réponse précédente)
- ❌ Pas de séparation visuelle claire des sections
- ❌ Pas de possibilité d’insérer des **images, logos ou contenus HTML personnalisés**
- ❌ Interface utilisateur peu personnalisable
- ❌ Stockage limité aux fichiers plats (`CSV`)

---

## 📌 Perspectives d’amélioration

Pour pallier les limitations, voici les suggestions à intégrer dans un système amélioré :

- ✅ Support de types supplémentaires : `select`, `radio`, `dropdown`, `date`, `slider`
- ✅ Gestion conditionnelle des questions
- ✅ Ajout de titres de sections, textes informatifs, et images
- ✅ Design personnalisable via CSS
- ✅ Support pour bases de données (ex. SQLite, PostgreSQL)
- ✅ Export PDF et visualisation des réponses directement dans l’interface

---

## 📌 Conclusion

`shinyforms` est une solution rapide et élégante pour créer des formulaires simples dans Shiny.  
Mais dans le cas de questionnaires complexes comme celui étudié ici, il reste limité.  
👉 Il s’agit d’un **excellent point de départ**, mais **des développements supplémentaires** sont requis pour un usage professionnel avancé.

Grâce aux fonctionnalités de validation et de stockage local, il constitue une **alternative plus robuste que `shinysurveys`** pour les projets nécessitant une logique de validation ou un encadrement plus strict de la saisie.

---

## 📌 Informations complémentaires

📂 Arborescence du projet :

```
02_shinyforms/
│
├── 01_questionnaire_base.R        # Script Shiny principal
├── 02_documentation.md            # Ce fichier de documentation
├── 03_solution_partielle.R        # Version partiellement améliorée
├── Screenshots du Questionnaire   # Captures du formulaire papier
└── Logo/
    ├── ANSD.jpg
    └── ENSAE.png
```
