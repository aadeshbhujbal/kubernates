#!/bin/bash
echo "🔄 Restarting all services..."
./stop-all.sh
sleep 5
./start-all.sh
