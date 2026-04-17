# Exercise 6 — Counter app on tiny_framework
#
# Routes:
#   GET  /            shows the counter as a page with two forms
#   POST /increment   adds 1 to the counter, redirects (or just returns) the page
#   POST /reset       zeros the counter
#
# Persistence: store the counter in a file (counter.txt) so it survives restarts.
#
# Hints:
#   - `<form method="POST" action="/increment"><button type="submit">+1</button></form>`
#   - To redirect after POST, return [302, { "Location" => "/" }, []]
#     (Or just return the same HTML you'd return on GET / — simpler.)
#
# Bonus: track per-user counts using a cookie. (Hint: HTTP_COOKIE in env.)

# TODO: build the app
