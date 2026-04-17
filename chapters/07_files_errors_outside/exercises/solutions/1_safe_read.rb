# Solution to Exercise 1
def safe_read(path)
  File.read(path)
rescue Errno::ENOENT
  warn "no such file: #{path}"
  ""
rescue Errno::EACCES
  warn "permission denied: #{path}"
  ""
end

if __FILE__ == $PROGRAM_NAME
  puts safe_read("README.md").length    # works
  puts safe_read("/nonexistent").length # 0, with warning
end
