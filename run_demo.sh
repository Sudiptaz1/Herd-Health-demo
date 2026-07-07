#!/bin/bash
# One-command demo launcher.
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "Installing dependencies..."
pip install -r requirements.txt --break-system-packages --quiet

if [ ! -f "data/herd_sensor_data.csv" ]; then
  echo "Generating synthetic herd sensor data..."
  python3 data/generate_data.py
fi

if [ ! -f "models/risk_model.joblib" ]; then
  echo "Training risk model..."
  (cd models && python3 train_model.py)
fi

echo ""
echo "Starting dashboard at http://localhost:8000"
echo "Press Ctrl+C to stop."
cd app && python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
