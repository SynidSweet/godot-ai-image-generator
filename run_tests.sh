#!/bin/bash

# Run GUT tests from command line
# Usage: ./run_tests.sh

# Check if godot is available
if ! command -v godot &> /dev/null; then
    echo "Error: godot command not found in PATH"
    echo "Please ensure Godot 4.x is installed and available as 'godot' command"
    exit 1
fi

# Run tests
echo "Running GUT tests..."
godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://test/ -gexit

echo ""
echo "Tests complete!"
