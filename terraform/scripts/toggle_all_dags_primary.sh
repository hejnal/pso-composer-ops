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

# Check if required arguments are provided
if [ -z "$PROJECT" ]; then
  echo "Error: --project argument is required." >&2
  exit 1
fi

if [ -z "$ENVIRONMENT" ]; then
  echo "Error: --environment argument is required." >&2
  exit 1
fi

if [ -z "$LOCATION" ]; then
  echo "Error: --location argument is required." >&2
  exit 1
fi

if [ -z "$OPERATION" ]; then
  echo "Error: --operation argument is required." >&2
  exit 1
fi

(
  cd "${SCRIPT_DIR}"
  python3 -m venv env
  source env/bin/activate
  which python
  pip install -r requirements.txt
  python3 "${SCRIPT_DIR}/composer_dags.py" --project "$PROJECT" --environment "$ENVIRONMENT" --location "$LOCATION" --operation "$OPERATION"
  deactivate
)