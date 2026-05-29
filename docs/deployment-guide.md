# Deployment Guide — Prani Doctor

**Version:** 1.0 · Phase 6

## Prerequisites

- Node 20+, Docker 24+
- Filled `.env` from `.env.production.example` (per repo)
- TLS certificates on reverse proxy

## Backend API

```bash
cd pranidoctor-backend
cp .env.production.example .env
# Edit secrets, DATABASE_URL, JWT keys, API_DOCS_KEY, METRICS_TOKEN

npm run docker:up
npm run db:migrate:deploy
docker compose -f docker-compose.yml -f docker-compose.prod.yml --profile production up -d --build
```

Health: `GET https://api.example.com/health`  
Ready: `GET https://api.example.com/ready`

## Admin web

```bash
cd pranidoctor-web
cp .env.production.example .env
npm run build
# Docker:
docker build -t pranidoctor-web:latest .
docker run -p 3001:3001 --env-file .env pranidoctor-web:latest
```

## Mobile

```powershell
cd pranidoctor_user
cp .env.production.example .env
.\scripts\build_release.ps1
```

Requires `android/key.properties` and upload keystore for Play Store.

## nginx (example)

See `pranidoctor-backend/deploy/nginx/pranidoctor.conf.example`.

## Order of deployment

1. Postgres + Redis + MinIO  
2. `prisma migrate deploy`  
3. Backend API  
4. Admin web  
5. Mobile release to internal track → production
