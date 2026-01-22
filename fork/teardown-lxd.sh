#!/bin/bash
set -e

CONTAINER_NAME="${1:-kan}"

echo "Deleting LXD container: $CONTAINER_NAME"
lxc delete "$CONTAINER_NAME" --force

echo "Done."
