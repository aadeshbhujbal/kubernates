#!/bin/bash

echo "Checking service health..."

# Check Elasticsearch
echo "Checking Elasticsearch..."
curl -s http://localhost:9200/_cluster/health | grep -q '"status":"green\|yellow"' && echo "✓ Elasticsearch is healthy" || echo "✗ Elasticsearch is not healthy"

# Check Kafka
echo "Checking Kafka..."
docker-compose exec -T kafka kafka-topics.sh --list --bootstrap-server localhost:9092 && echo "✓ Kafka is healthy" || echo "✗ Kafka is not healthy"

# Check Airflow
echo "Checking Airflow..."
curl -s http://localhost:8091/health | grep -q "healthy" && echo "✓ Airflow is healthy" || echo "✗ Airflow is not healthy"

# Check Spark
echo "Checking Spark..."
curl -s http://localhost:8090 | grep -q "Spark Master" && echo "✓ Spark is healthy" || echo "✗ Spark is not healthy"

# Check PostgreSQL
echo "Checking PostgreSQL..."
docker-compose exec -T postgres pg_isready && echo "✓ PostgreSQL is healthy" || echo "✗ PostgreSQL is not healthy"

# Check Redis
echo "Checking Redis..."
docker-compose exec -T redis redis-cli ping | grep -q "PONG" && echo "✓ Redis is healthy" || echo "✗ Redis is not healthy"

# Check Prometheus
echo "Checking Prometheus..."
curl -s http://localhost:9090/-/healthy | grep -q "Prometheus Server is Healthy" && echo "✓ Prometheus is healthy" || echo "✗ Prometheus is not healthy"

# Check Grafana
echo "Checking Grafana..."
curl -s http://localhost:3001/api/health | grep -q "ok" && echo "✓ Grafana is healthy" || echo "✗ Grafana is not healthy"

echo "Checking data flow connections..."

# Test Kafka Producer/Consumer
echo "Testing Kafka connectivity..."
TOPIC_NAME="test-topic"
docker-compose exec -T kafka kafka-topics.sh --create --if-not-exists --topic $TOPIC_NAME --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

# Test message production
echo "test message" | docker-compose exec -T kafka kafka-console-producer.sh --topic $TOPIC_NAME --bootstrap-server localhost:9092

# Test message consumption
docker-compose exec -T kafka kafka-console-consumer.sh --topic $TOPIC_NAME --bootstrap-server localhost:9092 --from-beginning --max-messages 1 --timeout-ms 5000

# Test Elasticsearch indexing
echo "Testing Elasticsearch indexing..."
curl -X PUT "localhost:9200/test-index" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "number_of_shards": 1
  },
  "mappings": {
    "properties": {
      "field1": { "type": "text" }
    }
  }
}
'

# Test Spark
echo "Testing Spark..."
docker-compose exec -T spark-master spark-submit --version

echo "Data flow check complete!" 