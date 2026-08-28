# Development Guide

## Project Structure

```
schoonmelder-app/
├── frontend/              # React + Vite
├── backend/               # Node.js + Express
├── docs/                  # Documentation
└── docker-compose.yml     # Docker config
```

## Getting Started

1. Clone: `git clone https://github.com/serg556688-hash/schoonmelder-app.git`
2. Install: `npm install`
3. Copy `.env.example` to `.env`
4. Add Supabase credentials
5. Start: `npm run dev`

Frontend: http://localhost:5173
Backend: http://localhost:3000

## Frontend Development

- React 18 + Vite
- Tailwind CSS
- Supabase JS Client
- Lucide React icons

```bash
cd frontend
npm run dev
```

## Backend Development

- Express.js
- Supabase
- CORS
- JWT

```bash
cd backend
npm run dev
```

## Code Style

- 2 spaces indentation
- camelCase for variables
- PascalCase for components
- Descriptive names

## Commits

- `feat: add feature`
- `fix: fix bug`
- `docs: documentation`
- `refactor: refactor code`
