# 📄 Documentation – Méthode 04_Shiny_Markdown

------------------------------------------------------------------------

## 🧠 Objectif de la méthode

La méthode **`04_shiny_markdown`** vise à construire un questionnaire Shiny robuste et esthétique, sans dépendre d’un package externe comme `shinyforms` ou `shinysurveys`.

Elle a pour but de : - Structurer le formulaire en **sections claires** via des onglets - Ajouter une **logique conditionnelle dynamique** - Intégrer une **validation métier avancée** (cohérence, contraintes) - Fournir un **design moderne** et institutionnel (logos, couleurs, encadrés) - Conserver la **modularité** et la **simplicité de maintenance**

Ce modèle constitue **l’aboutissement logique** après avoir testé les limites de `shinysurveys` (01) et `shinyforms` (02).

------------------------------------------------------------------------

## 🗂️ Questionnaire reproduit

Le formulaire reproduit les pages suivantes du questionnaire papier utilisé pour l’enquête sur le choix des séries scientifiques à Dakar :

![Page 1](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/1.png)\
![Page 2](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/2.png)\
![Page 3](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/3.png)\
![Page 4](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/4.png)\
![Page 5](Screenshots%20du%20Questionnaire%20%C3%A0%20reproduire/5.png)

------------------------------------------------------------------------

## ⚙️ Fonctionnement du script `03_solution_partielle.R`

Le script est construit comme une **application Shiny complète** avec :

-   Un design personnalisé (`CSS` via `tags$style`)
-   Deux **onglets principaux** : Identification & Profil académique
-   Des composants adaptés (`radioButtons`, `selectInput`, `conditionalPanel`)
-   Une logique de validation structurée :
    -   âge minimal
    -   cohérence entre moyennes
    -   obligation de réponse selon contexte
-   Un affichage des réponses après soumission
-   Un message de confirmation (`modalDialog`)
-   L'intégration de logos institutionnels (`ANSD.jpg`, `ENSAE.png`)

------------------------------------------------------------------------

## 🧠 Comparatif des scripts `03_solution_partielle.R` des trois méthodes

| Critère                               | `01_shinysurveys`     | `02_shinyforms`     | `04_shiny_markdown` ✅                        |
|--------------------------|----------------|----------------|----------------|
| 🔄 Navigation par onglets             | ❌                    | ✅                  | ✅                                            |
| 📐 Sections visuelles claires         | ❌                    | ✅ (formUI séparés) | ✅ (`wellPanel`, titres)                      |
| 🧠 Validation cohérente des réponses  | ❌                    | ✅ (simple)         | ✅ (âge, progression, logique conditionnelle) |
| 💬 Affichage conditionnel             | ❌                    | ❌                  | ✅                                            |
| 🎨 Design soigné                      | ❌ brut               | ❌ brut             | ✅ (moderne, responsive, structuré)           |
| 🖼️ Logos officiels                    | ❌                    | ❌                  | ✅ (en-tête ANSD + ENSAE)                     |
| 🎛️ Types d’inputs personnalisés       | ❌ (`select` partout) | ❌ limité à 3 types | ✅ adaptés à chaque question                  |
| 📥 Message de confirmation            | ✅                    | ✅                  | ✅ (modalDialog élégant)                      |
| 🧾 Affichage ou stockage des réponses | ✅ (console)          | ✅ (CSV local)      | ✅ (console, modifiable pour CSV ou DB)       |
| 🔧 Modularité pour évolution future   | ❌                    | ⚠️ moyennement      | ✅ excellente                                 |

------------------------------------------------------------------------

## ✅ Avantages spécifiques à `04_shiny_markdown`

| Atout                             | Détail                                                     |
|----------------------------------|--------------------------------------|
| 🧱 Organisation claire            | Onglets, titres, séparation logique des blocs              |
| 🎨 Expérience utilisateur soignée | Couleurs, ombres, marges, police, icônes                   |
| 🧠 Intégration métier             | Âge minimum, progression réaliste, questions contextuelles |
| 🧩 100% personnalisable           | CSS, HTML, composants Shiny à volonté                      |
| 🖼️ Intégration institutionnelle   | Logos, structure pro, image sérieuse                       |
| 📦 Aucune dépendance externe      | Pas de package `shinysurveys` ou `shinyforms` requis       |
| 🚀 Prêt à l’emploi                | Fonctionne en local ou déployable sur shinyapps.io         |

------------------------------------------------------------------------

## 📂 Structure du dossier

```         
04_shiny_markdown/
│
├── 01_questionnaire_base.R        # Version minimaliste (style RMarkdown)
├── 02_documentation.md            # Ce fichier de documentation
├── 03_solution_partielle.R        # Version complète avec design et logique
├── Screenshots du Questionnaire à reproduire/
│   ├── 1.png
│   ├── 2.png
│   ├── 3.png
│   ├── 4.png
│   └── 5.png
└── www/
    ├── ANSD.jpg
    └── ENSAE.png
```

------------------------------------------------------------------------

## 🧠 Conclusion

La méthode `04_shiny_markdown` représente la **synthèse des points forts** des méthodes `shinysurveys` et `shinyforms`, tout en **corrigeant toutes leurs limites majeures** :

-   ✅ Meilleure interface
-   ✅ Meilleure logique métier
-   ✅ Meilleure modularité
-   ✅ Meilleur rendu professionnel

Elle constitue désormais **la version la plus aboutie du questionnaire**, prête à être utilisée en conditions réelles ou pour des démonstrations de qualité.
