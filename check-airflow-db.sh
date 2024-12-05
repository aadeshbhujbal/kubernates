#!/bin/bash

# Wait for PostgreSQL
until docker-compose exec -T postgres pg_isready -U airflow; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done

# Check Airflow DB
docker-compose exec -T airflow-webserver airflow db check

# If DB check fails, initialize it
if [ $? -ne 0 ]; then
  echo "Initializing Airflow database..."
  docker-compose exec -T airflow-webserver airflow db init
fi

# Check if admin user exists
if ! docker-compose exec -T airflow-webserver airflow users list | grep -q "admin"; then
  echo "Creating admin user..."
  docker-compose exec -T airflow-webserver airflow users create \
    --username admin \
    --firstname Admin \
    --lastname Admin \
    --role Admin \
    --email admin@example.com \
    --password admin
fi