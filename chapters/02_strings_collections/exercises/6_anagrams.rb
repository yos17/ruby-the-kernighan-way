# Exercise 6 — anagrams.rb
#
# Read a word list (one word per line). Print groups of anagrams.
# Example file:
#   listen
#   silent
#   enlist
#   tinsel
#   hello
#   world
# Output:
#   listen, silent, enlist, tinsel
#   hello
#   world
#
# Words are anagrams if they have the same letters. Hint:
#   "listen".chars.sort.join == "silent".chars.sort.join  # => true ("eilnst")
#   arr.group_by { |x| ... } returns a hash where the block's return value is the key.

filename = ARGV[0]

# TODO: read words from filename
# TODO: group_by their sorted-letters fingerprint
# TODO: for each group, print the words joined by ", "
