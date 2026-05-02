#!/bin/bash
# Stress test script for MyText app
# Opens and edits multiple files in parallel using AppleScript

set -e

APP_NAME="MyText"
TEST_DIR="/Users/thotas/Development/MyAppsDev/MyText/TestFiles"
NUM_FILES=${1:-10}
ITERATIONS=${2:-5}

echo "Creating $NUM_FILES test files..."
for i in $(seq 1 $NUM_FILES); do
  cat > "$TEST_DIR/test_file_$i.txt" << EOF
Test File $i
$(date)
============================

Line 1 of content in test file $i
Line 2 with some text
Line 3 with more content
Line 4 additional text
Line 5 final line

Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.

Quick brown fox jumps over the lazy dog.
The quick brown fox jumps over the lazy dog.
Pack my box with five dozen liquor jugs.

EOF
done

echo "Created $NUM_FILES test files"

# Function to open and edit a file
open_and_edit() {
  local file=$1
  local iteration=$2
  local osascript_cmd="
    tell application \"$APP_NAME\"
      activate
      delay 0.2
    end tell

    tell application \"System Events\"
      -- Open file with Cmd+O
      keystroke \"o\" using command down
      delay 0.3

      -- Type filename
      keystroke \"$file\"
      delay 0.2

      -- Press Enter
      keystroke return
      delay 0.5

      -- Edit content - add text at end
      keystroke \"e\" using command down  -- Move to end
      delay 0.1
      keystroke return
      keystroke \"Edited at $(date +%H:%M:%S) - Iteration $iteration\"
      delay 0.1

      -- Save with Cmd+S
      keystroke \"s\" using command down
      delay 0.2

      -- Close tab with Cmd+W
      keystroke \"w\" using command down
      delay 0.2
    end tell
  "
  osascript -e "$osascript_cmd" 2>/dev/null || true
}

echo "Starting stress test: $ITERATIONS iterations with $NUM_FILES files each"
for iter in $(seq 1 $ITERATIONS); do
  echo "=== Iteration $iter of $ITERATIONS ==="

  # Open files in parallel using background jobs
  for i in $(seq 1 $NUM_FILES); do
    open_and_edit "test_file_$i.txt" "$iter" &
  done

  # Wait for all parallel jobs
  wait

  echo "Iteration $iter complete"
done

echo "Stress test complete!"
echo "Verifying files were modified..."
ls -la "$TEST_DIR"/*.txt | head -20