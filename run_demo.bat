@echo off
REM One-command demo launcher for Windows.
cd /d "%~dp0"

echo Installing dependencies...
pip install -r requirements.txt

if not exist "data\herd_sensor_data.csv" (
    echo Generating synthetic herd sensor data...
    python data\generate_data.py
)

if not exist "models\risk_model.joblib" (
    echo Training risk model...
    cd models
    python train_model.py
    cd ..
)

echo.
echo Starting dashboard at http://localhost:8000
echo Press Ctrl+C to stop.
cd app
python -m uvicorn main:app --host 0.0.0.0 --port 8000
