#!/bin/bash

echo "🚀 Initializing Kubernetes Environment..."

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

# Create namespace if it doesn't exist
echo "📦 Creating namespace..."
kubectl create namespace mlops-platform --dry-run=client -o yaml | kubectl apply -f -

# Apply resource quotas and limits
echo "⚖️ Applying resource quotas..."
kubectl apply -f kubernetes/base/quotas/resource-quotas.yaml

# Apply storage classes and PVCs
echo "💾 Setting up storage..."
kubectl apply -f kubernetes/base/storage/

# Apply core services
echo "🛠 Deploying core services..."
services=(
    "kubernetes/base/kafka/zookeeper-deployment.yaml"
    "kubernetes/base/kafka/kafka-statefulset.yaml"
    "kubernetes/base/model-serving/redis-deployment.yaml"
    "kubernetes/base/airflow/postgres.yaml"
)

for service in "${services[@]}"; do
    kubectl apply -f $service
    echo "✅ Applied $service"
done

# Wait for core services
echo "⏳ Waiting for core services..."
kubectl wait --for=condition=ready pod -l app=kafka --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis --timeout=300s
kubectl wait --for=condition=ready pod -l app=postgres --timeout=300s

# Apply monitoring setup
echo "📊 Setting up monitoring..."
kubectl apply -f kubernetes/base/monitoring/prometheus.yaml
kubectl apply -f kubernetes/base/monitoring/grafana.yaml
kubectl apply -f kubernetes/base/monitoring/telemetry.yaml

# Apply remaining services
echo "🚀 Deploying remaining services..."
kubectl apply -k kubernetes/

# Apply network policies
echo "🔒 Applying network policies..."
kubectl apply -f kubernetes/base/network/network-policies.yaml

# Apply service mesh
echo "🕸 Setting up service mesh..."
kubectl apply -f kubernetes/base/monitoring/service-mesh-config.yaml

# Wait for all pods to be ready
echo "⏳ Waiting for all pods to be ready..."
kubectl wait --for=condition=ready pod --all --timeout=300s

# Get service URLs
echo "🎉 Getting service URLs..."
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "
🎉 Services are ready! Access them at:
📊 Airflow UI: http://$INGRESS_IP/airflow (user: admin, pass: admin)
📈 Kibana UI: http://$INGRESS_IP/kibana
🔄 API: http://$INGRESS_IP/api
📡 Kafka UI: http://$INGRESS_IP/kafka
⚡ Spark UI: http://$INGRESS_IP/spark
🗄️ pgAdmin: http://$INGRESS_IP/pgadmin (user: admin@admin.com, pass: admin)
📝 Adminer: http://$INGRESS_IP/adminer
📊 Prometheus: http://$INGRESS_IP/prometheus
📈 Grafana: http://$INGRESS_IP/grafana (user: admin, pass: admin)

To check the status of all pods:
kubectl get pods -A

To view logs:
kubectl logs -f <pod-name>

To check scaling status:
kubectl get hpa
"

# Setup monitoring dashboards
echo "📊 Setting up Grafana dashboards..."
kubectl apply -f kubernetes/base/monitoring/grafana-dashboards.yaml

# Run initial health checks
echo "🏥 Running health checks..."
./check-kubernetes-health.sh 