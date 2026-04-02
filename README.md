# Taskboard

Application web de gestion de tâches construite avec Node.js, Express et PostgreSQL.

## Prérequis

- **Node.js** v18 ou supérieur
- **PostgreSQL** v14 ou supérieur
- **npm** v9 ou supérieur

## Installation

### 1. Cloner le dépôt

```bash
git clone <url-du-depot>
cd taskboard
```

### 2. Installer les dépendances

```bash
npm install
```

### 3. Configurer la base de données

Créez une base de données PostgreSQL :

```bash
createdb taskboard
```

Ou via `psql` :

```sql
CREATE USER taskboard WITH PASSWORD 'taskboard123';
CREATE DATABASE taskboard OWNER taskboard;
```

### 4. Configurer les variables d'environnement

Copiez le fichier d'exemple et ajustez les valeurs si nécessaire :

```bash
cp .env.example .env
```

Variables disponibles :

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `PORT` | Port du serveur | `3000` |
| `DATABASE_URL` | URL de connexion PostgreSQL | — |
| `JWT_SECRET` | Clé secrète pour les tokens JWT | — |

### 5. Lancer l'application

```bash
npm start
```

L'application est accessible sur [http://localhost:3000](http://localhost:3000).

Au premier démarrage, la base de données est initialisée automatiquement et un utilisateur par défaut est créé :

- **Nom d'utilisateur :** `admin`
- **Mot de passe :** `admin123`

## Scripts disponibles

| Commande | Description |
|----------|-------------|
| `npm start` | Démarre le serveur |
| `npm run dev` | Démarre le serveur en mode watch (redémarrage automatique) |
| `npm test` | Lance les tests |
| `npm run test:coverage` | Lance les tests avec rapport de couverture |
| `npm run lint` | Vérifie le code avec ESLint |

## API

### Authentification

| Méthode | Route | Description |
|---------|-------|-------------|
| `POST` | `/auth/login` | Authentification, retourne un token JWT |

**Corps de la requête :**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Réponse :**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": { "id": 1, "username": "admin" }
}
```

### Tâches

Toutes les routes `/tasks` nécessitent un header `Authorization: Bearer <token>`.

| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/tasks` | Lister les tâches (filtre optionnel `?status=todo`) |
| `POST` | `/tasks` | Créer une tâche |
| `PUT` | `/tasks/:id` | Modifier une tâche |
| `DELETE` | `/tasks/:id` | Supprimer une tâche |

**Exemple de création :**
```json
{
  "title": "Ma tâche",
  "description": "Description optionnelle",
  "status": "todo"
}
```

Statuts possibles : `todo`, `in-progress`, `done`

### Monitoring

| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/health` | Vérification de l'état de l'application |
| `GET` | `/metrics` | Métriques Prometheus (à implémenter) |

## Structure du projet

```
taskboard/
├── src/
│   ├── app.js           # Configuration Express
│   ├── server.js        # Point d'entrée
│   ├── db.js            # Connexion PostgreSQL
│   ├── routes/
│   │   ├── auth.js      # Routes d'authentification
│   │   └── tasks.js     # Routes CRUD des tâches
│   ├── models/
│   │   ├── task.js      # Modèle Task
│   │   └── user.js      # Modèle User
│   └── middleware/
│       ├── auth.js      # Vérification JWT
│       ├── logging.js   # Logging des requêtes
│       └── errors.js    # Gestion des erreurs
├── public/              # Frontend statique
├── tests/
│   ├── unit/            # Tests unitaires
│   └── integration/     # Tests d'intégration
├── db/
│   └── init.sql         # Schéma de la base de données
├── package.json
├── .env.example
└── README.md
```

## Technologies

- **Runtime :** Node.js
- **Framework :** Express
- **Base de données :** PostgreSQL
- **Authentification :** JWT (jsonwebtoken)
- **Hash des mots de passe :** bcryptjs
- **Tests :** Jest + Supertest
- **Linter :** ESLint
