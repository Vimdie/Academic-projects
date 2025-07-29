# 📋 Documentation – Implémentation du questionnaire via `shinysurveys`

## 🎯 Objectif

Cette première phase vise à évaluer la capacité du package `shinysurveys` à reproduire, dans un environnement interactif, un **questionnaire réel structuré** utilisé dans le cadre de l’**Enquête sur le Choix des Séries Scientifiques en classe de 3e à Dakar**.

L’objectif n’est pas uniquement de transposer le questionnaire sous forme numérique, mais aussi de tester les **capacités de modélisation logique, de mise en forme visuelle et d’expérience utilisateur** du package dans un contexte de collecte de données statistiques exigeant.

---

## 🗂️ Contenu du questionnaire reproduit

La version implémentée dans `01_questionnaire_base.R` reprend les trois premières pages du questionnaire papier original, à savoir :

- 🏫 **Informations sur l’établissement scolaire**
- 🧍‍♂️ **Section I – Identification du répondant**
- 📚 **Section II – Profil académique de l’élève**

Ces sections couvrent des variables de typologies diverses :
- Textuelles (nom, IEF, observations)
- Numériques (âge, moyenne)
- Choix fermés (sexe, nationalité, type d’établissement)
- Champs conditionnels dépendant d'une réponse précédente

> **📌 Images du questionnaire original scanné** :  
> ![Page 1 – Établissement](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/1.png)  
> ![Page 2 – Identification du répondant](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/2.png)  
> ![Page 3 – Profil académique (1)](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/3.png)  
> ![Page 4 – Profil académique (2)](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/4.png)

---

## 🛠️ Fonctionnement technique de `shinysurveys`

Le cœur de `shinysurveys` repose sur une **logique déclarative**, où le questionnaire est défini dans un `data.frame` de structure bien définie. Chaque ligne de ce tableau représente une question ou un champ, avec des attributs précis :

| Colonne             | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `question`          | Texte de la question affiché à l’utilisateur                                |
| `input_id`          | Identifiant interne utilisé pour la récupération des réponses               |
| `input_type`        | Type d’entrée utilisateur : `text`, `select`, `numeric`, `slider`, etc.     |
| `option`            | Si `input_type = select`, liste des choix séparés par `;`                   |
| `required`          | Booléen (`TRUE` ou `FALSE`) indiquant si le champ est obligatoire            |
| `dependence`        | Input ID d’une question parent (affiche cette question si condition remplie) |
| `dependence_value`  | Valeur exacte de la question parent qui déclenche l’affichage                |

**💡 Avantage majeur** : tout le formulaire est structuré de manière centralisée, facilitant la maintenance, la réutilisation, et les itérations rapides du formulaire.

---

## 📄 Structure du script `01_questionnaire_base.R`

Le script se compose de plusieurs parties :

1. **Chargement des packages nécessaires**
   - Installation conditionnelle et chargement automatique (`shiny`, `bslib`, `shinyjs`, `shinysurveys`)

2. **Déclaration du tableau de questions**
   - Encodage manuel de toutes les questions, options, dépendances et types de champ
   - Gestion manuelle des exceptions (`text` utilisé à la place de `date`, car `shinysurveys` ne le prend pas en charge nativement)

3. **Interface utilisateur (UI)**
   - Application de thèmes personnalisés (`bs_theme` avec Google Fonts)
   - Bloc central contenant le questionnaire via `surveyOutput()`
   - Bouton de soumission et affichage conditionnel des réponses

4. **Serveur**
   - Rendu automatique du formulaire via `renderSurvey()`
   - Récupération des réponses avec `getSurveyData()`
   - Stockage dans une variable globale `collected_responses`
   - Affichage dans la console et dans l’application via `verbatimTextOutput`

---

## ✅ Fonctionnalités prises en charge

| Fonctionnalité                       | Supportée | Détail                                                                 |
|-------------------------------------|-----------|------------------------------------------------------------------------|
| 🔢 Questions à choix fermés         | ✅        | Via `input_type = select`                                             |
| 🧾 Champs libres ou numériques      | ✅        | Via `text`, `numeric`, etc.                                           |
| 🔄 Affichage conditionnel           | ✅        | Affichage basé sur dépendance simple (ex : nationalité ≠ sénégalaise) |
| 📋 Champs obligatoires              | ✅        | Gérés via `required = TRUE`                                           |
| 🧠 Prototypage rapide               | ✅        | Un seul tableau de définition suffit pour générer l’ensemble du formulaire |
| 💾 Export des données               | ✅        | Format `data.frame`, stockable dans l’environnement R ou exportable   |

---

## ❌ Limites observées dans cette version

### 1. 🌐 Absence de structuration visuelle par section
Toutes les questions sont affichées à la suite, sans titre de section ou séparation logique (ex : pas de “SECTION I”, “SECTION II”).

### 2. 🧩 Uniformisation des types d’entrée
- Questions Oui/Non ou mono-réponses sont présentées en menu déroulant, même quand des `radioButtons` seraient plus adaptés.
- Les interfaces sont donc moins intuitives pour les enquêteurs.

### 3. 🧭 Navigation linéaire obligatoire
- Pas de pagination ou de progression étape par étape.
- Aucune logique de saut de bloc ou de contournement de sections entières.

### 4. 🔒 Aucune logique de validation avancée
- Ex : impossible de déclencher une alerte si la moyenne est incohérente avec l’âge.
- Pas de vérification croisée entre les champs.

### 5. 💄 Personnalisation esthétique très limitée
- Impossible d’ajouter des titres intermédiaires ou des commentaires contextuels.
- Mise en forme visuelle très basique malgré l’utilisation de `bs_theme`.

---

## 🔍 Comparatif – Papier vs. Interface numérique

| Élément                     | Version papier                        | Rendu avec `shinysurveys`             |
|-----------------------------|----------------------------------------|----------------------------------------|
| 🧱 Structure en sections     | Très claire (I, II, III...)            | Absente                                |
| 🧩 Variété des champs        | Cases à cocher, menus, textes libres   | Menus déroulants ou champs texte       |
| 🧭 Logique de navigation     | Instructions “passez à...” présentes   | Impossible à reproduire                |
| 🖼️ Présentation visuelle     | Lisibilité optimisée                   | Présentation linéaire                  |
| 🧠 Adapté aux enquêteurs     | Oui                                    | Partiellement                          |

---

## 🧪 Intérêt de cette étape

- **Valider rapidement un socle technique** avec un outil standardisé
- **Identifier les limitations concrètes** pour les adapter ou les contourner
- **Fournir un point de comparaison** avec des implémentations futures plus avancées (`03_solution_partielle.R`, `04_solution_finale`)

---

## 🚀 Perspectives d’amélioration

Les prochaines versions viseront à corriger ces limites à l’aide de `Shiny` natif et de modules personnalisés :

1. **Modularisation du questionnaire**
   - Découper chaque section en modules `Shiny` indépendants
   - Navigation conditionnelle possible avec `shiny.router` ou `tabsetPanel()`

2. **Amélioration visuelle**
   - Ajout de titres, encadrés, et composants modernes (`shinyWidgets`, `shinydashboard`, etc.)

3. **Validation métier**
   - Intégration de règles personnalisées selon la cohérence des réponses

4. **Sauvegarde et export**
   - Possibilité d’export en `.csv` ou vers des bases de données (MongoDB, SQLite…)

5. **Authentification et suivi**
   - Ajout d’un identifiant enquêteur
   - Suivi de progression, relance d’interview, reprise de session

---

## 🧠 Conclusion

Le package `shinysurveys` est adapté pour des prototypes rapides, simples et fonctionnels. En revanche, sa rigidité dans la mise en page, la gestion des types de réponses et la logique métier le rend peu adapté aux enquêtes de terrain complexes.

Ce premier script nous permet de tester ses capacités et de poser les bases pour une **solution modulaire évolutive**, plus proche des exigences professionnelles d’un dispositif de collecte comme ceux de l’ANSD.

---
