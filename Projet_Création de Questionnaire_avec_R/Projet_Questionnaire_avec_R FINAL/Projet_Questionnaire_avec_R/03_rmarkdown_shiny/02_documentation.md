# Documentation — Méthode RMarkdown + Shiny

---

## 🧠 Objectif de la méthode

La méthode **RMarkdown + Shiny** combine la souplesse du langage Markdown avec la puissance interactive de Shiny. Elle permet de construire **des questionnaires dynamiques au sein d’un document HTML**, avec une structure simple, un rendu soigné et une exécution immédiate.

Ce mode est adapté lorsqu'on souhaite diffuser un formulaire interactif rapidement, sans créer une application Shiny complète. Il est idéal pour les **projets pédagogiques**, **prototypes d'enquête**, ou **petites collectes de données**.

---

## ⚙️ Fonctionnement général

Le fichier `.Rmd` repose sur trois éléments clés :

- **YAML header** : au début du fichier, il précise `runtime: shiny` et `output: html_document`
- **Blocs de code Shiny** : balises ` ```{r}` contenant les éléments interactifs (`textInput`, `radioButtons`, etc.)
- **Markdown classique** : pour structurer le contenu et ajouter du texte, des titres, des images...

Une fois le fichier prêt, il suffit de cliquer sur **Run Document** dans RStudio pour afficher l’application.

---

## 📸 Reproduction du questionnaire cible

Le formulaire ci-dessous est basé sur un **questionnaire d’enquête officiel** fourni par l’ANSD et l’ENSAE :

![Page 1](Screenshots%20du%20Questionnaire%20à%20reproduire/1.png)  
![Page 2](Screenshots%20du%20Questionnaire%20à%20reproduire/2.png)  
![Page 3](Screenshots%20du%20Questionnaire%20à%20reproduire/3.png)  
![Page 4](Screenshots%20du%20Questionnaire%20à%20reproduire/4.png)  
![Page 5](Screenshots%20du%20Questionnaire%20à%20reproduire/5.png)

Notre reproduction intègre :

- ✅ L’affichage conditionnel dynamique (ex: question sur la nationalité)
- ✅ Des boutons radios et menus déroulants fidèles au support original
- ✅ Un **message de confirmation modal** à la fin
- ✅ L’insertion de logos institutionnels (`www/ANSD.jpg`, `www/ENSAE.png`)

---

## ✅ Avantages identifiés

| Avantage | Détail |
|---------|--------|
| 🚀 **Rapidité de mise en œuvre** | Quelques lignes suffisent pour créer une interface fonctionnelle |
| 📂 **Fichier unique** | Tout est contenu dans un `.Rmd` (pas besoin de `ui.R`/`server.R`) |
| 💄 **Facilité de mise en forme** | Markdown natif + composants Shiny |
| 🧠 **Composants dynamiques** | `conditionalPanel`, `modalDialog`, `selectInput`, etc. |
| 🧼 **Code masqué à l'utilisateur** | Avec `echo = FALSE` |
| 🖼️ **Ajout d’images/logos** | Dossier `www/` ou balises HTML `<img>` |
| 🌐 **Déploiement web facile** | Compatible Rpubs / shinyapps.io sans modification |

---

## ❌ Limites observées

| Limite | Détail |
|--------|--------|
| ❌ **Pas de sauvegarde automatique** | Les réponses ne sont pas stockées sans `write.csv()` ou base externe |
| 🔁 **Pas de navigation multipages** | Pas de gestion native de sections ou d'étapes |
| 🧪 **Pas de validation avancée** | Il faut coder manuellement les contraintes |
| 🔐 **Pas de gestion des utilisateurs** | Aucun système de login/session |
| 🎨 **Design limité** | Personnalisation CSS manuelle et peu intuitive |
| 🧵 **Dépendance forte à RStudio** | Lancement local ou via serveur requis |

---

## 🔧 Améliorations proposées

Pour aller plus loin, notre version partielle inclura :

- 💾 Export automatique vers `.csv` à chaque soumission
- 🛡️ Vérification de saisie : champs requis, longueur minimale
- 📝 Ajout de champs `textarea`, `checkboxGroupInput`
- 🧾 Génération automatique d’un résumé des réponses
- 🕒 Ajout d’un horodatage et identifiant anonyme

---

## 📌 Conclusion

Cette méthode offre une solution **simple, rapide et accessible** à toute personne souhaitant construire des formulaires interactifs dans R. Bien que limitée pour des projets complexes, elle constitue un excellent compromis entre rigueur et facilité.

Elle permet également d’**enseigner les principes de base de Shiny** à travers un exemple concret, visuel, et orienté utilisateur.

Elle sera utilisée ici comme **solution de référence pédagogique**, avant la transition vers des outils plus robustes.

