#!/usr/bin/env swift
// Stress test for MyText app - Creates test files and opens them via AppleScript

import Foundation

let testDir = URL(fileURLWithPath: "/Users/thotas/Development/MyAppsDev/MyText/TestFiles")
let numFiles = 10
let iterations = 5

// Create test files
print("Creating \(numFiles) test files...")
for i in 1...numFiles {
    let content = """
    Test File \(i)
    Created: \(Date())
    ============================

    Line 1: Content for test file \(i)
    Line 2: Additional text here
    Line 3: More content to edit
    Line 4: Even more lines
    Line 5: Final line of initial content

    Paragraph of lorem ipsum.
    Lorem ipsum dolor sit amet, consectetur adipiscing elit.
    Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

    The quick brown fox jumps over the lazy dog.
    How vexingly quick daft zebras jump!

    End of file \(i).
    """
    let fileURL = testDir.appendingPathComponent("test_file_\(i).txt")
    try? content.write(to: fileURL, atomically: true, encoding: .utf8)
}
print("Created \(numFiles) test files")

// Build AppleScript to open all files in tabs
var script = """
tell application "MyText"
    activate
    delay 0.5
"""

for i in 1...numFiles {
    script += """

    -- Open test_file_\(i).txt
    tell application "System Events"
        keystroke "o" using command down
        delay 0.2
        keystroke "test_file_\(i).txt"
        keystroke return
        delay 0.3
    end tell
"""
}

script += """

    delay 1.0
"""

// Close tabs in reverse order
for i in stride(from: numFiles, through: 1, by: -1) {
    script += """

    -- Close tab \(i)
    tell application "System Events"
        keystroke "w" using command down
        delay 0.1
    end tell
"""
}

script += """

end tell
"""

// Run the AppleScript
print("Running AppleScript stress test...")
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
process.arguments = ["-e", script]

do {
    try process.run()
    process.waitUntilExit()
    print("AppleScript completed with exit code: \(process.terminationStatus)")
} catch {
    print("Error running AppleScript: \(error)")
}

print("Stress test files created at: \(testDir.path)")