# Exercise 5 — color overdue items
#
# When stdout is a terminal ($stdout.tty?), color overdue items red.
# When piped (e.g., to a file or another program), don't add color codes.
#
# ANSI codes:
#   "\e[31m" = start red
#   "\e[0m"  = reset
#
# Wrap the format_task output for overdue tasks in those codes when tty.
#
# Try:
#   ruby tasks.rb list             # colored
#   ruby tasks.rb list | cat       # NOT colored (cat is not a tty)
