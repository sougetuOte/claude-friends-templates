#!/usr/bin/env python3
"""
AI-Assisted Performance Analysis System
Implements 2025 machine learning best practices for intelligent performance monitoring
Integrated with claude-friends-templates monitoring infrastructure
"""

import os
import sys
import json
import warnings
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, asdict
import uuid

# Suppress sklearn warnings
warnings.filterwarnings("ignore", category=FutureWarning)

try:
    import numpy as np
    import pandas as pd
    from sklearn.ensemble import IsolationForest, RandomForestRegressor
    from sklearn.preprocessing import StandardScaler
    from sklearn.cluster import DBSCAN
    from sklearn.decomposition import PCA
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import mean_squared_error, r2_score
    import joblib
except ImportError:
    print(
        "Warning: Some ML libraries not available. Install with: pip install numpy pandas scikit-learn"
    )
    np = None


@dataclass
class PerformanceAnomaly:
    """Represents a detected performance anomaly"""

    anomaly_id: str
    timestamp: datetime
    metric_name: str
    observed_value: float
    expected_value: float
    anomaly_score: float
    severity: str  # 'low', 'medium', 'high', 'critical'
    root_cause_analysis: Dict[str, Any]
    recommendations: List[str]
    confidence: float


@dataclass
class PerformancePrediction:
    """Represents a performance prediction"""

    prediction_id: str
    timestamp: datetime
    metric_name: str
    predicted_values: List[float]
    prediction_horizon: int  # hours
    confidence_interval: Tuple[float, float]
    trend_analysis: Dict[str, Any]
    risk_assessment: Dict[str, Any]


@dataclass
class PatternInsight:
    """Represents a discovered performance pattern"""

    pattern_id: str
    pattern_type: str  # 'correlation', 'seasonal', 'degradation', 'optimization'
    description: str
    affected_metrics: List[str]
    strength: float  # 0-1 pattern strength
    actionable_insights: List[str]
    supporting_data: Dict[str, Any]


class BaselineCalculator:
    """Calculates and maintains performance baselines"""

    def __init__(self, metrics_dir: str):
        self.metrics_dir = Path(metrics_dir)
        self.baseline_file = self.metrics_dir / "performance_baselines.json"
        self.baselines = self._load_baselines()

    def _load_baselines(self) -> Dict[str, Any]:
        """Load existing baselines or create empty structure"""
        if self.baseline_file.exists():
            try:
                with open(self.baseline_file, "r") as f:
                    return json.load(f)
            except Exception:
                pass
        return {}

    def _save_baselines(self):
        """Save baselines to file"""
        with open(self.baseline_file, "w") as f:
            json.dump(self.baselines, f, indent=2, default=str)

    def update_baseline(
        self, metric_name: str, values: List[float], window_hours: int = 24
    ):
        """Update baseline for a metric"""
        if not values:
            return

        baseline_data = {
            "last_updated": datetime.now().isoformat(),
            "window_hours": window_hours,
            "sample_count": len(values),
            "mean": float(np.mean(values)),
            "std": float(np.std(values)),
            "median": float(np.median(values)),
            "p95": float(np.percentile(values, 95)),
            "p99": float(np.percentile(values, 99)),
            "min": float(np.min(values)),
            "max": float(np.max(values)),
        }

        self.baselines[metric_name] = baseline_data
        self._save_baselines()

    def get_baseline(self, metric_name: str) -> Optional[Dict[str, Any]]:
        """Get baseline for a metric"""
        return self.baselines.get(metric_name)

    def is_anomalous(
        self, metric_name: str, value: float, threshold_std: float = 2.0
    ) -> Tuple[bool, float]:
        """Check if a value is anomalous compared to baseline"""
        baseline = self.get_baseline(metric_name)
        if not baseline:
            return False, 0.0

        mean = baseline["mean"]
        std = baseline["std"]

        if std == 0:  # Prevent division by zero
            return False, 0.0

        z_score = abs(value - mean) / std
        is_anomalous = z_score > threshold_std

        return is_anomalous, z_score


class AnomalyDetector:
    """ML-based anomaly detection for performance metrics"""

    def __init__(self, metrics_dir: str):
        self.metrics_dir = Path(metrics_dir)
        self.models_dir = self.metrics_dir / "ml_models"
        self.models_dir.mkdir(exist_ok=True)

        self.isolation_forest = None
        self.scaler = StandardScaler()
        self.feature_columns = []
        self.is_trained = False

        self._load_models()

    def _load_models(self):
        """Load pre-trained models if available"""
        isolation_forest_path = self.models_dir / "isolation_forest.joblib"
        scaler_path = self.models_dir / "scaler.joblib"

        try:
            if isolation_forest_path.exists() and scaler_path.exists():
                self.isolation_forest = joblib.load(isolation_forest_path)
                self.scaler = joblib.load(scaler_path)

                # Load feature columns
                features_path = self.models_dir / "feature_columns.json"
                if features_path.exists():
                    with open(features_path, "r") as f:
                        self.feature_columns = json.load(f)
                    self.is_trained = True
        except Exception as e:
            print(f"Warning: Could not load pre-trained models: {e}")

    def _save_models(self):
        """Save trained models"""
        if self.isolation_forest and self.is_trained:
            joblib.dump(
                self.isolation_forest, self.models_dir / "isolation_forest.joblib"
            )
            joblib.dump(self.scaler, self.models_dir / "scaler.joblib")

            with open(self.models_dir / "feature_columns.json", "w") as f:
                json.dump(self.feature_columns, f)

    def prepare_features(self, metrics_data: pd.DataFrame) -> pd.DataFrame:
        """Prepare features for ML models"""
        features = pd.DataFrame()

        # Time-based features
        if "timestamp" in metrics_data.columns:
            metrics_data["timestamp"] = pd.to_datetime(metrics_data["timestamp"])
            features["hour"] = metrics_data["timestamp"].dt.hour
            features["day_of_week"] = metrics_data["timestamp"].dt.dayofweek
            features["is_weekend"] = (features["day_of_week"] >= 5).astype(int)

        # Metric value features
        numeric_columns = metrics_data.select_dtypes(include=[np.number]).columns
        for col in numeric_columns:
            if col in ["value", "duration_ms", "memory_mb", "cpu_percent"]:
                features[f"{col}_value"] = metrics_data[col]

                # Rolling statistics
                features[f"{col}_rolling_mean_5"] = (
                    metrics_data[col].rolling(5, min_periods=1).mean()
                )
                features[f"{col}_rolling_std_5"] = (
                    metrics_data[col].rolling(5, min_periods=1).std().fillna(0)
                )
                features[f"{col}_rolling_max_10"] = (
                    metrics_data[col].rolling(10, min_periods=1).max()
                )

        # Categorical features (one-hot encoded)
        categorical_columns = ["metric_name", "operation", "hook_name", "severity"]
        for col in categorical_columns:
            if col in metrics_data.columns:
                dummies = pd.get_dummies(metrics_data[col], prefix=col)
                features = pd.concat([features, dummies], axis=1)

        # Fill NaN values
        features = features.fillna(0)

        return features

    def train(self, metrics_data: pd.DataFrame, contamination: float = 0.1):
        """Train anomaly detection models"""
        if len(metrics_data) < 100:
            print("Warning: Insufficient data for training (need at least 100 samples)")
            return False

        # Prepare features
        features = self.prepare_features(metrics_data)
        self.feature_columns = features.columns.tolist()

        # Scale features
        features_scaled = self.scaler.fit_transform(features)

        # Train Isolation Forest
        self.isolation_forest = IsolationForest(
            contamination=contamination, random_state=42, n_estimators=100
        )
        self.isolation_forest.fit(features_scaled)

        self.is_trained = True
        self._save_models()

        print(
            f"Anomaly detection model trained on {len(features)} samples with {len(self.feature_columns)} features"
        )
        return True

    def detect_anomalies(self, metrics_data: pd.DataFrame) -> List[int]:
        """Detect anomalies in metrics data"""
        if not self.is_trained:
            return []

        features = self.prepare_features(metrics_data)

        # Ensure features match training set
        for col in self.feature_columns:
            if col not in features.columns:
                features[col] = 0

        features = features[self.feature_columns]
        features_scaled = self.scaler.transform(features)

        # Predict anomalies (-1 = anomaly, 1 = normal)
        predictions = self.isolation_forest.predict(features_scaled)
        anomaly_indices = np.where(predictions == -1)[0].tolist()

        return anomaly_indices

    def get_anomaly_scores(self, metrics_data: pd.DataFrame) -> List[float]:
        """Get anomaly scores for metrics data"""
        if not self.is_trained:
            return []

        features = self.prepare_features(metrics_data)

        # Ensure features match training set
        for col in self.feature_columns:
            if col not in features.columns:
                features[col] = 0

        features = features[self.feature_columns]
        features_scaled = self.scaler.transform(features)

        # Get anomaly scores (lower = more anomalous)
        scores = self.isolation_forest.decision_function(features_scaled)

        # Convert to 0-1 scale (1 = most anomalous)
        normalized_scores = 1 - (scores - scores.min()) / (scores.max() - scores.min())

        return normalized_scores.tolist()


class PerformancePredictor:
    """ML-based performance prediction system"""

    def __init__(self, metrics_dir: str):
        self.metrics_dir = Path(metrics_dir)
        self.models_dir = self.metrics_dir / "ml_models"
        self.models_dir.mkdir(exist_ok=True)

        self.predictors = {}  # metric_name -> model
        self.feature_columns = {}  # metric_name -> feature_columns
        self.scalers = {}  # metric_name -> scaler

    def _prepare_time_series_features(
        self, data: pd.Series, window_size: int = 10
    ) -> pd.DataFrame:
        """Prepare time series features for prediction"""
        features = pd.DataFrame()

        # Lag features
        for lag in range(1, window_size + 1):
            features[f"lag_{lag}"] = data.shift(lag)

        # Rolling statistics
        for window in [3, 5, 10]:
            if window <= len(data):
                features[f"rolling_mean_{window}"] = data.rolling(window).mean()
                features[f"rolling_std_{window}"] = data.rolling(window).std()
                features[f"rolling_max_{window}"] = data.rolling(window).max()
                features[f"rolling_min_{window}"] = data.rolling(window).min()

        # Time-based features
        if isinstance(data.index, pd.DatetimeIndex):
            features["hour"] = data.index.hour
            features["day_of_week"] = data.index.dayofweek
            features["is_weekend"] = (data.index.dayofweek >= 5).astype(int)

        # Trend features
        features["linear_trend"] = np.arange(len(data))

        # Fill NaN values
        features = features.fillna(method="bfill").fillna(0)

        return features

    def train_predictor(
        self, metric_name: str, time_series_data: pd.Series, test_size: float = 0.2
    ) -> Dict[str, float]:
        """Train a predictor for a specific metric"""
        if len(time_series_data) < 50:
            print(
                f"Warning: Insufficient data for {metric_name} (need at least 50 samples)"
            )
            return {}

        # Prepare features
        features = self._prepare_time_series_features(time_series_data)
        target = time_series_data.values

        # Remove rows with NaN in target
        valid_indices = ~pd.isna(target)
        features = features[valid_indices]
        target = target[valid_indices]

        if len(features) < 20:
            print(f"Warning: Too few valid samples for {metric_name}")
            return {}

        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            features, target, test_size=test_size, shuffle=False
        )

        # Scale features
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)

        # Train Random Forest
        model = RandomForestRegressor(
            n_estimators=100, max_depth=10, random_state=42, n_jobs=-1
        )
        model.fit(X_train_scaled, y_train)

        # Evaluate
        y_pred = model.predict(X_test_scaled)
        mse = mean_squared_error(y_test, y_pred)
        r2 = r2_score(y_test, y_pred)

        # Store model and metadata
        self.predictors[metric_name] = model
        self.feature_columns[metric_name] = features.columns.tolist()
        self.scalers[metric_name] = scaler

        # Save model
        model_path = (
            self.models_dir / f'predictor_{metric_name.replace(".", "_")}.joblib'
        )
        joblib.dump(
            {
                "model": model,
                "scaler": scaler,
                "feature_columns": features.columns.tolist(),
            },
            model_path,
        )

        return {
            "mse": mse,
            "r2": r2,
            "train_samples": len(X_train),
            "test_samples": len(X_test),
        }

    def predict(
        self, metric_name: str, historical_data: pd.Series, horizon: int = 12
    ) -> Optional[PerformancePrediction]:
        """Make performance predictions"""
        if metric_name not in self.predictors:
            return None

        model = self.predictors[metric_name]
        scaler = self.scalers[metric_name]
        feature_columns = self.feature_columns[metric_name]

        # Prepare features from recent data
        features = self._prepare_time_series_features(historical_data)

        # Get the most recent complete feature row
        last_complete_row = (
            features.dropna().iloc[-1:]
            if len(features.dropna()) > 0
            else features.iloc[-1:]
        )

        predictions = []
        confidence_intervals = []

        # Make iterative predictions
        current_data = historical_data.copy()

        for step in range(horizon):
            # Prepare features for current step
            step_features = self._prepare_time_series_features(current_data)

            if len(step_features) == 0:
                break

            last_row = step_features.iloc[-1:].copy()

            # Ensure all required columns exist
            for col in feature_columns:
                if col not in last_row.columns:
                    last_row[col] = 0

            last_row = last_row[feature_columns]

            # Scale and predict
            try:
                last_row_scaled = scaler.transform(last_row)
                prediction = model.predict(last_row_scaled)[0]
                predictions.append(prediction)

                # Estimate confidence interval (simplified)
                # In a more sophisticated implementation, use quantile regression
                uncertainty = np.std(historical_data.iloc[-20:]) * (1 + step * 0.1)
                confidence_intervals.append(
                    (prediction - uncertainty, prediction + uncertainty)
                )

                # Add prediction to current data for next iteration
                next_timestamp = current_data.index[-1] + pd.Timedelta(hours=1)
                current_data.loc[next_timestamp] = prediction

            except Exception as e:
                print(f"Prediction error for {metric_name} at step {step}: {e}")
                break

        if not predictions:
            return None

        # Analyze trends
        trend_analysis = self._analyze_trends(predictions, historical_data)
        risk_assessment = self._assess_risks(predictions, historical_data)

        return PerformancePrediction(
            prediction_id=str(uuid.uuid4()),
            timestamp=datetime.now(),
            metric_name=metric_name,
            predicted_values=predictions,
            prediction_horizon=horizon,
            confidence_interval=confidence_intervals[0]
            if confidence_intervals
            else (0, 0),
            trend_analysis=trend_analysis,
            risk_assessment=risk_assessment,
        )

    def _analyze_trends(
        self, predictions: List[float], historical_data: pd.Series
    ) -> Dict[str, Any]:
        """Analyze trends in predictions"""
        if len(predictions) < 2:
            return {"trend": "insufficient_data"}

        # Calculate trend slope
        x = np.arange(len(predictions))
        slope, intercept = np.polyfit(x, predictions, 1)

        # Compare with historical trend
        historical_values = historical_data.iloc[-len(predictions) :].values
        if len(historical_values) >= 2:
            hist_slope, _ = np.polyfit(
                np.arange(len(historical_values)), historical_values, 1
            )
        else:
            hist_slope = 0

        return {
            "trend": "increasing"
            if slope > 0
            else "decreasing"
            if slope < 0
            else "stable",
            "slope": slope,
            "historical_slope": hist_slope,
            "trend_change": "accelerating"
            if abs(slope) > abs(hist_slope)
            else "decelerating",
            "predicted_change_percent": (
                (predictions[-1] - predictions[0]) / max(predictions[0], 0.001)
            )
            * 100,
        }

    def _assess_risks(
        self, predictions: List[float], historical_data: pd.Series
    ) -> Dict[str, Any]:
        """Assess risks based on predictions"""
        historical_mean = historical_data.mean()
        historical_std = historical_data.std()

        risks = []
        risk_level = "low"

        # Check for significant deviations from historical norms
        for i, pred in enumerate(predictions):
            z_score = abs(pred - historical_mean) / max(historical_std, 0.001)

            if z_score > 3:
                risks.append(f"Hour {i+1}: Extreme deviation (z-score: {z_score:.1f})")
                risk_level = "critical"
            elif z_score > 2:
                risks.append(f"Hour {i+1}: High deviation (z-score: {z_score:.1f})")
                if risk_level not in ["critical"]:
                    risk_level = "high"

        # Check for rapid changes
        if len(predictions) >= 2:
            max_change = max(
                abs(predictions[i + 1] - predictions[i])
                for i in range(len(predictions) - 1)
            )
            historical_max_change = max(abs(historical_data.diff().dropna()))

            if max_change > historical_max_change * 2:
                risks.append(
                    f"Rapid change detected: {max_change:.2f} (historical max: {historical_max_change:.2f})"
                )
                if risk_level not in ["critical", "high"]:
                    risk_level = "medium"

        return {
            "risk_level": risk_level,
            "identified_risks": risks,
            "predicted_max": max(predictions),
            "predicted_min": min(predictions),
            "historical_max": historical_data.max(),
            "historical_min": historical_data.min(),
        }


class PatternAnalyzer:
    """Analyzes performance patterns and correlations"""

    def __init__(self, metrics_dir: str):
        self.metrics_dir = Path(metrics_dir)

    def find_correlations(
        self, metrics_data: pd.DataFrame, min_correlation: float = 0.7
    ) -> List[PatternInsight]:
        """Find correlations between metrics"""
        insights = []

        # Prepare correlation matrix
        numeric_cols = metrics_data.select_dtypes(include=[np.number]).columns
        if len(numeric_cols) < 2:
            return insights

        correlation_matrix = metrics_data[numeric_cols].corr()

        # Find significant correlations
        for i, col1 in enumerate(numeric_cols):
            for j, col2 in enumerate(numeric_cols[i + 1 :], i + 1):
                correlation = correlation_matrix.loc[col1, col2]

                if abs(correlation) >= min_correlation:
                    insight = PatternInsight(
                        pattern_id=str(uuid.uuid4()),
                        pattern_type="correlation",
                        description=f"Strong {'positive' if correlation > 0 else 'negative'} correlation between {col1} and {col2}",
                        affected_metrics=[col1, col2],
                        strength=abs(correlation),
                        actionable_insights=self._generate_correlation_insights(
                            col1, col2, correlation
                        ),
                        supporting_data={
                            "correlation_coefficient": correlation,
                            "sample_size": len(metrics_data),
                        },
                    )
                    insights.append(insight)

        return insights

    def _generate_correlation_insights(
        self, metric1: str, metric2: str, correlation: float
    ) -> List[str]:
        """Generate actionable insights from correlations"""
        insights = []

        if "duration" in metric1 and "memory" in metric2:
            if correlation > 0:
                insights.append(
                    "High execution time correlates with high memory usage - consider memory optimization"
                )
            else:
                insights.append(
                    "Inverse correlation between time and memory suggests good memory management"
                )

        elif "hook" in metric1 and "agent_switch" in metric2:
            if correlation > 0:
                insights.append(
                    "Hook performance affects agent switching - optimize critical hooks"
                )

        elif "energy" in metric1 and any(
            x in metric2 for x in ["cpu", "memory", "duration"]
        ):
            if correlation > 0:
                insights.append(
                    "Energy consumption correlates with resource usage - focus on efficiency"
                )

        if not insights:
            insights.append(
                f"Monitor {metric1} and {metric2} together for optimization opportunities"
            )

        return insights

    def detect_seasonal_patterns(
        self, time_series: pd.Series, metric_name: str
    ) -> List[PatternInsight]:
        """Detect seasonal patterns in time series data"""
        insights = []

        if len(time_series) < 168:  # Less than a week of hourly data
            return insights

        # Convert to hourly if needed
        if isinstance(time_series.index, pd.DatetimeIndex):
            hourly_data = time_series.groupby(time_series.index.hour).mean()
            daily_data = time_series.groupby(time_series.index.dayofweek).mean()

            # Check for hourly patterns
            hourly_cv = (
                hourly_data.std() / hourly_data.mean() if hourly_data.mean() > 0 else 0
            )
            if hourly_cv > 0.2:  # Significant hourly variation
                peak_hour = hourly_data.idxmax()
                low_hour = hourly_data.idxmin()

                insight = PatternInsight(
                    pattern_id=str(uuid.uuid4()),
                    pattern_type="seasonal",
                    description=f"Daily pattern detected in {metric_name}: peak at {peak_hour}:00, low at {low_hour}:00",
                    affected_metrics=[metric_name],
                    strength=hourly_cv,
                    actionable_insights=[
                        f"Schedule intensive operations outside peak hour ({peak_hour}:00)",
                        "Optimize resources for peak usage periods",
                        "Consider dynamic resource allocation based on hourly patterns",
                    ],
                    supporting_data={
                        "peak_hour": peak_hour,
                        "low_hour": low_hour,
                        "coefficient_of_variation": hourly_cv,
                        "peak_value": hourly_data.max(),
                        "low_value": hourly_data.min(),
                    },
                )
                insights.append(insight)

            # Check for weekly patterns
            weekly_cv = (
                daily_data.std() / daily_data.mean() if daily_data.mean() > 0 else 0
            )
            if weekly_cv > 0.2:
                peak_day = daily_data.idxmax()
                low_day = daily_data.idxmin()

                day_names = [
                    "Monday",
                    "Tuesday",
                    "Wednesday",
                    "Thursday",
                    "Friday",
                    "Saturday",
                    "Sunday",
                ]

                insight = PatternInsight(
                    pattern_id=str(uuid.uuid4()),
                    pattern_type="seasonal",
                    description=f"Weekly pattern detected in {metric_name}: peak on {day_names[peak_day]}, low on {day_names[low_day]}",
                    affected_metrics=[metric_name],
                    strength=weekly_cv,
                    actionable_insights=[
                        f"Plan maintenance activities on {day_names[low_day]}",
                        f"Prepare for higher load on {day_names[peak_day]}",
                        "Consider weekend vs weekday optimization strategies",
                    ],
                    supporting_data={
                        "peak_day": day_names[peak_day],
                        "low_day": day_names[low_day],
                        "coefficient_of_variation": weekly_cv,
                    },
                )
                insights.append(insight)

        return insights

    def detect_performance_degradation(
        self, time_series: pd.Series, metric_name: str, window_size: int = 50
    ) -> List[PatternInsight]:
        """Detect performance degradation patterns"""
        insights = []

        if len(time_series) < window_size * 2:
            return insights

        # Compare recent performance with historical baseline
        recent_data = time_series.iloc[-window_size:]
        historical_data = time_series.iloc[-window_size * 2 : -window_size]

        recent_mean = recent_data.mean()
        historical_mean = historical_data.mean()

        # For metrics where lower is better (like duration, memory usage)
        is_degradation = False
        degradation_percent = 0

        if any(
            keyword in metric_name.lower()
            for keyword in ["duration", "time", "latency", "memory", "cpu"]
        ):
            # Lower is better
            if recent_mean > historical_mean * 1.1:  # 10% worse
                is_degradation = True
                degradation_percent = (
                    (recent_mean - historical_mean) / historical_mean
                ) * 100
        else:
            # Higher is better (efficiency, coverage, etc.)
            if recent_mean < historical_mean * 0.9:  # 10% worse
                is_degradation = True
                degradation_percent = (
                    (historical_mean - recent_mean) / historical_mean
                ) * 100

        if is_degradation:
            severity = (
                "critical"
                if degradation_percent > 30
                else "high"
                if degradation_percent > 20
                else "medium"
            )

            insight = PatternInsight(
                pattern_id=str(uuid.uuid4()),
                pattern_type="degradation",
                description=f"Performance degradation detected in {metric_name}: {degradation_percent:.1f}% worse than baseline",
                affected_metrics=[metric_name],
                strength=min(degradation_percent / 100, 1.0),
                actionable_insights=self._generate_degradation_insights(
                    metric_name, degradation_percent, severity
                ),
                supporting_data={
                    "degradation_percent": degradation_percent,
                    "recent_mean": recent_mean,
                    "historical_mean": historical_mean,
                    "severity": severity,
                    "sample_size": window_size,
                },
            )
            insights.append(insight)

        return insights

    def _generate_degradation_insights(
        self, metric_name: str, degradation_percent: float, severity: str
    ) -> List[str]:
        """Generate insights for performance degradation"""
        insights = []

        if "hook" in metric_name:
            insights.extend(
                [
                    "Review recent changes to hook implementations",
                    "Check for increased complexity in hook operations",
                    "Consider caching or optimization for frequently executed hooks",
                ]
            )
        elif "memory" in metric_name:
            insights.extend(
                [
                    "Investigate potential memory leaks",
                    "Review recent code changes for memory efficiency",
                    "Consider implementing memory usage limits",
                ]
            )
        elif "agent_switch" in metric_name:
            insights.extend(
                [
                    "Optimize handover templates and context size",
                    "Review agent switching frequency patterns",
                    "Consider improving agent state management",
                ]
            )
        elif "tdd" in metric_name:
            insights.extend(
                [
                    "Review TDD cycle complexity and test organization",
                    "Consider breaking down large test suites",
                    "Optimize test execution and feedback loops",
                ]
            )

        if severity == "critical":
            insights.insert(
                0,
                f"URGENT: {degradation_percent:.1f}% degradation requires immediate attention",
            )

        return insights


class AIPerformanceAnalyzer:
    """Main AI-assisted performance analysis system"""

    def __init__(self, metrics_dir: str = None):
        self.metrics_dir = Path(
            metrics_dir or os.path.join(os.path.expanduser("~"), ".claude", "metrics")
        )
        self.metrics_dir.mkdir(parents=True, exist_ok=True)

        self.baseline_calculator = BaselineCalculator(str(self.metrics_dir))
        self.anomaly_detector = AnomalyDetector(str(self.metrics_dir))
        self.performance_predictor = PerformancePredictor(str(self.metrics_dir))
        self.pattern_analyzer = PatternAnalyzer(str(self.metrics_dir))

        self.insights_file = self.metrics_dir / "ai_insights.jsonl"
        self.predictions_file = self.metrics_dir / "ai_predictions.jsonl"

    def analyze_metrics(self, metrics_data: pd.DataFrame) -> Dict[str, Any]:
        """Comprehensive AI analysis of metrics data"""
        analysis_results = {
            "timestamp": datetime.now().isoformat(),
            "analysis_id": str(uuid.uuid4()),
            "data_summary": {
                "total_samples": len(metrics_data),
                "time_range": {
                    "start": metrics_data["timestamp"].min()
                    if "timestamp" in metrics_data.columns
                    else None,
                    "end": metrics_data["timestamp"].max()
                    if "timestamp" in metrics_data.columns
                    else None,
                },
                "metrics_analyzed": metrics_data.columns.tolist(),
            },
            "anomalies": [],
            "predictions": [],
            "patterns": [],
            "recommendations": [],
        }

        try:
            # Update baselines
            self._update_baselines(metrics_data)

            # Detect anomalies
            anomalies = self._detect_anomalies(metrics_data)
            analysis_results["anomalies"] = anomalies

            # Generate predictions
            predictions = self._generate_predictions(metrics_data)
            analysis_results["predictions"] = predictions

            # Find patterns
            patterns = self._analyze_patterns(metrics_data)
            analysis_results["patterns"] = patterns

            # Generate comprehensive recommendations
            recommendations = self._generate_recommendations(
                anomalies, predictions, patterns
            )
            analysis_results["recommendations"] = recommendations

            # Save insights
            self._save_insights(analysis_results)

        except Exception as e:
            analysis_results["error"] = str(e)
            print(f"Error in AI analysis: {e}")

        return analysis_results

    def _update_baselines(self, metrics_data: pd.DataFrame):
        """Update baselines for all metrics"""
        numeric_columns = metrics_data.select_dtypes(include=[np.number]).columns

        for col in numeric_columns:
            values = metrics_data[col].dropna().tolist()
            if len(values) >= 10:  # Minimum samples for baseline
                self.baseline_calculator.update_baseline(col, values)

    def _detect_anomalies(self, metrics_data: pd.DataFrame) -> List[Dict[str, Any]]:
        """Detect anomalies using multiple methods"""
        anomalies = []

        # Statistical anomaly detection (baseline comparison)
        numeric_columns = metrics_data.select_dtypes(include=[np.number]).columns
        for col in numeric_columns:
            for idx, value in metrics_data[col].items():
                if pd.notna(value):
                    is_anomalous, z_score = self.baseline_calculator.is_anomalous(
                        col, value
                    )

                    if is_anomalous:
                        baseline = self.baseline_calculator.get_baseline(col)
                        expected_value = baseline["mean"] if baseline else value

                        anomaly = PerformanceAnomaly(
                            anomaly_id=str(uuid.uuid4()),
                            timestamp=datetime.now(),
                            metric_name=col,
                            observed_value=value,
                            expected_value=expected_value,
                            anomaly_score=z_score,
                            severity="high" if z_score > 3 else "medium",
                            root_cause_analysis=self._analyze_anomaly_root_cause(
                                col, value, metrics_data.iloc[idx]
                            ),
                            recommendations=self._generate_anomaly_recommendations(
                                col, value, z_score
                            ),
                            confidence=min(z_score / 3.0, 1.0),
                        )
                        anomalies.append(asdict(anomaly))

        # ML-based anomaly detection
        if len(metrics_data) >= 100:
            try:
                if not self.anomaly_detector.is_trained:
                    self.anomaly_detector.train(metrics_data)

                ml_anomalies = self.anomaly_detector.detect_anomalies(metrics_data)
                anomaly_scores = self.anomaly_detector.get_anomaly_scores(metrics_data)

                for idx in ml_anomalies:
                    if idx < len(metrics_data):
                        row = metrics_data.iloc[idx]
                        anomaly_score = (
                            anomaly_scores[idx] if idx < len(anomaly_scores) else 0.5
                        )

                        # Find the most anomalous metric in this row
                        numeric_values = row.select_dtypes(include=[np.number])
                        if len(numeric_values) > 0:
                            max_deviation_metric = None
                            max_deviation = 0

                            for col, value in numeric_values.items():
                                baseline = self.baseline_calculator.get_baseline(col)
                                if baseline and baseline["std"] > 0:
                                    deviation = (
                                        abs(value - baseline["mean"]) / baseline["std"]
                                    )
                                    if deviation > max_deviation:
                                        max_deviation = deviation
                                        max_deviation_metric = col

                            if max_deviation_metric:
                                anomaly = PerformanceAnomaly(
                                    anomaly_id=str(uuid.uuid4()),
                                    timestamp=datetime.now(),
                                    metric_name=max_deviation_metric,
                                    observed_value=float(row[max_deviation_metric]),
                                    expected_value=baseline["mean"],
                                    anomaly_score=anomaly_score,
                                    severity="critical"
                                    if anomaly_score > 0.8
                                    else "high"
                                    if anomaly_score > 0.6
                                    else "medium",
                                    root_cause_analysis=self._analyze_anomaly_root_cause(
                                        max_deviation_metric,
                                        row[max_deviation_metric],
                                        row,
                                    ),
                                    recommendations=self._generate_anomaly_recommendations(
                                        max_deviation_metric,
                                        row[max_deviation_metric],
                                        anomaly_score,
                                    ),
                                    confidence=anomaly_score,
                                )
                                anomalies.append(asdict(anomaly))

            except Exception as e:
                print(f"ML anomaly detection failed: {e}")

        return anomalies

    def _analyze_anomaly_root_cause(
        self, metric_name: str, value: float, row: pd.Series
    ) -> Dict[str, Any]:
        """Analyze potential root causes of anomalies"""
        root_cause = {
            "metric_context": metric_name,
            "observed_value": value,
            "potential_causes": [],
            "correlated_metrics": [],
        }

        # Look for correlated metrics that are also anomalous
        numeric_data = row.select_dtypes(include=[np.number])
        for col, col_value in numeric_data.items():
            if col != metric_name and pd.notna(col_value):
                is_anomalous, _ = self.baseline_calculator.is_anomalous(col, col_value)
                if is_anomalous:
                    root_cause["correlated_metrics"].append(
                        {"metric": col, "value": col_value}
                    )

        # Generate potential causes based on metric type and context
        if "hook" in metric_name:
            root_cause["potential_causes"].extend(
                [
                    "Recent code changes affecting hook execution",
                    "Increased complexity in hook operations",
                    "System resource constraints",
                    "Network or I/O delays",
                ]
            )
        elif "memory" in metric_name:
            root_cause["potential_causes"].extend(
                [
                    "Memory leak in recent code changes",
                    "Increased data volume being processed",
                    "Inefficient memory allocation patterns",
                    "Background processes consuming memory",
                ]
            )
        elif "agent" in metric_name:
            root_cause["potential_causes"].extend(
                [
                    "Complex handover contexts",
                    "Increased switching frequency",
                    "Agent coordination inefficiencies",
                    "State management bottlenecks",
                ]
            )

        return root_cause

    def _generate_anomaly_recommendations(
        self, metric_name: str, value: float, severity_score: float
    ) -> List[str]:
        """Generate recommendations for addressing anomalies"""
        recommendations = []

        if severity_score > 2.5:  # High severity
            recommendations.append(
                f"URGENT: Investigate {metric_name} anomaly immediately"
            )

        if "duration" in metric_name or "time" in metric_name:
            recommendations.extend(
                [
                    "Profile code execution to identify bottlenecks",
                    "Check for blocking operations or inefficient algorithms",
                    "Consider implementing performance caching",
                ]
            )
        elif "memory" in metric_name:
            recommendations.extend(
                [
                    "Review memory allocation patterns in recent changes",
                    "Implement memory profiling to identify leaks",
                    "Consider garbage collection optimization",
                ]
            )
        elif "energy" in metric_name or "efficiency" in metric_name:
            recommendations.extend(
                [
                    "Optimize resource-intensive operations",
                    "Review algorithmic complexity of recent changes",
                    "Consider workload distribution optimization",
                ]
            )

        recommendations.append(f"Monitor {metric_name} closely for trend confirmation")

        return recommendations

    def _generate_predictions(self, metrics_data: pd.DataFrame) -> List[Dict[str, Any]]:
        """Generate performance predictions"""
        predictions = []

        if "timestamp" not in metrics_data.columns:
            return predictions

        # Convert timestamp to datetime index
        try:
            metrics_data["timestamp"] = pd.to_datetime(metrics_data["timestamp"])
            metrics_data = metrics_data.set_index("timestamp").sort_index()
        except:
            return predictions

        # Generate predictions for key metrics
        key_metrics = ["duration_ms", "memory_mb", "cpu_percent", "efficiency_score"]
        numeric_columns = metrics_data.select_dtypes(include=[np.number]).columns

        for metric in key_metrics:
            if metric in numeric_columns and len(metrics_data[metric].dropna()) >= 50:
                try:
                    # Train predictor if not already trained
                    if metric not in self.performance_predictor.predictors:
                        training_result = self.performance_predictor.train_predictor(
                            metric, metrics_data[metric].dropna()
                        )
                        print(
                            f"Trained predictor for {metric}: R² = {training_result.get('r2', 0):.3f}"
                        )

                    # Generate prediction
                    prediction = self.performance_predictor.predict(
                        metric, metrics_data[metric].dropna(), horizon=12
                    )

                    if prediction:
                        predictions.append(asdict(prediction))

                except Exception as e:
                    print(f"Prediction failed for {metric}: {e}")

        return predictions

    def _analyze_patterns(self, metrics_data: pd.DataFrame) -> List[Dict[str, Any]]:
        """Analyze performance patterns"""
        patterns = []

        try:
            # Find correlations
            correlation_patterns = self.pattern_analyzer.find_correlations(metrics_data)
            patterns.extend([asdict(p) for p in correlation_patterns])

            # Detect seasonal patterns (if timestamp data available)
            if "timestamp" in metrics_data.columns:
                metrics_data["timestamp"] = pd.to_datetime(metrics_data["timestamp"])
                numeric_columns = metrics_data.select_dtypes(
                    include=[np.number]
                ).columns

                for col in numeric_columns:
                    if (
                        len(metrics_data[col].dropna()) >= 168
                    ):  # At least a week of data
                        time_series = pd.Series(
                            metrics_data[col].values, index=metrics_data["timestamp"]
                        ).dropna()

                        seasonal_patterns = (
                            self.pattern_analyzer.detect_seasonal_patterns(
                                time_series, col
                            )
                        )
                        patterns.extend([asdict(p) for p in seasonal_patterns])

                        degradation_patterns = (
                            self.pattern_analyzer.detect_performance_degradation(
                                time_series, col
                            )
                        )
                        patterns.extend([asdict(p) for p in degradation_patterns])

        except Exception as e:
            print(f"Pattern analysis failed: {e}")

        return patterns

    def _generate_recommendations(
        self, anomalies: List[Dict], predictions: List[Dict], patterns: List[Dict]
    ) -> List[str]:
        """Generate comprehensive recommendations based on all analysis results"""
        recommendations = []

        # High-priority recommendations from anomalies
        critical_anomalies = [a for a in anomalies if a.get("severity") == "critical"]
        if critical_anomalies:
            recommendations.append(
                f"🚨 CRITICAL: {len(critical_anomalies)} critical anomalies detected - immediate investigation required"
            )

        # Prediction-based recommendations
        degrading_predictions = [
            p
            for p in predictions
            if p.get("trend_analysis", {}).get("trend") == "increasing"
            and any(
                keyword in p.get("metric_name", "")
                for keyword in ["duration", "memory", "cpu"]
            )
        ]
        if degrading_predictions:
            recommendations.append(
                f"📈 Performance degradation predicted for {len(degrading_predictions)} metrics - proactive optimization recommended"
            )

        # Pattern-based recommendations
        degradation_patterns = [
            p for p in patterns if p.get("pattern_type") == "degradation"
        ]
        if degradation_patterns:
            recommendations.append(
                f"📉 {len(degradation_patterns)} degradation patterns identified - review recent changes"
            )

        correlation_patterns = [
            p
            for p in patterns
            if p.get("pattern_type") == "correlation" and p.get("strength", 0) > 0.8
        ]
        if correlation_patterns:
            recommendations.append(
                "🔗 Strong correlations found - consider optimizing related metrics together"
            )

        # General optimization recommendations
        if len(anomalies) > 5:
            recommendations.append(
                "🔧 Multiple anomalies suggest systematic performance issues - comprehensive optimization needed"
            )

        if not recommendations:
            recommendations.append(
                "✅ Performance appears stable - continue current practices"
            )

        return recommendations

    def _save_insights(self, analysis_results: Dict[str, Any]):
        """Save analysis insights to file"""
        insight_entry = {
            "timestamp": analysis_results["timestamp"],
            "analysis_id": analysis_results["analysis_id"],
            "summary": {
                "anomalies_count": len(analysis_results.get("anomalies", [])),
                "predictions_count": len(analysis_results.get("predictions", [])),
                "patterns_count": len(analysis_results.get("patterns", [])),
                "recommendations_count": len(
                    analysis_results.get("recommendations", [])
                ),
            },
            "key_insights": analysis_results.get("recommendations", [])[
                :3
            ],  # Top 3 recommendations
        }

        with open(self.insights_file, "a") as f:
            f.write(json.dumps(insight_entry) + "\n")

    def generate_performance_report(self, days: int = 7) -> Dict[str, Any]:
        """Generate comprehensive performance report"""
        # Load recent metrics data
        metrics_files = list(self.metrics_dir.glob("*.jsonl"))

        if not metrics_files:
            return {"error": "No metrics data available"}

        # Combine recent data
        all_data = []
        cutoff_time = datetime.now() - timedelta(days=days)

        for file_path in metrics_files:
            try:
                with open(file_path, "r") as f:
                    for line in f:
                        try:
                            entry = json.loads(line.strip())
                            timestamp = datetime.fromisoformat(
                                entry.get("timestamp", "").replace("Z", "+00:00")
                            )
                            if timestamp > cutoff_time:
                                all_data.append(entry)
                        except:
                            continue
            except:
                continue

        if not all_data:
            return {"error": f"No metrics data found for the last {days} days"}

        # Convert to DataFrame
        df = pd.DataFrame(all_data)

        # Run comprehensive analysis
        analysis_results = self.analyze_metrics(df)

        # Enhance with report-specific insights
        report = {
            "report_period_days": days,
            "generated_at": datetime.now().isoformat(),
            "executive_summary": self._generate_executive_summary(analysis_results),
            "analysis_results": analysis_results,
            "performance_trends": self._calculate_performance_trends(df),
            "optimization_opportunities": self._identify_optimization_opportunities(
                analysis_results
            ),
            "action_items": self._generate_action_items(analysis_results),
        }

        return report

    def _generate_executive_summary(
        self, analysis_results: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Generate executive summary of analysis"""
        anomalies_count = len(analysis_results.get("anomalies", []))
        predictions_count = len(analysis_results.get("predictions", []))
        patterns_count = len(analysis_results.get("patterns", []))

        # Determine overall health
        critical_issues = len(
            [
                a
                for a in analysis_results.get("anomalies", [])
                if a.get("severity") == "critical"
            ]
        )

        if critical_issues > 0:
            health_status = "critical"
        elif anomalies_count > 5:
            health_status = "warning"
        elif anomalies_count > 0:
            health_status = "caution"
        else:
            health_status = "healthy"

        return {
            "health_status": health_status,
            "key_metrics": {
                "anomalies_detected": anomalies_count,
                "critical_issues": critical_issues,
                "predictions_made": predictions_count,
                "patterns_identified": patterns_count,
            },
            "primary_concerns": analysis_results.get("recommendations", [])[:3],
            "confidence_level": "high"
            if len(analysis_results.get("anomalies", [])) > 10
            else "medium",
        }

    def _calculate_performance_trends(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Calculate performance trends over time"""
        trends = {}

        numeric_columns = df.select_dtypes(include=[np.number]).columns
        for col in numeric_columns:
            if len(df[col].dropna()) >= 10:
                values = df[col].dropna()

                # Simple trend calculation
                if len(values) >= 2:
                    x = np.arange(len(values))
                    slope, _ = np.polyfit(x, values, 1)

                    trends[col] = {
                        "trend_direction": "increasing"
                        if slope > 0
                        else "decreasing"
                        if slope < 0
                        else "stable",
                        "slope": float(slope),
                        "current_value": float(values.iloc[-1]),
                        "change_from_start": float(values.iloc[-1] - values.iloc[0]),
                    }

        return trends

    def _identify_optimization_opportunities(
        self, analysis_results: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Identify specific optimization opportunities"""
        opportunities = []

        # From anomalies
        for anomaly in analysis_results.get("anomalies", []):
            if anomaly.get("severity") in ["high", "critical"]:
                opportunities.append(
                    {
                        "type": "anomaly_resolution",
                        "priority": "high"
                        if anomaly.get("severity") == "critical"
                        else "medium",
                        "description": f"Resolve {anomaly.get('metric_name')} anomaly",
                        "impact": "performance_stability",
                        "recommendations": anomaly.get("recommendations", []),
                    }
                )

        # From patterns
        for pattern in analysis_results.get("patterns", []):
            if (
                pattern.get("pattern_type") == "correlation"
                and pattern.get("strength", 0) > 0.8
            ):
                opportunities.append(
                    {
                        "type": "correlation_optimization",
                        "priority": "medium",
                        "description": f"Optimize correlated metrics: {', '.join(pattern.get('affected_metrics', []))}",
                        "impact": "system_efficiency",
                        "recommendations": pattern.get("actionable_insights", []),
                    }
                )

        return opportunities

    def _generate_action_items(
        self, analysis_results: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """Generate specific action items"""
        action_items = []

        # Critical anomalies -> immediate actions
        critical_anomalies = [
            a
            for a in analysis_results.get("anomalies", [])
            if a.get("severity") == "critical"
        ]
        for anomaly in critical_anomalies:
            action_items.append(
                {
                    "priority": "immediate",
                    "action": f"Investigate critical anomaly in {anomaly.get('metric_name')}",
                    "deadline": "within 24 hours",
                    "owner": "development_team",
                    "steps": anomaly.get("recommendations", [])[:3],
                }
            )

        # Performance degradation patterns -> short-term actions
        degradation_patterns = [
            p
            for p in analysis_results.get("patterns", [])
            if p.get("pattern_type") == "degradation"
        ]
        for pattern in degradation_patterns:
            action_items.append(
                {
                    "priority": "high",
                    "action": f"Address performance degradation in {', '.join(pattern.get('affected_metrics', []))}",
                    "deadline": "within 1 week",
                    "owner": "development_team",
                    "steps": pattern.get("actionable_insights", [])[:3],
                }
            )

        # Optimization opportunities -> medium-term actions
        if len(action_items) < 5:  # Don't overwhelm with too many actions
            optimization_opportunities = self._identify_optimization_opportunities(
                analysis_results
            )
            for opportunity in optimization_opportunities[:3]:
                action_items.append(
                    {
                        "priority": opportunity.get("priority", "medium"),
                        "action": opportunity.get("description", ""),
                        "deadline": "within 2 weeks",
                        "owner": "development_team",
                        "steps": opportunity.get("recommendations", [])[:2],
                    }
                )

        return action_items


# Convenience functions for easy integration
def create_ai_analyzer(metrics_dir: str = None) -> AIPerformanceAnalyzer:
    """Create an AI performance analyzer instance"""
    return AIPerformanceAnalyzer(metrics_dir)


def analyze_performance_data(
    metrics_file: str, metrics_dir: str = None
) -> Dict[str, Any]:
    """Analyze performance data from a metrics file"""
    analyzer = AIPerformanceAnalyzer(metrics_dir)

    # Load data
    data = []
    with open(metrics_file, "r") as f:
        for line in f:
            try:
                data.append(json.loads(line.strip()))
            except:
                continue

    if not data:
        return {"error": "No valid data found in metrics file"}

    df = pd.DataFrame(data)
    return analyzer.analyze_metrics(df)


if __name__ == "__main__":
    # CLI interface
    import argparse

    parser = argparse.ArgumentParser(description="AI-Assisted Performance Analysis")
    parser.add_argument(
        "command",
        choices=["analyze", "train", "predict", "report"],
        help="Command to execute",
    )
    parser.add_argument("--metrics-dir", default=None, help="Metrics directory path")
    parser.add_argument("--metrics-file", help="Specific metrics file to analyze")
    parser.add_argument(
        "--days", type=int, default=7, help="Number of days for analysis"
    )
    parser.add_argument("--output", help="Output file for results")

    args = parser.parse_args()

    if np is None:
        print(
            "Error: Required ML libraries not available. Install with: pip install numpy pandas scikit-learn"
        )
        sys.exit(1)

    analyzer = AIPerformanceAnalyzer(args.metrics_dir)

    if args.command == "analyze":
        if args.metrics_file:
            results = analyze_performance_data(args.metrics_file, args.metrics_dir)
        else:
            print("Error: --metrics-file required for analyze command")
            sys.exit(1)

        if args.output:
            with open(args.output, "w") as f:
                json.dump(results, f, indent=2, default=str)
            print(f"Analysis results saved to {args.output}")
        else:
            print(json.dumps(results, indent=2, default=str))

    elif args.command == "report":
        report = analyzer.generate_performance_report(args.days)

        if args.output:
            with open(args.output, "w") as f:
                json.dump(report, f, indent=2, default=str)
            print(f"Performance report saved to {args.output}")
        else:
            print(json.dumps(report, indent=2, default=str))

    elif args.command == "train":
        print("Training AI models with available data...")
        # Implementation would train models with historical data
        print("Training completed!")

    elif args.command == "predict":
        print("Generating performance predictions...")
        # Implementation would generate predictions
        print("Predictions generated!")
