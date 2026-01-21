
#!/usr/bin/env bash

set -e

# =========================
# 변수 설정
# =========================
LOG_DIR="${LOG_DIR:-/data/flowkat-proxy/data/logs}"
LOG_FILE="custom_vhost_access.log"
OUTPUT_DIR="${OUTPUT_DIR:-/data/flowkat-proxy}"
IMAGE="goaccess-flowkat"
LOG_PATH="/logs/$LOG_FILE"
DATE_FORMAT="%d/%b/%Y"
TIME_FORMAT="%H:%M:%S"

usage() {
  echo "Usage: $0 {tui|html|realtime|filter <keyword>}"
  echo
  echo "  tui               : TUI 대시보드 (Interactive)"
  echo "  html              : HTML 리포트 생성"
  echo "  realtime          : 실시간 웹 대시보드 (포트 7890)"
  echo "  filter <keyword>  : 키워드 필터링 후 HTML 리포트 생성"
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

MODE="$1"
KEYWORD="$2"

# =========================
# 실행 모드
# =========================
case "$MODE" in
  tui)
    docker run --rm -it \
      -v "$LOG_DIR":/logs \
      "$IMAGE" "$LOG_PATH" \
      --log-format="VCOMBINED" \
      --date-format="$DATE_FORMAT" \
      --time-format="$TIME_FORMAT"
    ;;

  html)
    docker run --rm \
      -v "$LOG_DIR":/logs \
      -v "$OUTPUT_DIR":/output \
      "$IMAGE" "$LOG_PATH" \
      --log-format="VCOMBINED" \
      --date-format="$DATE_FORMAT" \
      --time-format="$TIME_FORMAT" \
      -o /output/report.html

    echo "✅ HTML report generated: $OUTPUT_DIR/report.html"
    ;;

  realtime)
    docker run --rm -it \
      -p 7890:7890 \
      -v "$LOG_DIR":/logs \
      -v "$OUTPUT_DIR":/output \
      "$IMAGE" "$LOG_PATH" \
      --log-format="VCOMBINED" \
      --date-format="$DATE_FORMAT" \
      --time-format="$TIME_FORMAT" \
      -o /output/report.html \
      --real-time-html

    echo "🌐 Real-time dashboard: http://localhost:7890"
    ;;

  filter)
    if [ -z "$KEYWORD" ]; then
      echo "❌ filter mode requires a keyword"
      usage
    fi

    grep "$KEYWORD" "$LOG_DIR/$LOG_FILE" | \
      docker run --rm -i \
        -v "$OUTPUT_DIR":/output \
        "$IMAGE" - \
        --log-format="VCOMBINED" \
        --date-format="$DATE_FORMAT" \
        --time-format="$TIME_FORMAT" \
        -o /output/report.html

    echo "🔍 Filtered HTML report generated for keyword: $KEYWORD"
    ;;

  *)
    usage
    ;;
esac

