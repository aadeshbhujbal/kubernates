@echo off
mkdir src\api
mkdir kubernetes
mkdir dags
mkdir logs
mkdir spark\jobs

echo Creating necessary files...
copy NUL src\api\package.json
copy NUL src\api\server.js
copy NUL Dockerfile.api
copy NUL .dockerignore

echo Done! Now you can run init-local.sh 