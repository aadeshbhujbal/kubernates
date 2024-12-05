#!/bin/bash

echo "🔄 Restarting Kafka cluster..."

# Stop containers
echo "Stopping Kafka and Zookeeper..."
docker-compose stop kafka zookeeper

# Remove containers
echo "Removing old containers..."
docker-compose rm -f kafka zookeeper

# Clear Kafka data (optional, uncomment if needed)
# echo "Clearing Kafka data..."
# rm -rf ./kafka/data/*

# Start Zookeeper
echo "Starting Zookeeper..."
docker-compose up -d zookeeper

# Wait for Zookeeper
echo "Waiting for Zookeeper to start..."
sleep 15

# Start Kafka
echo "Starting Kafka..."
docker-compose up -d kafka

# Wait for Kafka
echo "Waiting for Kafka to start..."
sleep 20

# Check Kafka status
echo "Checking Kafka status..."
docker-compose exec -T kafka kafka-topics.sh --list --bootstrap-server localhost:9092

echo "✅ Kafka restart completed" 