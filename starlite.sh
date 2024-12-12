#!/bin/bash -l

set -euo pipefail

ENDPOINT_BASE="https://78ryomnr49.execute-api.eu-north-1.amazonaws.com" #"https://www.mockachino.com/2cf87bb2-b2ea-4c"

parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    --org-id)
      ORG_ID="$2"
      shift 2
      ;;
    --record-id)
      RECORD_ID="$2"
      shift 2
      ;;
    --token)
      TOKEN="$2"
      shift 2
      ;;
    --action)
      ACTION="$2"
      shift 2
      ;;
    *)
      echo "❌ Unknown argument: $1" >&2
      return 1
      ;;
    esac
  done
}

validate_arguments() {
  if [ -z "${ORG_ID:-}" ]; then
    echo "❌ ERROR: ORG_ID is not set!" >&2
    return 1
  fi

  if [ -z "${RECORD_ID:-}" ]; then
    echo "❌ ERROR: RECORD_ID is not set!" >&2
    return 1
  fi

  if [ -z "${TOKEN:-}" ]; then
    echo "❌ ERROR: TOKEN is not set!" >&2
    return 1
  fi

  if [ -z "${ACTION:-}" ]; then
    echo "❌ ERROR: ACTION is not set!" >&2
    return 1
  fi
}

send_request() {
  local url="$1"
  local method="$2"
  local data_file="$3"

  if [[ -n "${MOCK_CURL_FAILURE:-}" ]]; then
    echo "❌ Mocked HTTP call failed." >&2
    return 1
  fi

  RAW_RESPONSE=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
    -d @"$data_file" -H "Content-Type: application/json")

  RESPONSE_BODY=$(echo "$RAW_RESPONSE" | sed '$d')
  HTTP_STATUS=$(echo "$RAW_RESPONSE" | tail -n 1)

  if [[ -z "$HTTP_STATUS" || "$HTTP_STATUS" -ne 200 ]]; then
    echo "❌ ERROR: Request failed. HTTP Status: $HTTP_STATUS" >&2
    echo "Response: $RESPONSE_BODY" >&2
    return 1
  fi

  echo "✅ Request succeeded with HTTP Status: $HTTP_STATUS"
}

handle_deployment() {
  local current_git_sha

  # Check if Git is installed
  if ! command -v git >/dev/null 2>&1; then
    echo "❌ ERROR: Git is not installed. Cannot proceed with deployment." >&2
    return 1
  fi

  # Get the current Git SHA or handle errors gracefully
  if ! current_git_sha=$(git log --pretty=format:'%H' -n 1 2>/dev/null); then
    echo "⚠️ WARNING: Git repository has no commits or is invalid. Using fallback SHA." >&2
    current_git_sha="demo_commit_sha"
  fi

  # Create deployment data
  local deployment_file="deployment.json"
  cat >"$deployment_file" <<EOF
{
  "event": "deployment",
  "commitSha": "$current_git_sha"
}
EOF

  # Send deployment data
  local url="$ENDPOINT_BASE/event/$ORG_ID/$RECORD_ID/$TOKEN"
  if ! send_request "$url" "POST" "$deployment_file"; then
    echo "❌ ERROR: Failed to send deployment data." >&2
    rm -f "$deployment_file"
    return 1
  fi

  echo "✅ Deployment data successfully sent."
  rm -f "$deployment_file"
  return 0
}

handle_standards() {
  if [[ -f "standardlint.json" ]]; then
    if command -v node &>/dev/null; then
      npm install standardlint
      npx standardlint --output
    else
      echo "❌ Node.js is required to generate Standards output. Please make sure you have Node and NPM in your environment."
      exit 1
    fi
  fi

  if [[ -f "standardlint.results.json" ]]; then
    local url="$ENDPOINT_BASE/standards/$ORG_ID/$RECORD_ID/$TOKEN"
    send_request "$url" "POST" "standardlint.results.json"
  else
    echo "⚠️ No standards results file found; skipping."
  fi
}

handle_record() {
  if [[ -f "manifest.json" ]]; then
    echo "Uploading record to Starlite..."
    local url="$ENDPOINT_BASE/record/$ORG_ID/$RECORD_ID/$TOKEN"
    send_request "$url" "POST" "manifest.json"
  else
    echo "⚠️ No manifest file found; skipping."
  fi
}

main() {
  parse_arguments "$@" || exit 1
  validate_arguments || exit 1

  case "$ACTION" in
  "deployment")
    handle_deployment
    ;;
  "standards")
    handle_standards
    ;;
  "record")
    handle_record
    ;;
  *)
    echo "❌ ERROR: Invalid action: $ACTION" >&2
    exit 1
    ;;
  esac

  echo "✅ Starlite has completed successfully!"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi
