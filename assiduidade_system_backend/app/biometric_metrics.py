"""
Metricas biometricas operacionais: FAR, FRR, taxa de match, etc.
Armazena metricas em memoria e expoe via /metrics.
"""
import threading
from dataclasses import dataclass, field


@dataclass
class BiometricMetrics:
    """Metricas biometricas acumuladas desde o inicio do processo."""
    total_enroll_attempts: int = 0
    total_enroll_success: int = 0
    total_enroll_failures: int = 0

    total_verify_attempts: int = 0
    total_verify_matches: int = 0
    total_verify_rejections: int = 0

    # FAR (False Acceptance Rate): impostor aceito como genuino
    far_attempts: int = 0
    far_acceptances: int = 0

    # FRR (False Rejection Rate): usuario genuino rejeitado
    frr_attempts: int = 0
    frr_rejections: int = 0

    # Scores medios
    confidence_scores_sum: float = 0.0
    confidence_scores_count: int = 0

    liveness_scores_sum: float = 0.0
    liveness_scores_count: int = 0

    # Liveness failures
    liveness_failures: int = 0

    # Quality failures
    quality_failures: int = 0

    _lock: threading.Lock = field(default_factory=threading.Lock, repr=False)

    def record_enroll_success(self):
        with self._lock:
            self.total_enroll_attempts += 1
            self.total_enroll_success += 1

    def record_enroll_failure(self):
        with self._lock:
            self.total_enroll_attempts += 1
            self.total_enroll_failures += 1

    def record_verify_match(self, confidence: float, liveness: float):
        with self._lock:
            self.total_verify_attempts += 1
            self.total_verify_matches += 1
            self.confidence_scores_sum += confidence
            self.confidence_scores_count += 1
            self.liveness_scores_sum += liveness
            self.liveness_scores_count += 1

    def record_verify_rejection(self, reason: str, confidence: float = 0.0, liveness: float = 0.0):
        with self._lock:
            self.total_verify_attempts += 1
            self.total_verify_rejections += 1
            if reason == "match_below_threshold":
                self.frr_attempts += 1
                self.frr_rejections += 1
            elif reason == "liveness_failed":
                self.liveness_failures += 1
            elif reason in ("low_quality_capture", "blurry_capture", "poor_lighting", "face_too_small"):
                self.quality_failures += 1
            self.confidence_scores_sum += confidence
            self.confidence_scores_count += 1
            self.liveness_scores_sum += liveness
            self.liveness_scores_count += 1

    @property
    def far_rate(self) -> float:
        if self.far_attempts == 0:
            return 0.0
        return round(self.far_acceptances / self.far_attempts, 4)

    @property
    def frr_rate(self) -> float:
        if self.frr_attempts == 0:
            return 0.0
        return round(self.frr_rejections / self.frr_attempts, 4)

    @property
    def match_rate(self) -> float:
        if self.total_verify_attempts == 0:
            return 0.0
        return round(self.total_verify_matches / self.total_verify_attempts, 4)

    @property
    def avg_confidence(self) -> float:
        if self.confidence_scores_count == 0:
            return 0.0
        return round(self.confidence_scores_sum / self.confidence_scores_count, 4)

    @property
    def avg_liveness(self) -> float:
        if self.liveness_scores_count == 0:
            return 0.0
        return round(self.liveness_scores_sum / self.liveness_scores_count, 4)

    def to_prometheus_format(self) -> list[str]:
        with self._lock:
            return [
                f"biometric_enroll_attempts_total {self.total_enroll_attempts}",
                f"biometric_enroll_success_total {self.total_enroll_success}",
                f"biometric_enroll_failure_total {self.total_enroll_failures}",
                f"biometric_verify_attempts_total {self.total_verify_attempts}",
                f"biometric_verify_matches_total {self.total_verify_matches}",
                f"biometric_verify_rejections_total {self.total_verify_rejections}",
                f"biometric_far_rate {self.far_rate}",
                f"biometric_frr_rate {self.frr_rate}",
                f"biometric_match_rate {self.match_rate}",
                f"biometric_avg_confidence {self.avg_confidence}",
                f"biometric_avg_liveness {self.avg_liveness}",
                f"biometric_liveness_failures_total {self.liveness_failures}",
                f"biometric_quality_failures_total {self.quality_failures}",
            ]


biometric_metrics = BiometricMetrics()
