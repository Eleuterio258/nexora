"""
Metricas de sincronizacao com o Nexora ERP: tentativas, sucessos, falhas e
latencia do envio de eventos de assiduidade (Fase 5.5 da integracao).
Armazena metricas em memoria e expoe via /metrics.
"""
import threading
from dataclasses import dataclass, field


@dataclass
class ErpSyncMetrics:
    """Metricas de envio de clock_records ao ERP acumuladas desde o inicio do processo."""

    attempts_total: int = 0
    success_total: int = 0
    failure_total: int = 0

    duration_ms_sum: float = 0.0
    duration_ms_count: int = 0

    _lock: threading.Lock = field(default_factory=threading.Lock, repr=False)

    def record_success(self, duration_ms: float) -> None:
        with self._lock:
            self.attempts_total += 1
            self.success_total += 1
            self.duration_ms_sum += duration_ms
            self.duration_ms_count += 1

    def record_failure(self, duration_ms: float) -> None:
        with self._lock:
            self.attempts_total += 1
            self.failure_total += 1
            self.duration_ms_sum += duration_ms
            self.duration_ms_count += 1

    @property
    def avg_duration_ms(self) -> float:
        if self.duration_ms_count == 0:
            return 0.0
        return round(self.duration_ms_sum / self.duration_ms_count, 2)

    @property
    def failure_rate(self) -> float:
        if self.attempts_total == 0:
            return 0.0
        return round(self.failure_total / self.attempts_total, 4)

    def to_prometheus_format(self) -> list[str]:
        with self._lock:
            return [
                f"erp_sync_attempts_total {self.attempts_total}",
                f"erp_sync_success_total {self.success_total}",
                f"erp_sync_failure_total {self.failure_total}",
                f"erp_sync_failure_rate {self.failure_rate}",
                f"erp_sync_duration_ms_avg {self.avg_duration_ms}",
            ]


erp_sync_metrics = ErpSyncMetrics()
