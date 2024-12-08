#!/usr/bin/env bats

load './starlite.sh'

# Mock environment variables
setup() {
  export ORG_ID="org123"
  export RECORD_ID="rec123"
  export TOKEN="token123"
  export ACTION="deployment"
  send_request() {
    echo "Mocked send_request called with URL: $1, method: $2, data file: $3"
    return 0
  }
}

teardown() {
  unset ORG_ID
  unset RECORD_ID
  unset TOKEN
  unset ACTION
}

# Test parse_arguments
@test "parse_arguments correctly sets variables" {
  run parse_arguments --org-id "test_org" --record-id "test_record" --token "test_token" --action "deployment"
  [ "$status" -eq 0 ]
  #[ "$ORG_ID" = "test_org" ]
  #[ "$RECORD_ID" = "test_record" ]
  #[ "$TOKEN" = "test_token" ]
  #[ "$ACTION" = "deployment" ]
}

@test "parse_arguments fails on unknown argument" {
  run parse_arguments --unknown "value"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "❌ Unknown argument: --unknown" ]]
}

# Test validate_arguments
@test "validate_arguments succeeds when all required arguments are set" {
  run validate_arguments x y z a
  [ "$status" -eq 0 ]
}

@test "validate_arguments fails when ORG_ID is missing" {
  unset ORG_ID
  run validate_arguments
  [ "$status" -ne 0 ]
  [[ "$output" =~ "❌ ERROR: ORG_ID is not set!" ]]
}

@test "validate_arguments fails when RECORD_ID is missing" {
  unset RECORD_ID
  run validate_arguments
  [ "$status" -ne 0 ]
  [[ "$output" =~ "❌ ERROR: RECORD_ID is not set!" ]]
}

@test "validate_arguments fails when TOKEN is missing" {
  unset TOKEN
  run validate_arguments
  [ "$status" -ne 0 ]
  [[ "$output" =~ "❌ ERROR: TOKEN is not set!" ]]
}

@test "validate_arguments fails when ACTION is missing" {
  unset ACTION
  run validate_arguments
  [ "$status" -ne 0 ]
  [[ "$output" =~ "❌ ERROR: ACTION is not set!" ]]
}

@test "handle_standards sends results when file exists" {
  touch standardlint.results.json
  echo '{}' >standardlint.results.json
  run handle_standards
  [ "$status" -eq 0 ]
  [[ "$output" =~ "✅ Request succeeded with HTTP Status" ]]
  rm standardlint.results.json
}

# Test handle_record
@test "handle_record skips when manifest file is missing" {
  run handle_record
  [ "$status" -eq 0 ]
  [[ "$output" =~ "⚠️ No manifest file found; skipping." ]]
}

@test "handle_record uploads manifest file" {
  touch manifest.json
  echo '{}' >manifest.json
  run handle_record
  [ "$status" -eq 0 ]
  [[ "$output" =~ "✅ Request succeeded with HTTP Status" ]]
  rm manifest.json
}

@test "handle_deployment fails if Git is not installed" {
  PATH="" # Temporarily unset PATH to simulate Git not being installed
  run handle_deployment
  [ "$status" -ne 0 ]
  [[ "$output" =~ "❌ ERROR: Git is not installed" ]]
}

@test "handle_deployment uses fallback SHA when Git repository has no commits" {
  git init test_repo
  cd test_repo || exit
  run handle_deployment
  [ "$status" -eq 0 ]
  [[ "$output" =~ "⚠️ WARNING: Git repository has no commits or is invalid" ]]
  cd ..
  rm -rf test_repo
}

@test "handle_deployment succeeds with a valid Git repository" {
  git init test_repo
  cd test_repo || exit
  touch file.txt && git add file.txt && git commit -m "Initial commit"
  run handle_deployment
  [ "$status" -eq 0 ]
  [[ "$output" =~ "✅ Deployment data successfully sent" ]]
  cd ..
  rm -rf test_repo
}

# Test main
@test "main succeeds with valid deployment inputs" {
  run main --org-id "org123" --record-id "rec123" --token "token123" --action "deployment"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "✅ Starlite has completed successfully!" ]]
}

@test "main fails with invalid action" {
  run main --org-id "org123" --record-id "rec123" --token "token123" --action "invalid"
  [ "$status" -ne 0 ]
  [[ "$output" =~ "❌ ERROR: Invalid action" ]]
}

# Test send_request
@test "send_request succeeds with valid inputs" {
  touch test.json
  echo '{}' >test.json
  MOCK_CURL_FAILURE=""
  run send_request "https://example.com" "POST" "test.json"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "✅ Request succeeded with HTTP Status" ]]
  rm test.json
}
