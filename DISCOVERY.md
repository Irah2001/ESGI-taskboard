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

## Étape 2 : Conteneurisation

### Analyse du problème

- Pourquoi conteneuriser une application Node.js ?
    - Isolation : Chaque conteneur fonctionne de manière isolée, ce qui réduit les conflits de dépendances et les problèmes de compatibilité.
    - Portabilité : Les conteneurs peuvent être exécutés sur n'importe quelle machine disposant d'un moteur de conteneurs (comme Docker), assurant une cohérence entre les environnements de développement, de test et de production.
    - Scalabilité : Les conteneurs permettent de facilement scaler horizontalement en dupliquant les instances selon la demande.
    - Gestion simplifiée : Les outils d'orchestration comme Kubernetes facilitent la gestion, le déploiement et la mise à jour des applications conteneurisées.

- Qu'est-ce qu'un « build reproductible » ?
Un build reproductible garantit que le même code source, avec les mêmes dépendances et configurations, produira toujours le même résultat binaire ou exécutable. Cela est crucial pour la fiabilité, la sécurité et la traçabilité des applications, car cela permet de s'assurer que les versions déployées sont exactement celles qui ont été testées.

### Comparatif : Choix de l'image de base Docker

| Image de base | Taille | Compatibilité & Support | Surface d'attaque (Sécurité) | Cas d'usage idéal |
| :--- | :--- | :--- | :--- | :--- |
| **`node:20`** | ~1 Go | **Maximale.** Basée sur un OS Debian complet. Contient tous les outils système (git, python, compilateurs). | **Très large.** Des centaines de paquets inutiles en production qui sont autant de failles potentielles. | Développement local ou builds très complexes. **À éviter en production.** |
| **`node:20-slim`** | ~200 Mo | **Très bonne.** Basée sur Debian allégé. Retire les outils lourds mais garde la librairie standard classique (`glibc`). | **Réduite.** Bon équilibre si l'application dépend de librairies complexes. | Applications utilisant des modules natifs C++ qui posent problème sur Alpine. |
| **`node:20-alpine`** | ~120 Mo | **Bonne.** Basée sur Alpine Linux. Utilise `musl` au lieu de `glibc`, ce qui peut (rarement) demander de recompiler certaines dépendances. | **Minime.** Très peu de paquets système inclus, image très légère. | **Le standard recommandé en production** pour 95% des API web (dont notre projet). |
| **`gcr.io/distroless/nodejs20`** | ~100 Mo | **Stricte.** Image conçue par Google contenant *uniquement* Node.js. Ne possède même pas de shell (`/bin/sh` ou `bash`). | **Excellente.** La surface d'attaque est la plus faible possible. | Environnements ultra-sécurisés (Défense, santé, banque). Impossible d'y entrer pour débugger. |

### Stratégie de build : Multi-stage vs Single-stage

**Single-stage** : On copie le code, on installe tout, on lance. Résultat : l'image finale contient les outils de compilation, le cache npm, et les devDependencies. C'est lourd et risqué.

**Multi-stage** : On utilise une première image pour installer et compiler (le "Builder"), puis on copie uniquement le résultat final dans une seconde image vierge (le "Runner"). C'est la norme en production.

### Sécurité de l'image

**Root vs Utilisateur dédié** : Par défaut, Docker exécute tout en tant que root. Si l'appli est piratée, le hacker est root dans le conteneur. Node fournit un utilisateur non privilégié nommé node qu'il faut explicitement activer.

**Lecture seule** : Le système de fichiers du conteneur ne devrait pas être modifiable par l'application (sauf un dossier /tmp si nécessaire).

**HEALTHCHECK** : Permet à Docker de savoir si l'appli est réellement capable de répondre à une requête HTTP, plutôt que de juste vérifier si le processus Node tourne (il pourrait être bloqué (deadlock)).

### Gestion des dépendances

`npm ci` vs `npm install` : `npm install` peut mettre à jour le fichier `package-lock.json`. `npm ci` (Clean Install) fait l'inverse : il supprime `node_modules` et installe strictement les versions figées dans le lockfile. C'est obligatoire pour un build reproductible.

**Cache Docker** : En copiant `package.json` et en lançant `npm ci` avant de copier le reste du code source, on indique à Docker de mettre en cache les dépendances. Ainsi, si on modifie juste du code métier, le build prendra 2 secondes au lieu de retélécharger tout internet.

## Étape 3 : Tests automatisés

### Analyse du problème

- Qu'est-ce que la pyramide des tests ? Quels types de tests existent ?
La pyramide des tests est un concept qui illustre la proportion idéale de différents types de tests dans une suite de tests automatisés. Elle se compose de trois niveaux principaux :
    - Tests unitaires (base de la pyramide) : Ils testent des fonctions ou des méthodes individuelles de manière isolée. Ils sont rapides à exécuter et faciles à écrire, mais ne garantissent pas que les différentes parties de l'application fonctionnent bien ensemble.
    - Tests d'intégration (milieu de la pyramide) : Ils testent l'interaction entre plusieurs composants ou modules. Ils sont plus lents que les tests unitaires, mais permettent de vérifier que les différentes parties de l'application fonctionnent correctement ensemble.
    - Tests end-to-end (sommet de la pyramide) : Ils testent l'application dans son ensemble, du point de vue de l'utilisateur final. Ils sont les plus lents et les plus coûteux à maintenir, mais offrent la meilleure garantie que l'application fonctionne comme prévu dans un environnement de production.

- Qu'est-ce que la couverture de code ? Est-ce un indicateur suffisant de la qualité des tests ?
La couverture de code est une métrique qui mesure le pourcentage de code source qui est exécuté lors de l'exécution des tests automatisés. Elle peut être mesurée à différents niveaux, tels que la couverture des lignes de code, la couverture des branches ou la couverture des fonctions. Bien que la couverture de code puisse fournir une indication de la quantité de code testée, elle n'est pas un indicateur suffisant de la qualité des tests. Un taux de couverture élevé ne garantit pas que les tests sont efficaces ou qu'ils couvrent tous les scénarios possibles. Il est possible d'avoir une couverture élevée avec des tests qui ne vérifient pas correctement les résultats attendus ou qui ne couvrent pas les cas d'erreur. Par conséquent, il est important d'utiliser la couverture de code en conjonction avec d'autres métriques et pratiques pour évaluer la qualité globale des tests.

- Comment tester une API REST ? Quels outils existent pour ça ?
Pour tester une API REST, il est important de vérifier que les différentes routes fonctionnent correctement, que les réponses sont conformes aux attentes et que les erreurs sont gérées de manière appropriée. Voici quelques outils populaires pour tester une API REST :
    - Postman : Un outil graphique qui permet de créer, organiser et exécuter des requêtes HTTP pour tester les API. Il offre également des fonctionnalités de scripting pour automatiser les tests.
    - Insomnia : Un autre client HTTP avec une interface utilisateur intuitive, similaire à Postman, qui permet de tester les API REST facilement.
    - Jest : Un framework de test JavaScript qui peut être utilisé pour écrire des tests unitaires et d'intégration pour une API Node.js. Il peut être combiné avec des bibliothèques comme Supertest pour tester les routes de l'API.
    - Mocha : Un autre framework de test JavaScript qui offre une grande flexibilité pour écrire des tests unitaires et d'intégration. Il peut également être utilisé avec Supertest pour tester les API REST.
    - Newman : Un outil en ligne de commande qui permet d'exécuter des collections Postman dans un environnement CI/CD, facilitant ainsi l'automatisation des tests d'API.

### Exploration de l'existant
- L'application utilise Jest pour les tests unitaires, avec une configuration de base dans le `package.json`. Les tests sont organisés dans le dossier `tests/unit` et couvrent principalement les fonctions utilitaires et les modèles de données.
- La couverture de code est mesurée à l'aide de `jest --coverage`, qui génère un rapport détaillé indiquant les lignes de code couvertes par les tests. Actuellement, la couverture globale est d'environ 60%, avec des zones critiques (comme les routes API) qui ne sont pas suffisamment testées.

Ce qui est testé (16 tests au total) :
- Unit tests (tests/unit/task.test.js) : Probablement la logique du modèle Task (validation de l'état "todo", "in-progress", etc.).

- Integration tests (tests/integration/api.test.js) :
    - /health : Vérifie que l'endpoint répond 200 (quand DB ok) et 503 (quand DB down).
    - /auth/login : Test de succès (200) et d'échec (401 Unauthorized, 400 Bad Request).
    - /tasks : Accès refusé sans token (401), récupération des tâches (200), création d'une tâche (201).

Ce qui manque (Les failles dans la couverture) :
- Pas de tests pour les routes PUT /tasks/:id et DELETE /tasks/:id.
- Pas de tests pour les cas d'erreur (ex: création de tâche sans titre, ou avec un token expiré).
- Pas de tests pour les middlewares d'authentification et de gestion d'erreur.
- Pas de tests end-to-end qui simulent un utilisateur réel interagissant avec l'API de bout en bout.

### Mise en place et Documentation des lacunes
- Ajouter des tests pour les routes PUT et DELETE, en vérifiant à la fois les cas de succès et d'échec (ex: mise à jour d'une tâche inexistante, suppression sans token).
- Ajouter des tests pour les middlewares, en simulant des requêtes avec des tokens invalides ou expirés, et en vérifiant que les erreurs sont correctement gérées.
- Mettre en place des tests end-to-end avec un outil comme Supertest ou Postman pour simuler des scénarios utilisateur complets, comme la création d'une tâche, sa mise à jour, et sa suppression, tout en vérifiant les réponses à chaque étape.

### Les failles critiques découvertes grâce aux 3 nouveaux tests :
- La faille d'injection SQL découverte sur la route GET /tasks?status= (utilisation de concaténation de chaînes au lieu de requêtes paramétrées).
- Le crash du serveur (Erreur 500) sur la route DELETE /tasks/:id lorsqu'on tentait de supprimer une tâche inexistante (absence de vérification de rowCount).
- Le manque de validation des données sur le PUT /tasks/:id (l'API acceptait n'importe quel statut invalide au lieu de renvoyer une 400).
