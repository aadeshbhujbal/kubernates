#!/bin/bash

echo "🏥 Running Kubernetes Health Checks..."

# Check pod status
echo "📦 Checking pod status..."
kubectl get pods -A | grep -v "Running\|Completed" && echo "❌ Some pods are not running" || echo "✅ All pods are running"

# Check HPA status
echo "⚖️ Checking HPA status..."
kubectl get hpa -A

# Check service mesh status
echo "🕸 Checking service mesh status..."
kubectl get pods -n istio-system

# Check monitoring
echo "📊 Checking monitoring stack..."
kubectl get pods -n monitoring

# Check persistent volumes
echo "💾 Checking persistent volumes..."
kubectl get pv,pvc -A

# Check logs for errors
echo "📝 Checking for errors in logs..."
kubectl get pods -A -o name | while read pod; do
    kubectl logs "$pod" --tail=50 | grep -i "error" || true
done

echo "✅ Health check completed" 