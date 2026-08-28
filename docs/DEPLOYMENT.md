# Deployment Guide

## Frontend Deployment (Vercel)

1. Go to https://vercel.com
2. Import your GitHub repository
3. Add environment variables:
```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your_anon_key
VITE_API_URL=https://your-backend-url.com
```
4. Deploy

## Backend Deployment (Render or Railway)

### Render
1. Go to https://render.com
2. Click "New Web Service"
3. Connect GitHub repository
4. Build: `npm install`
5. Start: `node src/index.js`
6. Add environment variables
7. Deploy

### Railway
1. Go to https://railway.app
2. New project
3. Connect GitHub
4. Add variables
5. Deploy

## Environment Variables

**Backend:**
```
PORT=3000
NODE_ENV=production
SUPABASE_URL=your_url
SUPABASE_SERVICE_ROLE_KEY=your_key
JWT_SECRET=your_secret
CORS_ORIGIN=your_frontend_url
```

**Frontend:**
```
VITE_SUPABASE_URL=your_url
VITE_SUPABASE_ANON_KEY=your_key
VITE_API_URL=your_backend_url
```
