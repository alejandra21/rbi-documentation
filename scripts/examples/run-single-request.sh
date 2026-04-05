#!/bin/bash
# Run a single Bruno request from the terminal.
#
# Usage:
#   ./run-single-request.sh
#
# Requirements:
#   npm install -g @usebruno/cli

COLLECTION="collections/ai-uw-lambda"
REQUEST="initial-phase/Initial Validation.bru"
ENV="local"

# Navigate to repo root (works regardless of where you call the script from)
cd "$(dirname "$0")/../.." || exit 1

bru run "$REQUEST" --env "$ENV" --path "$COLLECTION"
