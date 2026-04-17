# Exercise 2 — tasks rm ID
#
# Add a `rm` command that deletes a task by id.
#
# 1. Add :rm to COMMANDS
# 2. Add a TaskStore#delete(id) method
# 3. Add a CLI#rm method
#
# Decide: should ids be re-used after delete? (Probably not — keep them
# stable so users can refer back to them in old terminal scrollback.)
