# Service Management Scripts

This repository contains scripts to manage the startup, shutdown, and restart of various services using Docker Compose. These services include databases, message brokers, processing services, monitoring tools, and UI components.

## Prerequisites

- Docker
- Docker Compose
- Bash

## Services Overview

The following services are managed by these scripts:

- **Core Infrastructure**
  - Zookeeper
  - Kafka

- **Databases**
  - PostgreSQL
  - Elasticsearch
  - Redis

- **Processing Services**
  - Spark Master
  - Spark Worker

- **Monitoring Stack**
  - Prometheus
  - Grafana

- **Application Services**
  - Airflow Webserver
  - Airflow Scheduler

- **UI Components**
  - Kibana
  - pgAdmin
  - Adminer

## Usage

### Starting Services

To start all services, execute the following command:

```bash
./start-all.sh
```
### Stopping Services

To stop all services, execute:
 

```bash
./stop-all.sh
```     

### Restarting Services

To restart all services, run:

```bash
./restart-all.sh
```

This will halt all running services.

## Health Checks

The `start-all.sh` script includes health checks for the following services:

- PostgreSQL
- Elasticsearch
- Redis
- Kafka
- Spark Master
- Prometheus
- Grafana
- Airflow
- Kibana
- pgAdmin

## Access Points

Once all services are running, they can be accessed at the following URLs:

- **Kafka**: `localhost:9092`
- **Zookeeper**: `localhost:2181`
- **PostgreSQL**: `localhost:5432`
- **Redis**: `localhost:6379`
- **Redis Commander**: `https://localhost:8083`
- **Elasticsearch**: `http://localhost:9200`
- **Airflow**: `http://localhost:8091` (admin/admin)
- **Kibana**: `http://localhost:5601`
- **Spark UI**: `http://localhost:8090`
- **pgAdmin**: `http://localhost:5050` (admin@admin.com/admin)
- **Adminer**: `http://localhost:8082`
- **Prometheus**: `http://localhost:9090`
- **Grafana**: `http://localhost:3001` (admin/admin)

## Viewing Logs

To view logs for a specific service, use:

```bash
docker-compose logs -f [service_name]
```

Replace `[service_name]` with the name of the service you wish to inspect.


