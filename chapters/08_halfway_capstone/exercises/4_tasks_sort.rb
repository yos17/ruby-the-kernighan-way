# Exercise 4 — sort
#
# tasks list --sort due  — sort by due date.
# Tasks with no due date should sort to the end.
# Within each, sort by id.
#
# Hint: sort_by with a composite key. nil due dates can be turned into a
# sentinel like Date.new(9999, 12, 31), or you can use a [no_due_flag, due]
# pair where no_due_flag is 0 if due exists else 1.
