#!/bin/bash
# Unless the project root has a vibecode.json, Vibecode puts its own copy of this file back
# each time the backend restarts (after every turn), so edits here are lost. To keep one, create
# backend/.vibecode/no-template-sync in the same step, commit both, and tell the user this project
# then stops getting Vibecode's fixes to these scripts.
# Shared environment setup for backend scripts

ENVIRONMENT="${ENVIRONMENT:-development}"

if [[ "${ENVIRONMENT}" == "production" ]]; then
  echo "Starting in production mode..."
  export NODE_ENV="production"
  DATA_DIR="${DATA_DIR:-/data}"
  export DATABASE_FILE="${DATA_DIR}/production.db"
  export DATABASE_URL="file:${DATABASE_FILE}"
else
  echo "Starting in development mode..."
  export NODE_ENV="development"
fi
