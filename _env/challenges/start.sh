#!/bin/bash
set -e

echo "Starting challenges"

echo "[1]: One-time pad"
( cd one-time-pad && ./one-time-pad.py ) &

echo "[2]: One-time pad 2"
( cd one-time-pad-2 && ./one-time-pad.py ) &

wait
