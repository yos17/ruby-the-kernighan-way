# Exercise 1 — tasks edit ID NEW_TEXT
#
# Add an `edit` command. Usage: tasks edit 2 "study Rails"
#
# Modify your copy of examples/tasks.rb. Specifically:
#   1. Add :edit to COMMANDS
#   2. Add a TaskStore method that updates a task's text
#   3. Add a CLI#edit method that parses ID + remaining args as new text
#
# Test: copy tasks.rb, add the changes, then:
#   ruby my_tasks.rb add "buy mlk"
#   ruby my_tasks.rb edit 1 "buy milk"
#   ruby my_tasks.rb list
