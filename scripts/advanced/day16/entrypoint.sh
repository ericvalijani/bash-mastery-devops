#!/bin/sh
echo "Container started at $(date)"

# Run the command passed to the container (this is the real entrypoint job)
exec "$@"
