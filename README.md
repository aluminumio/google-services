# GoogleServices

Simple Ruby interface for Google Calendar, Docs, and Meet APIs.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'google-services'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install google-services

## Configuration

```ruby
GoogleServices.configure do |config|
  config.client_id = ENV['GOOGLE_CLIENT_ID']
  config.client_secret = ENV['GOOGLE_CLIENT_SECRET']
end
```

## Usage

### Credentials

The gem requires credentials that include:
- `google_token` - The current access token
- `google_refresh_token` - The refresh token for getting new access tokens
- `google_token_expires_at` - When the current token expires

You can pass credentials as either a Hash or an object that responds to these methods:

```ruby
# Using a hash
credentials = {
  google_token: "ya29...",
  google_refresh_token: "1//0g...",
  google_token_expires_at: Time.now + 3600
}

# Using an object (like a User model)
user = User.find(1)  # must respond to google_token, google_refresh_token, google_token_expires_at
```

### Calendar

```ruby
# Create an event
calendar = GoogleServices.calendar(credentials)
event = calendar.create_event(
  title: "Team Meeting",
  start_time: 1.hour.from_now,
  duration: 60,
  location: "Conference Room"
)

# List events
events = calendar.list_events(date: Date.today)

# Find an event
event = calendar.find_event("event_id")

# Update an event
calendar.update_event("event_id", title: "Updated Title")

# Delete an event
calendar.delete_event("event_id")

# Use a specific calendar
family_calendar = GoogleServices.calendar(credentials, calendar_id: "family@gmail.com")
```

### Docs

```ruby
# Create a document
docs = GoogleServices.docs(credentials)
doc = docs.create("Project Proposal", content: "# Overview\n\nProject details...")

# Find a document
doc = docs.find("document_id")

# Update document content
docs.update("document_id", "New content")

# List documents
documents = docs.list(folder: "Work")

# Delete a document
docs.delete("document_id")
```

### Meet

```ruby
# Create a meeting with calendar integration
meet = GoogleServices.meet(credentials)
meeting = meet.create("Team Standup", duration: 30)
puts meeting.url  # => "https://meet.google.com/..."

# Create a standalone meeting space
meeting = meet.create_space(access_type: 'OPEN')
```

## CLI

```bash
# Configure credentials
google-services login

# Calendar commands
google-services calendar list
google-services calendar create "Meeting" --time 14:00 --duration 60

# Docs commands
google-services docs list
google-services docs create "New Document"

# Meet commands
google-services meet create "Quick Call"
```

## Error Handling

```ruby
begin
  calendar.create_event(title: "Meeting", start_time: Time.now)
rescue GoogleServices::AuthorizationError => e
  # Handle auth errors - token expired or invalid
rescue GoogleServices::QuotaExceededError => e
  # Handle quota errors
rescue GoogleServices::ApiError => e
  # Handle other API errors
end
```

## Token Management

The gem automatically refreshes expired tokens and updates the credentials object if it supports setter methods:

```ruby
# If your object has setters, tokens will be auto-updated
class User < ApplicationRecord
  attr_accessor :google_token, :google_refresh_token, :google_token_expires_at
end

# The gem will call user.google_token = new_token after refresh
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/usiegj00/google-services.
