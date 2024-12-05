#!/bin/bash

echo " Starting all services..."

# Function to check if a service is healthy
check_health() {
    local service=$1
    local port=$2
    local endpoint=${3:-/}
    local max_attempts=${4:-30}
    local attempt=1

    echo "Checking $service health..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:$port$endpoint" > /dev/null; then
            echo "✅ $service is healthy"
            return 0
        fi
        echo "⏳ Waiting for $service (attempt $attempt/$max_attempts)..."
        attempt=$((attempt+1))
        sleep 5
    done
    echo "❌ $service failed to start"
    return 1
}

# 1. Start core infrastructure
echo "📦 Starting core infrastructure..."

# Start Zookeeper and Kafka
./restart-kafka.sh

# 2. Start databases
echo "💾 Starting databases..."
docker-compose up -d postgres elasticsearch redis
sleep 10

# Check database health
check_health "PostgreSQL" "5432"
if ! pg_isready -h localhost -p 5432; then
    echo "❌ PostgreSQL is not ready"
    exit 1
fi

check_health "Elasticsearch" "9200" "/_cluster/health"
docker-compose exec -T redis redis-cli ping || { echo "❌ Redis is not responding"; exit 1; }

# Check Kafka health
./check-kafka-health.sh || { echo "❌ Kafka is not healthy"; exit 1; }

# 3. Start message brokers and processing
echo "🔄 Starting processing services..."
docker-compose up -d spark-master spark-worker
check_health "Spark Master" "8090"

# 4. Start monitoring stack
echo "📊 Starting monitoring..."
docker-compose up -d prometheus grafana
check_health "Prometheus" "9090" "/-/healthy"
check_health "Grafana" "3001"

# 5. Start application services
echo "🌐 Starting application services..."
docker-compose up -d airflow-webserver airflow-scheduler
check_health "Airflow" "8091" "/health"

# 6. Start UI components
echo "🖥️ Starting UI components..."
docker-compose up -d kibana pgadmin adminer
check_health "Kibana" "5601" "/api/status"
check_health "pgAdmin" "5050"

# 7. Start remaining services
echo "🚀 Starting remaining services..."
docker-compose up -d

# Final health check
echo "🏥 Running final health checks..."
./check-kafka-health.sh

# Display service status
echo "📋 Service Status:"
docker-compose ps

echo "
🎉 All services started! Access points:

Core Services:
-------------
🔄 Kafka: localhost:9092
📦 Zookeeper: localhost:2181
💾 PostgreSQL: localhost:5432
📦 Redis: localhost:6379
📦 Redis Commander URL : https://localhost:8083
🔍 Elasticsearch: http://localhost:9200

Web Interfaces:
--------------
📊 Airflow: http://localhost:8091 (admin/admin)
📈 Kibana: http://localhost:5601
⚡ Spark UI: http://localhost:8090
🗄️ pgAdmin: http://localhost:5050 (admin@admin.com/admin)
📝 Adminer: http://localhost:8082
📊 Prometheus: http://localhost:9090
📈 Grafana: http://localhost:3001 (admin/admin)

To check logs:
-------------
docker-compose logs -f [service_name]

To stop all services:
-------------------
./stop-all.sh
"

# Create stop script
cat > stop-all.sh << 'EOF'
#!/bin/bash
echo "🛑 Stopping all services..."
docker-compose down
echo "✅ All services stopped"
EOF

chmod +x stop-all.sh

# Create restart script
cat > restart-all.sh << 'EOF'
#!/bin/bash
echo "🔄 Restarting all services..."
./stop-all.sh
sleep 5
./start-all.sh
EOF

chmod +x restart-all.sh 