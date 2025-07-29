# 📋 Documentation – Implémentation du questionnaire via `shinysurveys`

## 🎯 Objectif

L’objectif de cette étape est de reproduire une portion du **questionnaire utilisé dans l’Enquête sur le Choix des Séries Scientifiques en classe de 3e à Dakar**, à l’aide du package `shinysurveys` dans R.

Ce travail permet d’évaluer la capacité de cet outil à transposer fidèlement un questionnaire structuré, destiné à la collecte de données statistiques, dans un environnement numérique interactif.

---

## 🗂️ Questionnaire reproduit

Nous avons sélectionné une portion représentative du questionnaire original comprenant :

- 🏫 Informations sur l’établissement scolaire
- 🧍‍♂️ Section I – Identification du répondant
- 📚 Section II – Profil académique de l’élève

📸 **Images du questionnaire original reproduit :**

![Page 1 – Établissement](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/1.png)
![Page 2 – Identification du répondant](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/2.png)
![Page 3 – Profil académique (1)](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/3.png)
![Page 4 – Profil académique (2)](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/4.png)
![Page 5 – Préférences](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/5.png)

Ces images ont servi de référence visuelle et logique pour juger la fidélité du rendu numérique.

---

## 🛠️ Fonctionnement de `shinysurveys`

Le package `shinysurveys` permet de concevoir un questionnaire dans R en définissant un simple tableau (`data.frame`) de questions, chaque ligne correspondant à un champ du formulaire.

Champs clés :
- `question` : texte affiché
- `input_id` : nom de la variable
- `input_type` : type de champ (`text`, `select`, `numeric`, etc.)
- `option` : options séparées par `;` si `input_type = select`
- `required` : champ obligatoire ou non
- `dependence` et `dependence_value` : conditions d'affichage simples

📄 **Script utilisé** : `01_questionnaire_base.R`  
💬 **Fonction de récupération des réponses** : `parseSurveyData()`

---

## ✅ Fonctionnalités bien prises en charge

| Fonctionnalité | Supportée | Détail |
|----------------|-----------|--------|
| 🔢 Questions à choix | ✅ | Menus déroulants (`select`) simples |
| ✅ Champs requis | ✅ | Contrôle via `required = TRUE` |
| 🔄 Affichage conditionnel | ✅ | Possible avec dépendance simple (ex : si A = Oui, afficher B) |
| 🧾 Récupération des données | ✅ | Les réponses sont stockées sous forme de `data.frame` |
| 🚀 Rapidité de prototypage | ✅ | L’outil est très rapide à prendre en main |

---

## ❌ Limites observées

### 1. 🚫 Pas de séparation visuelle par section

- 🔍 Dans le questionnaire original : sections distinctes avec titres et encadrés (`Section I`, `Section II`)
- ❌ Dans `shinysurveys` : toutes les questions sont empilées sans structure visuelle

### 2. 🧩 Choix toujours en menu déroulant

- 🔍 Dans le questionnaire : boutons radio et cases à cocher pour les questions binaires ou courtes
- ❌ Dans `shinysurveys` : tout s'affiche sous forme de `select`, ce qui ralentit la lecture et la réponse

### 3. 🧭 Absence de logique conditionnelle avancée

- 🔍 Certaines questions du type "Si Oui, passez à..." (comme I.4)
- ❌ Aucune gestion de saut de question ou section entière

### 4. 🖼️ Zéro personnalisation visuelle

- ❌ Impossible d’ajouter titres, encadrés, zones de texte personnalisées, commentaires
- ❌ Pas de possibilité d’indiquer des instructions ou observations libres

### 5. 🧱 Affichage monolithique

- ❌ L’ensemble du formulaire est visible d’un coup
- ❌ Pas de navigation étape par étape, ni de pagination, ce qui nuit à l’expérience utilisateur pour les questionnaires longs

---

## 🔍 Analyse : input vs. output

| Élément | Questionnaire original | Rendu `shinysurveys` |
|--------|--------------------------|------------------------|
| 🧩 Structure par section | Oui | Non |
| 🎯 Logique de navigation | Présente (sauts conditionnels) | Absente |
| 🎛️ Type de questions | Variés (radio, cases, texte, etc.) | Tous en `select` ou `text` |
| 🎨 Esthétique | Structurée, hiérarchisée | Linéaire, brute |
| 📱 Ergonomie | Pensée pour enquêteur | Pensée pour test rapide |

---

## 🔧 Limites à corriger dans la solution partielle

Notre fichier `03_solution_partielle.R` corrige déjà certaines limites :
- ✅ Organisation en sections avec `wellPanel()`, `h3()`, `fluidRow()`
- ✅ Questions avec `radioButtons()` au lieu de menus déroulants
- ✅ Affichage conditionnel via `conditionalPanel()`

Mais certaines limites persistent :
- ❌ Pas de saut de **bloc ou de section complète**
- ❌ Pas de **validation contextuelle avancée**
- ❌ Pas de **navigation multi-étapes**
- ❌ Pas d'export structuré ou de sauvegarde de session

### 6. ❌ Absence de contrôles de saisie avancés

- 🔍 Dans un vrai questionnaire, certaines réponses doivent être validées selon leur cohérence (ex : un âge compatible avec un rôle, ou une moyenne réaliste)
- ❌ `shinysurveys` ne permet pas de **bloquer la soumission** ou **d’afficher une erreur** si une réponse est incohérente avec une autre
- ❌ Aucune logique de vérification croisée n’est intégrée (ex : "si âge < 13 alors impossible d’avoir une moyenne en 3e", ou "si sexe = Femme alors rôle ≠ Père")
- 🔒 Il n’existe pas de mécanisme pour ajouter des règles de validation personnalisées basées sur la logique métier du questionnaire


---

## 🚀 Perspectives d'amélioration

Pour aller plus loin, voici les fonctionnalités à envisager pour concevoir une solution complète et robuste :

### 1. 🧱 Modularisation par section
- Chaque section devient un module Shiny distinct (ex. module_identification, module_profil_academique)
- Possibilité de charger dynamiquement les blocs selon les réponses

### 2. 🧭 Navigation conditionnelle
- Intégration de `shiny.router`, `navbarPage()` ou logique d’onglets conditionnels
- Affichage d’une section uniquement si la logique l’autorise

### 3. 🖼️ Amélioration de l’interface
- Ajout de `shinyWidgets`, `shiny.semantic` ou `shinymaterial` pour une présentation plus fluide et esthétique
- Composants comme `sliderInput`, `dateInput`, `textAreaInput` pour enrichir les champs

### 4. 💾 Sauvegarde des réponses
- Export en `.csv` ou `.json`
- Option de sauvegarde locale ou vers une base de données distante

### 5. 🔒 Expérience complète
- Authentification par enquêteur
- Système de progression, validation d’étape, relance des sessions

---

## 🧠 Conclusion

`shinysurveys` est un outil utile pour prototyper rapidement un questionnaire, mais il reste limité pour des usages statistiques réels. L’objectif de ce travail est de poser les bases d’une **solution évolutive**, en testant d’abord les limites d’un outil existant, puis en construisant progressivement une application plus complète, modulaire et réaliste.

Cette démarche nous permet de mieux comprendre les exigences liées à la conception de questionnaires complexes, tout en structurant les solutions techniques de manière progressive.
