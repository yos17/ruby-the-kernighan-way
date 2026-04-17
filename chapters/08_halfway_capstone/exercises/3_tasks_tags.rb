# Exercise 3 — tags
#
# Add an optional --tag flag (repeatable) to `add`:
#   tasks add "deploy" --tag work --tag urgent
#
# Store as an array on each Task.
# Add `tasks list --tag work` to filter.
#
# Considerations:
#   - Task = Data.define(:id, :text, :due, :done, :tags) — add the tags slot
#   - Default tags to [] when missing in stored JSON
#   - parse_add_args needs to extract repeated --tag values
