# Exercise 4 — tiny_processor.rb with multiple files
#
# Accept multiple filenames. Print one line per file with its individual
# counts, then a total line.
# Example:
#   ruby exercises/4_processor_multiple_files.rb a.txt b.txt
#   #=> a.txt: 3 lines, 6 words, 34 characters
#   #=> b.txt: 5 lines, 12 words, 80 characters
#   #=> total: 8 lines, 18 words, 114 characters
#
# Hint: ARGV.each do |filename| ... end. Track running totals outside the loop.

# TODO: initialize total_lines, total_words, total_chars
# TODO: ARGV.each do |filename| ... per-file counts ... add to totals ... end
# TODO: print the total line at the end
