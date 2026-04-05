#!/bin/bash
# Run an entire Bruno collection and export results as JSON + HTML.
#
# Usage:
#   ./run-collection.sh [environment]
#
# Examples:
#   ./run-collection.sh           # defaults to local
#   ./run-collection.sh production
#
# Requirements:
#   npm install -g @usebruno/cli

COLLECTION="collections/ai-uw-lambda"
ENV="${1:-local}"
OUTPUT_DIR="scripts/examples/output"

cd "$(dirname "$0")/../.." || exit 1

mkdir -p "$OUTPUT_DIR"

bru run \
  --path "$COLLECTION" \
  --env "$ENV" \
  --reporter-json "$OUTPUT_DIR/results.json" \
  --reporter-html "$OUTPUT_DIR/results.html"

echo ""
echo "Results saved to $OUTPUT_DIR/"
