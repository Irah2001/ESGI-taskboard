# Fil rouge — Pipeline CI/CD, Observabilité & Sécurité - Taskboard

## Prise en main de l'application

1. Analyse de l'écosystème et Dépendances

- L'application repose sur un écosystème Node.js standard pour une API RESTful selon les dépendances du projet dans le `package.json``

- Variables d'environnement nécessaires : 
    - `PORT` : Le port d'écoute du serveur (par défaut : 3000)
    - `DATABASE_URL` : L'URL de connexion à la base de données PostgreSQL
    - `JWT_SECRET` : La clé secrète pour les tokens JWT

- Services externes requis :
    - PostgreSQL (v14+) : La base de données relationnelle est indispensable au fonctionnement de l'API (stockage des utilisateurs et des tâches).
    - Node.js (v18+) : L'environnement d'exécution du serveur.

- Scripts disponibles (package.json)
    - `npm start` : Lance le serveur en production (node src/server.js).
    - `npm run dev` : Lance le serveur en mode développement avec redémarrage automatique (node --watch src/server.js).
    - `npm test` : Lance les tests unitaires.
    - `npm run test:coverage`: Lance les tests et génère un rapport de couverture de code.
    - `npm run lint` : Vérifie le code avec ESLint.

2. Observations et Problèmes de sécurité évidents

- Identifiants par défaut codés en dur / créés automatiquement
- Logging sensible : Les logs de tests montrent `User logged in: admin`
- Couplage fort et gestion d'erreur DB : Les logs de tests montrent une erreur Health check failed: Connection refused entraînant une réponse HTTP 503. Bien que le code HTTP soit correct, cela indique que l'application plante ou devient indisponible si la base de données est injoignable

3. Premières Hypothèses

Architecture : L'application suit un modèle MVC (Modèle-Vue-Contrôleur) simplifié via des routeurs Express (`src/routes`), des modèles de données (`src/models`), et des middlewares dédiés pour l'authentification et les erreurs.

## Étape 1 — Gestion des secrets

### Analyse du problème

- Dans le contexte d'une application web, un secret est une information hautement confidentielle qui permet à l'application de prouver son identité, d'accéder à des ressources protégées ou de chiffrer des données.

- L'intégration de secrets dans le système de contrôle de version (Git), même au sein d'un dépôt configuré comme privé, constitue une vulnérabilité critique pour les raisons suivantes:
    - Violation du principe de moindre privilège
    - Multiplication des vecteurs d'attaque
    - Risque lié aux outils tiers (CI/CD)
    - Risque d'erreur de configuration

- Détection de la fuite de secrets dans l'historique Git:
    - L'analyse de l'historique local : L'utilisation de scanners spécialisés comme TruffleHog ou Gitleaks
    - L'analyse continue (Solutions intégrées) : L'activation de fonctionnalités telles que GitHub Advanced Security ou l'intégration d'outils comme GitGuardian

- Supprimer le fichier contenant les secrets et créer un nouveau commit de suppression ne remédie pas à la compromission: Conservation dans l'historique et accessibilité persistante

### Solutions à identifier et comparer

1. Variables système (OS/Docker)

    Comment ça marche : Variables injectées directement au démarrage du serveur ou du conteneur.

    Le + : Aucun fichier sensible sur le disque (standard de l'industrie).

    Le - : Pénible à synchroniser entre développeurs en local.

    Quand l'utiliser : Applications conteneurisées (Docker) ou serveurs Linux simples.

2. Fichier .env (avec .gitignore)

    Comment ça marche : Un fichier texte local, strictement ignoré par Git pour ne pas être envoyé en ligne.

    Le + : Ultra simple et ergonomique pour le développement au quotidien.

    Le - : Repose sur l'humain. Un oubli du .gitignore et c'est la fuite.

    Quand l'utiliser : Uniquement en développement local. À bannir totalement en production.

3. Secrets GitHub Actions (CI/CD)

    Comment ça marche : Mots de passe stockés et chiffrés directement dans les paramètres GitHub.

    Le + : Parfaitement intégré pour automatiser les tests et les déploiements de façon sécurisée.

    Le - : Limité à l'écosystème GitHub, ne gère pas la production ni le local.

    Quand l'utiliser : Pour donner des accès temporaires à vos pipelines de déploiement automatique.

4. SOPS (GitOps)

    Comment ça marche : Outil qui chiffre uniquement les valeurs (pas les clés) d'un fichier de config, qu'on peut ensuite envoyer sur Git sans risque.

    Le + : Permet de versionner toute son infrastructure de manière sécurisée.

    Le - : Complexe à configurer (nécessite une gestion de clés de chiffrement maîtresses).

    Quand l'utiliser : Équipes matures utilisant Kubernetes et une approche "GitOps".

5. HashiCorp Vault

    Comment ça marche : Un véritable serveur tiers qui agit comme un coffre-fort ultra-blindé.

    Le + : Sécurité de niveau militaire (peut même générer des mots de passe temporaires valables 1h).

    Le - : C'est une usine à gaz à déployer et à maintenir.

    Quand l'utiliser : Très grandes entreprises, banques, ou architectures microservices massives.

6. Cloud Secret Managers (AWS, GCP)

    Comment ça marche : Le coffre-fort est directement géré par votre fournisseur Cloud (Amazon, Google).

    Le + : Zéro maintenance, ultra sécurisé, rotation automatique des clés.

    Le - : Payant (à l'usage) et vous rend dépendant d'un fournisseur cloud précis.

    Quand l'utiliser : Le meilleur compromis pour la production si votre application est hébergée sur le Cloud.
