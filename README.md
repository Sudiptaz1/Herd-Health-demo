# AI Herd Health Prediction — Demo

Predicts illness in cattle **before visible symptoms appear**, using simulated
smart ear-tag telemetry (body temperature, activity, rumination, heart rate,
GPS, weather). Built as a working, end-to-end prototype: data → model →
explainable predictions → live dashboard.

> "COW-318 has a 90% chance of becoming clinically sick within 48 hours —
> driven primarily by a rising body temperature relative to her own baseline
> and an elevated heart rate."

## Why this approach

- **Personal baselines, not population averages.** A healthy cow's normal
  temperature varies animal-to-animal. The model looks at deviation from
  each cow's own 7-day rolling baseline, not a fixed herd-wide threshold —
  this is how real precision-livestock research (rumination + activity drop
  as leading indicators) frames early illness detection.
- **Gradient boosted trees (XGBoost), not a black-box deep net**, for v1.
  At this data volume, well-engineered tabular features beat raw deep
  learning, training is fast enough to retrain per-herd, and it pairs with
  SHAP for exact, per-prediction explanations — which matters for rancher
  trust. An LSTM/1D-CNN over raw sequences is a natural v2 once there's
  enough real historical data per animal.
- **Time-based train/test split**, not random — this is a forecasting
  problem, so validating on a later time window (not random held-out rows)
  avoids leaking future information into training, same discipline as a
  real deployment where you only ever have the past to train on.

## Results (on synthetic validation data)

- ROC-AUC: **0.99**
- Recall on "sick within 48h" class: **88%**
- Precision on "sick within 48h" class: **72%**

See `models/shap_summary.png` for global feature importance and
`models/confusion_matrix.png` for the confusion matrix.

*(Synthetic data has a cleaner signal than real barns will — messier real
sensor data and edge cases would bring these numbers down. Presented as a
proof of concept, not a production benchmark.)*

## Project structure

```
herd_health_demo/
├── data/
│   └── generate_data.py       # synthetic multi-cow sensor generator
├── models/
│   ├── features.py            # rolling-window + baseline-deviation features
│   ├── train_model.py         # XGBoost training + evaluation
│   ├── risk_model.joblib      # trained model (generated)
│   ├── metrics.json           # evaluation metrics (generated)
│   ├── shap_summary.png       # global feature importance (generated)
│   └── confusion_matrix.png   # (generated)
├── app/
│   └── main.py                # FastAPI serving layer + SHAP explanations
├── static/
│   └── index.html             # live dashboard (vanilla JS + Chart.js)
├── requirements.txt
└── run_demo.sh                # one-command launcher
```

## Running it

**Mac / Linux:**
```bash
chmod +x run_demo.sh
./run_demo.sh
```

**Windows:**
Double-click `run_demo.bat`, or run it from Command Prompt / PowerShell:
```
run_demo.bat
```

**Manual steps (any OS, if you'd rather run them one at a time):**
```bash
pip install -r requirements.txt
python data/generate_data.py
python models/train_model.py
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```
(Note: in PowerShell, run each line separately — PowerShell's `&&` operator
only works on PowerShell 7+, not the default Windows PowerShell 5.1.)

Then open **http://localhost:8000** — a live dashboard listing every animal
in the simulated 60-head herd sorted by risk, with:
- Herd-wide risk summary (high/medium/low counts)
- Per-animal 48h illness risk %
- The top contributing factors behind each prediction (from SHAP)
- 72-hour sensor history charts (temperature, activity, rumination, heart rate)

### API only

```
GET /api/herd            → risk score for every animal
GET /api/cow/{cow_id}    → detailed prediction + explanation + history
GET /api/health          → service health check
```

## What's simulated vs. real

Everything here — sensor readings, illness events, prodromal (pre-clinical)
symptom drift — is **synthetically generated** (see `generate_data.py`) to
demonstrate the full pipeline without needing access to a real herd's
tag data. The feature engineering, modeling approach, and serving
architecture are all built the way they'd be built against real telemetry;
swapping in a real data feed only requires matching the input schema in
`generate_data.py`'s output columns.

## Natural next steps (roadmap talking points)

1. Swap XGBoost for an LSTM/temporal model once enough real historical
   per-animal data exists to justify the extra complexity.
2. Add a feedback loop: rancher confirms/rejects a flagged risk, retrain
   periodically on confirmed outcomes.
3. Calibrate risk thresholds per farm (some ranchers want high recall,
   others want fewer false alarms).
4. Feed this risk score into the "Predictive Ranch Dashboard" and
   "AI Report Generator" concepts as one of several health signals.
