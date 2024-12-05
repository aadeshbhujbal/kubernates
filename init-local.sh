#!/bin/bash

# Create required directories
mkdir -p ./dags ./logs ./plugins
chmod -R 777 ./dags ./logs ./plugins

# Stop any running containers and clean up
docker-compose down -v
docker volume prune -f

# Start Postgres first
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
until docker-compose exec -T postgres pg_isready -U airflow; do
  echo "Waiting for postgres..."
  sleep 2
done

# Initialize Airflow
./check-airflow-db.sh

# Start remaining services
docker-compose up -d

echo "Waiting for services to start..."
sleep 30

# Run data flow checks
./check-data-flow.sh

echo "Services are ready! Access them at:"
echo "Airflow UI: http://localhost:8091 (user: admin, pass: admin)"
echo "Kibana UI: http://localhost:5601"
echo "API: http://localhost:3000"
echo "Kafka UI: http://localhost:8081"
echo "Spark UI: http://localhost:8090"
echo "pgAdmin: http://localhost:5050"
echo "Adminer: http://localhost:8082"
echo "Redis: localhost:6379"
echo "Prometheus: http://localhost:9090"
echo "Grafana: http://localhost:3001 (user: admin, pass: admin)"