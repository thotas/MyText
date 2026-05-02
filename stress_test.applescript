-- Stress Test AppleScript for MyText
-- Opens multiple files in tabs and performs concurrent edits

on openFile(filename)
    tell application "System Events"
        -- Open file dialog
        keystroke "o" using command down
        delay 0.2
        -- Type the filename
        keystroke filename
        delay 0.1
        keystroke return
        delay 0.3
    end tell
end openFile

on editFile(iteration)
    tell application "System Events"
        -- Move to end of document
        keystroke "e" using command down
        delay 0.05
        -- Add new line
        keystroke return
        delay 0.05
        -- Type edit content
        keystroke "=== EDIT " & iteration & " ==="
        delay 0.05
        -- Save
        keystroke "s" using command down
        delay 0.1
    end tell
end editFile

on closeTab()
    tell application "System Events"
        keystroke "w" using command down
        delay 0.1
    end tell
end closeTab

-- Main stress test
tell application "MyText"
    activate
end tell

delay 0.5

-- Open 5 files in tabs
set fileNames to {"test_file_1.txt", "test_file_2.txt", "test_file_3.txt", "test_file_4.txt", "test_file_5.txt"}

repeat with fileName in fileNames
    openFile(fileName)
    delay 0.3
end repeat

delay 1.0

-- Perform rapid edits on each tab (simulate parallel editing)
repeat 3 times
    -- Edit each tab
    repeat with i from 1 to length of fileNames
        -- Switch to tab i
        tell application "System Events"
            keystroke "{" using command down
            delay 0.1
        end tell

        editFile(i & "-1")
        editFile(i & "-2")
    end repeat
end repeat

delay 0.5

-- Close all tabs
repeat length of fileNames times
    closeTab()
end repeat

delay 0.3

return "Stress test completed"