# Mes Dépenses
Application Android Flutter hors ligne : Agricole, Magasin, Atelier, Autre. Ajout, modification, suppression et totaux automatiques. Données sauvegardées sur le téléphone.

## Compiler sur GitHub
Le workflow `.github/workflows/build-apk.yml` compile automatiquement l'APK après un push sur `main` ou `master`.
Dans **Actions**, ouvrir **Construire APK Android**, puis la compilation verte et télécharger l'artifact **Mes-Depenses-APK**. Extraire le ZIP et installer `app-debug.apk`.

## Installation du projet depuis un téléphone
Ajouter ces 4 fichiers dans le dépôt en respectant les chemins : `pubspec.yaml`, `lib/main.dart`, `.github/workflows/build-apk.yml`, `README.md`. Pour les sous-dossiers, GitHub permet **Add file > Create new file** et d'entrer le chemin complet. Le dépôt doit contenir au moins un commit sur la branche principale.
