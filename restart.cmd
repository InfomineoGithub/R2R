@echo off
REM Change to the script's directory (project root)
cd /d "%~dp0"

REM Stop all services (or only the ones in your profile if you prefer)
docker compose -f docker/compose.yaml --profile postgres down

REM Rebuild r2r from local Dockerfile and start it along with postgres
docker compose -f docker/compose.yaml --profile postgres up -d --build

REM Optional: start all other services that are not in the postgres profile
docker compose -f docker/compose.yaml up -d --build

echo All services restarted and rebuilt.