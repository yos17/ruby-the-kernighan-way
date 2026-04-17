# Exercise 3 — Add a CLI to your gem

Make your gem usable from the command line.

## Steps

1. Create `exe/yourtool` (executable script). The `exe/` directory (not `bin/`) is the convention for user-facing executables in modern gems.

   ```ruby
   #!/usr/bin/env ruby
   # exe/yourtool
   require "yourtool"
   Yourtool::CLI.new.run(ARGV)
   ```

2. Make it executable: `chmod +x exe/yourtool`.

3. Add to gemspec:
   ```ruby
   spec.bindir       = "exe"
   spec.executables  = ["yourtool"]
   ```

4. Move your CLI code into `lib/yourtool/cli.rb`.

5. Build, install, run:
   ```bash
   gem build yourtool.gemspec
   gem install ./yourtool-0.1.0.gem
   yourtool --help
   ```

After installing, `yourtool` is on the user's $PATH automatically.
