#!/usr/bin/env bash

# Set the default values.
OUTPUT_FILE=".gas-snapshot"
FOUNDRY_PROFILE="default"
TEMP_FILE=$(mktemp)

# Utility function to print usage.
print_usage() {
  echo "Usage: $0 [--venom]"
  echo "  --venom    Use Venom configuration"
}

# Utility function to prepend content to the output file.
prepend_to_output() {
  echo "$1" >> "$TEMP_FILE"
}

# Parse the command line arguments.
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --venom)
      OUTPUT_FILE=".gas-snapshot-venom"
      FOUNDRY_PROFILE="default-venom"
      ;;
    --help)
      print_usage
      exit 0
      ;;
    *)
      echo "Error: Unknown parameter passed: $1"
      print_usage
      exit 1
      ;;
  esac
  shift
done

# Set the environment variable.
export FOUNDRY_PROFILE

# Generate the snapshot file.
forge snapshot --snap "$OUTPUT_FILE"

# Prepare the content to be prepended.
prepend_to_output "Vyper version: $(vyper --version)"
prepend_to_output "Forge version: $(forge --version)"
prepend_to_output "Vyper config:"
forge config --json | jq -r ".vyper" >> "$TEMP_FILE"
prepend_to_output "=========================================="
prepend_to_output "██╗░░░██╗██╗░░░██╗██████╗░███████╗██████╗░"
prepend_to_output "██║░░░██║╚██╗░██╔╝██╔══██╗██╔════╝██╔══██╗"
prepend_to_output "╚██╗░██╔╝░╚████╔╝░██████╔╝█████╗░░██████╔╝"
prepend_to_output "░╚████╔╝░░░╚██╔╝░░██╔═══╝░██╔══╝░░██╔══██╗"
prepend_to_output "░░╚██╔╝░░░░░██║░░░██║░░░░░███████╗██║░░██║"
prepend_to_output "░░░╚═╝░░░░░░╚═╝░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝"
prepend_to_output "=========================================="

# Prepend the prepared content to the snapshot file.
cat "$TEMP_FILE" "$OUTPUT_FILE" > "${OUTPUT_FILE}.tmp" && mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

# Clean up the temporary file.
rm "$TEMP_FILE"

echo "Gas snapshot generated in $OUTPUT_FILE"
