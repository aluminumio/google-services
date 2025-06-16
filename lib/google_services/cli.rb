require 'thor'
require 'tty-prompt'
require 'tty-table'
require 'json'
require 'yaml'

module GoogleServices
  class CLI < Thor
    class_option :config, type: :string, default: "~/.google-services.yml",
                 desc: "Path to config file"

    desc "login", "Authenticate with Google OAuth"
    def login
      prompt = TTY::Prompt.new
      
      client_id = prompt.ask("Enter Google Client ID:") do |q|
        q.required true
      end
      
      client_secret = prompt.mask("Enter Google Client Secret:") do |q|
        q.required true
      end
      
      # Save to config
      config = load_config
      config['client_id'] = client_id
      config['client_secret'] = client_secret
      save_config(config)
      
      say "Configuration saved!", :green
      say "\nTo complete authentication, you'll need to implement OAuth flow in your application."
      say "Visit: https://console.cloud.google.com/apis/credentials"
    end

    desc "calendar SUBCOMMAND", "Manage Google Calendar"
    subcommand "calendar", Calendar

    desc "docs SUBCOMMAND", "Manage Google Docs"
    subcommand "docs", Docs

    desc "meet SUBCOMMAND", "Manage Google Meet"
    subcommand "meet", Meet

    private

    def load_config
      path = File.expand_path(options[:config])
      return {} unless File.exist?(path)
      YAML.load_file(path) || {}
    rescue => e
      say "Error loading config: #{e.message}", :red
      {}
    end

    def save_config(config)
      path = File.expand_path(options[:config])
      File.write(path, config.to_yaml)
    end

    def ensure_auth
      config = load_config
      unless config['client_id'] && config['client_secret']
        say "Please run 'google-services login' first", :red
        exit 1
      end
      config
    end

    def mock_user(config)
      # In a real implementation, this would load user tokens
      # For CLI demo, we'll create a mock user object
      Struct.new(:google_token, :google_refresh_token, :google_token_expires_at).new(
        "mock_token",
        "mock_refresh_token",
        Time.now + 3600
      )
    end

    class Calendar < Thor
      desc "list", "List calendar events"
      option :date, type: :string, desc: "Date to list events for (YYYY-MM-DD)"
      def list
        config = parent_command.ensure_auth
        user = parent_command.mock_user(config)
        
        GoogleServices.configure do |c|
          c.client_id = config['client_id']
          c.client_secret = config['client_secret']
        end
        
        calendar = GoogleServices.calendar(user)
        date = options[:date] ? Date.parse(options[:date]) : Date.today
        
        say "Note: This is a mock response. Real implementation requires OAuth tokens.", :yellow
        say "\nEvents for #{date}:"
        
        # Mock response
        table = TTY::Table.new(
          header: ['Time', 'Title', 'Location'],
          rows: [
            ['09:00', 'Team Standup', 'Conference Room A'],
            ['14:00', 'Client Meeting', 'https://meet.google.com/abc-defg-hij']
          ]
        )
        puts table.render(:unicode)
      end

      desc "create TITLE", "Create a calendar event"
      option :time, type: :string, required: true, desc: "Start time (HH:MM)"
      option :duration, type: :numeric, default: 60, desc: "Duration in minutes"
      option :location, type: :string, desc: "Event location"
      def create(title)
        config = parent_command.ensure_auth
        prompt = TTY::Prompt.new
        
        # Parse time
        time_parts = options[:time].split(':')
        start_time = Time.now.change(hour: time_parts[0].to_i, min: time_parts[1].to_i)
        
        say "Creating event:", :green
        say "  Title: #{title}"
        say "  Time: #{start_time.strftime('%Y-%m-%d %H:%M')}"
        say "  Duration: #{options[:duration]} minutes"
        say "  Location: #{options[:location]}" if options[:location]
        
        if prompt.yes?("\nCreate this event?")
          say "\nNote: This is a mock response. Real implementation requires OAuth tokens.", :yellow
          say "Event created successfully!", :green
          say "URL: https://calendar.google.com/event?eid=mock123"
        end
      end

      private

      def parent_command
        @_parent_command ||= GoogleServices::CLI.new
      end
    end

    class Docs < Thor
      desc "list", "List documents"
      option :folder, type: :string, desc: "Folder to list documents from"
      def list
        config = parent_command.ensure_auth
        
        say "Note: This is a mock response. Real implementation requires OAuth tokens.", :yellow
        say "\nDocuments:"
        
        table = TTY::Table.new(
          header: ['Title', 'Modified', 'ID'],
          rows: [
            ['Project Proposal', '2024-01-15', 'doc123'],
            ['Meeting Notes', '2024-01-14', 'doc456']
          ]
        )
        puts table.render(:unicode)
      end

      desc "create TITLE", "Create a new document"
      option :content, type: :string, desc: "Initial content"
      option :folder, type: :string, desc: "Folder to create in"
      def create(title)
        config = parent_command.ensure_auth
        
        say "Creating document:", :green
        say "  Title: #{title}"
        say "  Folder: #{options[:folder] || 'My Drive'}"
        
        say "\nNote: This is a mock response. Real implementation requires OAuth tokens.", :yellow
        say "Document created successfully!", :green
        say "URL: https://docs.google.com/document/d/mock123/edit"
      end

      private

      def parent_command
        @_parent_command ||= GoogleServices::CLI.new
      end
    end

    class Meet < Thor
      desc "create TITLE", "Create a meeting"
      option :duration, type: :numeric, default: 60, desc: "Duration in minutes"
      def create(title)
        config = parent_command.ensure_auth
        
        say "Creating meeting:", :green
        say "  Title: #{title}"
        say "  Duration: #{options[:duration]} minutes"
        
        say "\nNote: This is a mock response. Real implementation requires OAuth tokens.", :yellow
        say "Meeting created successfully!", :green
        say "URL: https://meet.google.com/abc-defg-hij"
      end

      private

      def parent_command
        @_parent_command ||= GoogleServices::CLI.new
      end
    end
  end
end 