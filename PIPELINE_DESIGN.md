# Conception de la Pipeline CI - Taskboard

## Événements déclencheurs (Triggers)
La pipeline s'exécutera sur :
- `push` sur la branche `main`
- `pull_request` ciblant la branche `main`

## Stages et Jobs

1. **Job 1 : `lint`**
   - **Objectif :** Vérifier la qualité du code.
   - **Commande :** `npm run lint`
   - **Dépendance :** Aucune (démarre immédiatement).

2. **Job 2 : `test`**
   - **Objectif :** Exécuter les tests et mesurer la couverture.
   - **Commande :** `npm run test:coverage`
   - **Artefact :** Sauvegarde du dossier `coverage/` pour consultation.
   - **Dépendance :** Aucune (tourne en parallèle du lint pour aller plus vite).

3. **Job 3 : `build-and-push`**
   - **Objectif :** Construire l'image Docker optimisée et la publier sur GHCR.
   - **Dépendances :** `needs: [lint, test]` (Ne s'exécute QUE si le code est propre et fonctionnel).
   - **Condition :** Le *push* sur le registry GHCR ne s'effectue **que si l'événement est un push sur `main`**. Sur une *pull request*, l'image est seulement buildée pour vérifier qu'elle compile.
   - **Optimisations :** Utilisation du cache npm et du cache Docker (BuildKit).
