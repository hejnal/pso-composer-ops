#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT="$2"
      shift 2
      ;;
    --environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --location)
      LOCATION="$2"
      shift 2
      ;;
    --snapshot_bucket)
      SNAPSHOT_BUCKET="$2"
      shift 2
      ;;
    --operation)
      OPERATION="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# --- Validation ---

# Check if all required arguments are provided
if [ -z "$PROJECT" ] || [ -z "$ENVIRONMENT" ] || [ -z "$LOCATION" ] || [ -z "$SNAPSHOT_BUCKET" ] || [ -z "$OPERATION" ]; then
  echo "Error: Missing arguments." >&2
  echo "Usage: $0 --project <PROJECT> --environment <ENVIRONMENT> --location <LOCATION> --snapshot_bucket <SNAPSHOT_BUCKET> --operation <create|restore>" >&2
  exit 1
fi

# Check if operation is valid
if [[ "$OPERATION" != "create" && "$OPERATION" != "restore" ]]; then
  echo "Error: Invalid operation. Must be 'create' or 'restore'." >&2
  exit 1
fi

# --- End of Validation ---

(
  cd "${SCRIPT_DIR}"
  python3 -m venv env
  source env/bin/activate
  which python
  pip install -r requirements.txt

  python3 "${SCRIPT_DIR}/composer_snapshot_manager.py" --project "$PROJECT" --environment "$ENVIRONMENT" --location "$LOCATION" --snapshot_bucket "$SNAPSHOT_BUCKET" --operation "$OPERATION"

  deactivate
)