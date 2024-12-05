#!/bin/bash

echo "🚀 Initializing Docker Environment..."

# Create required directories
mkdir -p ./dags ./logs ./plugins ./data/elasticsearch ./data/kafka ./data/redis
chmod -R 777 ./dags ./logs ./plugins ./data

# Stop any running containers and clean up
echo "🧹 Cleaning up existing containers..."
docker-compose down -v
docker volume prune -f

# Start core services first
echo "📦 Starting core services..."
docker-compose up -d postgres redis elasticsearch

# Wait for core services
echo "⏳ Waiting for core services to be ready..."
until docker-compose exec -T postgres pg_isready -U airflow; do
  echo "Waiting for postgres..."
  sleep 2
done

until docker-compose exec -T redis redis-cli ping; do
  echo "Waiting for redis..."
  sleep 2
done

until curl -s http://localhost:9200/_cluster/health; do
  echo "Waiting for elasticsearch..."
  sleep 2
done

# Initialize Airflow
echo "🛠 Initializing Airflow..."
docker-compose run --rm airflow-webserver airflow db init
docker-compose run --rm airflow-webserver airflow users create \
    --username admin \
    --firstname admin \
    --lastname admin \
    --role Admin \
    --email admin@admin.com \
    --password admin

# Start remaining services
echo "🚀 Starting all services..."
docker-compose up -d

echo "⏳ Waiting for services to stabilize..."
sleep 30

# Health checks
echo "🏥 Performing health checks..."
services=("airflow:8091/health" "kibana:5601/api/status" "kafka:9092" "spark-master:8090" "prometheus:9090/-/healthy")

for service in "${services[@]}"; do
    IFS=':' read -r -a array <<< "$service"
    until curl -s "http://localhost:${array[1]}" > /dev/null; do
        echo "Waiting for ${array[0]}..."
        sleep 2
    done
    echo "✅ ${array[0]} is ready"
done

# Modify the Kafka health check section (around line 25-33)
echo "Checking Kafka connectivity..."
MAX_RETRIES=30
RETRY_COUNT=0

while ! docker-compose exec -T kafka bash -c 'kafka-topics.sh --list --bootstrap-server localhost:9092 2>/dev/null'; do
    RETRY_COUNT=$((RETRY_COUNT+1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        echo "❌ Kafka failed to start after $MAX_RETRIES attempts. Checking logs..."
        docker-compose logs kafka
        echo "Check if Zookeeper is running:"
        docker-compose ps zookeeper
        exit 1
    fi
    echo "Waiting for Kafka (attempt $RETRY_COUNT/$MAX_RETRIES)..."
    sleep 10
done

echo "✅ Kafka is ready"

echo "
🎉 Services are ready! Access them at:
📊 Airflow UI: http://localhost:8091 (user: admin, pass: admin)
📈 Kibana UI: http://localhost:5601
🔄 API: http://localhost:3000
📡 Kafka UI: http://localhost:8081
⚡ Spark UI: http://localhost:8090
🗄️ pgAdmin: http://localhost:5050 (user: admin@admin.com, pass: admin)
📝 Adminer: http://localhost:8082
📦 Redis: localhost:6379
📊 Prometheus: http://localhost:9090
📈 Grafana: http://localhost:3001 (user: admin, pass: admin)
" 