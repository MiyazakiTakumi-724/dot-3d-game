#!/bin/sh
# Usage: ./run_tests.sh [test_file.gd]
godot --headless --import >/dev/null 2>&1
if [ -n "$1" ]; then
  exec godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/$1 -gexit
fi
exec godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
