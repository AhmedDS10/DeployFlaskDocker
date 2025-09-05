#!/bin/bash
set -e

echo ">>> Running Flask database migrations..."
flask db init || true
flask db migrate -m "Auto migration" || true
flask db upgrade || true

echo ">>> Creating admin user..."
flask create-admin || true

echo ">>> Starting Flask app..."
exec "$@"
