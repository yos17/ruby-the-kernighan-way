# Exercise 5 — Welcome email on signup

```bash
bin/rails generate mailer Welcome greet
```

`app/mailers/welcome_mailer.rb`:

```ruby
class WelcomeMailer < ApplicationMailer
  def greet(user)
    @user = user
    mail(to: user.email_address, subject: "Welcome to the blog!")
  end
end
```

`app/views/welcome_mailer/greet.html.erb`:

```erb
<h1>Welcome, <%= @user.email_address %>!</h1>
<p>Thanks for signing up. Your blog journey starts now.</p>
```

`app/views/welcome_mailer/greet.text.erb`:

```
Welcome, <%= @user.email_address %>!

Thanks for signing up. Your blog journey starts now.
```

Hook it in. Find where the auth generator creates a User on signup (look in `RegistrationsController` or `UsersController`), and add:

```ruby
WelcomeMailer.greet(@user).deliver_later
```

`deliver_later` queues a `ActionMailer::MailDeliveryJob` via Solid Queue. The HTTP request returns immediately; the email sends in the background.

In development, install `letter_opener` to view emails in a browser tab:

```ruby
# Gemfile
group :development do
  gem "letter_opener"
end
```

```ruby
# config/environments/development.rb
config.action_mailer.delivery_method = :letter_opener
```
