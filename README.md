# GoogleServices

Simple Ruby interface for Google Calendar, Docs, and Meet APIs..

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

### Using .env Files

For development, you can use a `.env` file to store your Google credentials:

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Add your Google OAuth credentials to `.env`:
   ```
   GOOGLE_CLIENT_ID=your_actual_client_id
   GOOGLE_CLIENT_SECRET=your_actual_client_secret
   ```

3. The gem will automatically load these environment variables and display a warning when they're being used.

**⚠️ WARNING:** Never commit your `.env` file to version control! It's already included in `.gitignore`.

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

# Folders
folders = docs.list_folders
contents = docs.list_folder_contents("Work Documents")
folder = docs.create_folder("New Project")
folder = docs.create_folder("Subproject", parent_folder: "Projects")
docs.delete_folder("Old Project")
docs.delete_folder("Old Project", force: true)
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

The CLI tool provides a convenient way to interact with Google services from the command line.

### Authentication

Before using any commands, you must authenticate with Google:

```bash
# Authenticate with Google OAuth
google-services login
```

This will:
1. Prompt for your Google Client ID and Secret (or use them from `.env`)
2. Open a browser for Google OAuth authentication
3. Save your access and refresh tokens for future use

**Important:** Make sure to add `http://localhost:3000/users/auth/google_oauth2/callback` to your OAuth 2.0 redirect URIs in the Google Cloud Console.

### Commands

```bash
# Calendar commands
google-services calendar list                          # List today's events
google-services calendar list --date 2024-01-20       # List events for specific date
google-services calendar create "Meeting" --time 14:00 --duration 60
google-services calendar create "Meeting" --time 14:00 -y  # Skip confirmation with -y or --yes

# Docs commands
google-services docs list                              # List all documents
google-services docs list --folder "Work"              # List documents in folder
google-services docs create "New Document" --content "Initial content"
google-services docs create "Report" --folder "Work"   # Create in specific folder

# Folder commands
google-services docs folders                           # List all folders
google-services docs folders --parent "Projects"       # List folders in parent
google-services docs folder "Work Documents"           # List folder contents
google-services docs create-folder "New Project"       # Create a folder
google-services docs create-folder "v2" --parent "Projects"  # Create in parent
google-services docs delete-folder "Old Project"       # Delete empty folder
google-services docs delete-folder "Old Project" -f    # Force delete with contents

# Meet commands
google-services meet create "Quick Call" --duration 30 # Create a meeting
```

### Non-Interactive Mode

For automation and scripts, use the `-y` or `--yes` flag to skip confirmation prompts:

```bash
google-services calendar create "Daily Standup" --time 09:00 --duration 15 -y
```

### Troubleshooting

If you encounter authentication errors:
- Ensure your OAuth credentials are valid
- Check that `http://localhost:3000/users/auth/google_oauth2/callback` is in your redirect URIs
- Run `google-services login` again to refresh your authentication

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

Bug reports and pull requests are welcome on GitHub at https://github.com/aluminumio/google-services.
