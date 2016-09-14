#!/bin/bash
set -e

echo "Starting challenges"

echo "[1]: One time pad"
( cd one-time-pad && ./one-time-pad.py )
