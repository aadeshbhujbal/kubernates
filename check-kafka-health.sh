#!/bin/bash

echo "🔍 Checking Kafka Health..."

# Check if Zookeeper is running
echo "Checking Zookeeper status..."
if docker-compose ps zookeeper | grep -q "Up"; then
    echo "✅ Zookeeper is running"
else
    echo "❌ Zookeeper is not running"
    echo "Zookeeper logs:"
    docker-compose logs zookeeper
    exit 1
fi

# Check Kafka broker status
echo "Checking Kafka broker status..."
if docker-compose ps kafka | grep -q "Up"; then
    echo "✅ Kafka container is running"
else
    echo "❌ Kafka container is not running"
    echo "Kafka logs:"
    docker-compose logs kafka
    exit 1
fi

# Test Kafka connectivity
echo "Testing Kafka connectivity..."
if docker-compose exec -T kafka bash -c 'kafka-topics.sh --list --bootstrap-server localhost:9092 2>/dev/null'; then
    echo "✅ Kafka broker is responsive"
else
    echo "❌ Kafka broker is not responding"
    echo "Checking Kafka configurations..."
    docker-compose exec -T kafka bash -c 'cat /etc/kafka/server.properties'
    echo "Checking Kafka logs:"
    docker-compose logs kafka | tail -n 50
fi

# Check Kafka UI
echo "Checking Kafka UI..."
if curl -s http://localhost:8081/api/health 2>/dev/null | grep -q "UP"; then
    echo "✅ Kafka UI is accessible"
else
    echo "❌ Kafka UI is not accessible"
fi

# Memory usage check
echo "Checking Kafka memory usage..."
docker stats kafka --no-stream --format "Memory usage: {{.MemUsage}}"

echo "
Troubleshooting tips if Kafka fails:
1. Check if Zookeeper is running and accessible
2. Verify Kafka broker configurations
3. Check for port conflicts
4. Ensure enough memory is available
5. Check network connectivity between services

To restart Kafka properly:
docker-compose stop kafka zookeeper
docker-compose rm -f kafka zookeeper
docker-compose up -d zookeeper
sleep 10
docker-compose up -d kafka
" 