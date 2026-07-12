from fastapi import APIRouter, Request
from fastapi.responses import PlainTextResponse

from app.biometric_metrics import biometric_metrics
from app.erp_sync_metrics import erp_sync_metrics


router = APIRouter(tags=["Monitoring"])


@router.get("/metrics", response_class=PlainTextResponse)
def metrics(request: Request) -> str:
    metric_state = request.app.state.metrics
    total_requests = metric_state["http_requests_total"]
    avg_duration = 0.0
    p95_duration = 0.0
    p99_duration = 0.0
    if total_requests:
        avg_duration = metric_state["http_request_duration_ms_sum"] / total_requests
        durations = sorted(metric_state.get("http_request_durations_ms", []))
        if durations:
            p95_idx = min(int(len(durations) * 0.95), len(durations) - 1)
            p99_idx = min(int(len(durations) * 0.99), len(durations) - 1)
            p95_duration = durations[p95_idx]
            p99_duration = durations[p99_idx]

    lines = [
        f"http_requests_total {total_requests}",
        f"http_errors_total {metric_state['http_errors_total']}",
        f"http_request_duration_ms_avg {avg_duration:.2f}",
        f"http_request_duration_ms_p95 {p95_duration:.2f}",
        f"http_request_duration_ms_p99 {p99_duration:.2f}",
    ]
    for path, count in sorted(metric_state["http_requests_by_path"].items()):
        sanitized_path = path.replace("/", "_").strip("_") or "root"
        lines.append(f'http_requests_by_path{{path="{sanitized_path}"}} {count}')

    lines.extend(biometric_metrics.to_prometheus_format())
    lines.extend(erp_sync_metrics.to_prometheus_format())

    return "\n".join(lines) + "\n"
