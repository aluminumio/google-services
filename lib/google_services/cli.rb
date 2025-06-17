require 'thor'
require 'tty-prompt'
require 'tty-table'
require 'json'
require 'yaml'
require 'dotenv/load'
require 'webrick'
require 'launchy'

module GoogleServices
  class CalendarCLI < Thor
    desc "list", "List calendar events"
    option :date, type: :string, desc: "Date to list events for (YYYY-MM-DD)"
    def list
      config = parent_command.ensure_auth
      user = parent_command.get_authenticated_user(config)
      
      GoogleServices.configure do |c|
        c.client_id = config['client_id']
        c.client_secret = config['client_secret']
      end
      
      begin
        calendar = GoogleServices.calendar(user)
        date = options[:date] ? Date.parse(options[:date]) : Date.today
        
        say "\nFetching events for #{date}...", :yellow
        events = calendar.list_events(date: date)
        
        if events.empty?
          say "\nNo events found for #{date}", :yellow
        else
          say "\nEvents for #{date}:"
          
          rows = events.map do |event|
            start_time = event.start_time&.strftime('%H:%M') || 'All day'
            [start_time, event.title, event.location || '-']
          end
          
          table = TTY::Table.new(
            header: ['Time', 'Title', 'Location'],
            rows: rows
          )
          puts table.render(:unicode)
        end
      rescue => e
        say "\n❌ Failed to fetch events: #{e.message}", :red
        if e.message.include?('401') || e.message.include?('expired')
          say "Your authentication may have expired. Please run 'google-services login' again.", :yellow
        end
      end
    end

    desc "create TITLE", "Create a calendar event"
    option :time, type: :string, required: true, desc: "Start time (HH:MM)"
    option :duration, type: :numeric, default: 60, desc: "Duration in minutes"
    option :location, type: :string, desc: "Event location"
    option :yes, type: :boolean, aliases: '-y', desc: "Skip confirmation prompt"
    def create(title)
      config = parent_command.ensure_auth
      prompt = TTY::Prompt.new
      
      # Get authenticated user
      user = parent_command.get_authenticated_user(config)
      
      GoogleServices.configure do |c|
        c.client_id = config['client_id']
        c.client_secret = config['client_secret']
      end
      
      # Parse time
      time_parts = options[:time].split(':')
      start_time = Time.now.change(hour: time_parts[0].to_i, min: time_parts[1].to_i)
      
      say "Creating event:", :green
      say "  Title: #{title}"
      say "  Time: #{start_time.strftime('%Y-%m-%d %H:%M')}"
      say "  Duration: #{options[:duration]} minutes"
      say "  Location: #{options[:location]}" if options[:location]
      
      # Skip confirmation if --yes flag is provided
      create_event = options[:yes] || prompt.yes?("\nCreate this event?")
      
      if create_event
        begin
          calendar = GoogleServices.calendar(user)
          event = calendar.create_event(
            title: title,
            start_time: start_time,
            duration: options[:duration],
            location: options[:location]
          )
          say "\n✅ Event created successfully!", :green
          say "URL: #{event.url}"
        rescue => e
          say "\n❌ Failed to create event: #{e.message}", :red
        end
      else
        say "\nEvent creation cancelled.", :yellow
      end
    end

    private

    def parent_command
      @_parent_command ||= GoogleServices::CLI.new
    end
  end

  class DocsCLI < Thor
    desc "list", "List documents"
    option :folder, type: :string, desc: "Folder to list documents from"
    def list
      config = parent_command.ensure_auth
      user = parent_command.get_authenticated_user(config)
      
      GoogleServices.configure do |c|
        c.client_id = config['client_id']
        c.client_secret = config['client_secret']
      end
      
      begin
        docs = GoogleServices.docs(user)
        say "\nFetching documents...", :yellow
        documents = docs.list(folder: options[:folder])
        
        if documents.empty?
          say "\nNo documents found", :yellow
        else
          say "\nDocuments:"
          
          rows = documents.map do |doc|
            [doc.title, doc.modified_at.strftime('%Y-%m-%d'), doc.id]
          end
          
          table = TTY::Table.new(
            header: ['Title', 'Modified', 'ID'],
            rows: rows
          )
          puts table.render(:unicode)
        end
      rescue => e
        say "\n❌ Failed to fetch documents: #{e.message}", :red
      end
    end

    desc "folders", "List all folders"
    option :parent, type: :string, desc: "Parent folder to list folders from"
    def folders
      config = parent_command.ensure_auth
      user = parent_command.get_authenticated_user(config)
      
      GoogleServices.configure do |c|
        c.client_id = config['client_id']
        c.client_secret = config['client_secret']
      end
      
      begin
        docs = GoogleServices.docs(user)
        say "\nFetching folders...", :yellow
        folders = docs.list_folders(parent_folder: options[:parent])
        
        if folders.empty?
          say "\nNo folders found", :yellow
        else
          say "\nFolders:"
          
          rows = folders.map do |folder|
            [folder.name, folder.modified_at.strftime('%Y-%m-%d'), folder.id]
          end
          
          table = TTY::Table.new(
            header: ['Name', 'Modified', 'ID'],
            rows: rows
          )
          puts table.render(:unicode)
        end
      rescue => e
        say "\n❌ Failed to fetch folders: #{e.message}", :red
      end
    end

    desc "folder FOLDER_NAME", "List contents of a specific folder"
    def folder(folder_name)
      config = parent_command.ensure_auth
      user = parent_command.get_authenticated_user(config)
      
      GoogleServices.configure do |c|
        c.client_id = config['client_id']
        c.client_secret = config['client_secret']
      end
      
      begin
        docs = GoogleServices.docs(user)
        say "\nFetching contents of '#{folder_name}'...", :yellow
        contents = docs.list_folder_contents(folder_name)
        
        if contents.empty?
          say "\nFolder '#{folder_name}' is empty", :yellow
        else
          say "\nContents of '#{folder_name}':"
          
          # Separate folders and documents
          folders = contents.select { |item| item.is_a?(GoogleServices::Folder) }
          documents = contents.select { |item| item.is_a?(GoogleServices::Document) }
          
          # Display folders first
          unless folders.empty?
            say "\n📁 Folders:", :cyan
            folder_rows = folders.map do |folder|
              ["📁 #{folder.name}", folder.modified_at.strftime('%Y-%m-%d')]
            end
            
            folder_table = TTY::Table.new(
              header: ['Name', 'Modified'],
              rows: folder_rows
            )
            puts folder_table.render(:unicode)
          end
          
          # Display documents
          unless documents.empty?
            say "\n📄 Documents:", :cyan
            doc_rows = documents.map do |doc|
              ["📄 #{doc.title}", doc.modified_at.strftime('%Y-%m-%d')]
            end
            
            doc_table = TTY::Table.new(
              header: ['Name', 'Modified'],
              rows: doc_rows
            )
            puts doc_table.render(:unicode)
          end
        end
      rescue => e
        say "\n❌ Failed to fetch folder contents: #{e.message}", :red
      end
    end

    desc "create-folder FOLDER_NAME", "Create a new folder"
    option :parent, type: :string, desc: "Parent folder to create in"
    def create_folder(folder_name)
      config = parent_command.ensure_auth
      user = parent_command.get_authenticated_user(config)
      
      GoogleServices.configure do |c|
        c.client_id = config['client_id']
        c.client_secret = config['client_secret']
      end
      
      say "Creating folder:", :green
      say "  Name: #{folder_name}"
      say "  Parent: #{options[:parent] || 'My Drive'}"
      
      begin
        docs = GoogleServices.docs(user)
        folder = docs.create_folder(folder_name, parent_folder: options[:parent])
        say "\n✅ Folder created successfully!", :green
        say "URL: #{folder.url}"
      rescue => e
        say "\n❌ Failed to create folder: #{e.message}", :red
      end
    end

    desc "delete-folder FOLDER_NAME", "Delete a folder"
    option :force, type: :boolean, aliases: '-f', desc: "Force delete even if folder has contents"
    def delete_folder(folder_name)
      config = parent_command.ensure_auth
      user = parent_command.get_authenticated_user(config)
      prompt = TTY::Prompt.new
      
      GoogleServices.configure do |c|
        c.client_id = config['client_id']
        c.client_secret = config['client_secret']
      end
      
      # Confirm deletion
      message = options[:force] ? 
        "Delete folder '#{folder_name}' and ALL its contents?" : 
        "Delete folder '#{folder_name}'?"
      
      if prompt.yes?(message, default: false)
        begin
          docs = GoogleServices.docs(user)
          docs.delete_folder(folder_name, force: options[:force])
          say "\n✅ Folder '#{folder_name}' deleted successfully!", :green
        rescue => e
          say "\n❌ Failed to delete folder: #{e.message}", :red
          if e.message.include?("not empty")
            say "Use --force or -f flag to delete non-empty folders", :yellow
          end
        end
      else
        say "\nFolder deletion cancelled.", :yellow
      end
    end

    desc "create TITLE", "Create a new document"
    option :content, type: :string, desc: "Initial content"
    option :folder, type: :string, desc: "Folder to create in"
    def create(title)
      config = parent_command.ensure_auth
      user = parent_command.get_authenticated_user(config)
      
      GoogleServices.configure do |c|
        c.client_id = config['client_id']
        c.client_secret = config['client_secret']
      end
      
      say "Creating document:", :green
      say "  Title: #{title}"
      say "  Folder: #{options[:folder] || 'My Drive'}"
      
      begin
        docs = GoogleServices.docs(user)
        doc = docs.create(title, content: options[:content], folder: options[:folder])
        say "\n✅ Document created successfully!", :green
        say "URL: https://docs.google.com/document/d/#{doc.id}/edit"
      rescue => e
        say "\n❌ Failed to create document: #{e.message}", :red
      end
    end

    private

    def parent_command
      @_parent_command ||= GoogleServices::CLI.new
    end
  end

  class MeetCLI < Thor
    desc "create TITLE", "Create a meeting"
    option :duration, type: :numeric, default: 60, desc: "Duration in minutes"
    def create(title)
      config = parent_command.ensure_auth
      user = parent_command.get_authenticated_user(config)
      
      GoogleServices.configure do |c|
        c.client_id = config['client_id']
        c.client_secret = config['client_secret']
      end
      
      say "Creating meeting:", :green
      say "  Title: #{title}"
      say "  Duration: #{options[:duration]} minutes"
      
      begin
        meet = GoogleServices.meet(user)
        meeting = meet.create(title, duration: options[:duration])
        say "\n✅ Meeting created successfully!", :green
        say "URL: #{meeting.url}"
      rescue => e
        say "\n❌ Failed to create meeting: #{e.message}", :red
      end
    end

    private

    def parent_command
      @_parent_command ||= GoogleServices::CLI.new
    end
  end

  class CLI < Thor
    class_option :config, type: :string, default: "~/.google-services.yml",
                 desc: "Path to config file"

    desc "login", "Authenticate with Google OAuth"
    def login
      prompt = TTY::Prompt.new
      
      # Check if credentials exist in .env
      env_client_id = ENV['GOOGLE_CLIENT_ID']
      env_client_secret = ENV['GOOGLE_CLIENT_SECRET']
      
      if env_client_id && env_client_secret
        say "\n📋 Found credentials in .env file:", :green
        say "   Client ID: #{env_client_id[0..20]}..." if env_client_id.length > 20
        say "   Client ID: #{env_client_id}" if env_client_id.length <= 20
        say ""
        
        use_env = prompt.yes?("Use these credentials from .env?")
        client_id = env_client_id if use_env
        client_secret = env_client_secret if use_env
      end
      
      unless client_id && client_secret
        client_id = prompt.ask("Enter Google Client ID:") do |q|
          q.required true
          q.default env_client_id if env_client_id
        end
        
        client_secret = prompt.mask("Enter Google Client Secret:") do |q|
          q.required true
        end
      end
      
      say "\n🔐 Starting OAuth authentication...", :yellow
      
      # Configure Google Services
      GoogleServices.configure do |c|
        c.client_id = client_id
        c.client_secret = client_secret
      end
      
      # Perform OAuth flow
      begin
        tokens = perform_oauth_flow(client_id, client_secret)
        
        # Save credentials and tokens
        config = load_config
        config['client_id'] = client_id
        config['client_secret'] = client_secret
        config['google_token'] = tokens[:access_token]
        config['google_refresh_token'] = tokens[:refresh_token]
        config['google_token_expires_at'] = tokens[:expires_at].to_s
        save_config(config)
        
        say "\n✅ Authentication successful!", :green
        say "Your tokens have been saved to #{File.expand_path(options[:config])}"
        say "\nYou can now use all google-services commands!"
        
      rescue => e
        say "\n❌ Authentication failed: #{e.message}", :red
        say "\nPlease check your credentials and try again."
        say "Make sure to add http://localhost:3000/users/auth/google_oauth2/callback to your OAuth redirect URIs"
      end
    end

    desc "calendar SUBCOMMAND", "Manage Google Calendar"
    subcommand "calendar", CalendarCLI

    desc "docs SUBCOMMAND", "Manage Google Docs"
    subcommand "docs", DocsCLI

    desc "meet SUBCOMMAND", "Manage Google Meet"
    subcommand "meet", MeetCLI

    no_commands do
      def ensure_auth
        config = load_config
        
        # Check for credentials in config file or environment
        client_id = config['client_id'] || ENV['GOOGLE_CLIENT_ID']
        client_secret = config['client_secret'] || ENV['GOOGLE_CLIENT_SECRET']
        
        unless client_id && client_secret
          say "Please run 'google-services login' first or set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in your .env file", :red
          exit 1
        end
        
        # Check for valid tokens
        unless config['google_token'] && config['google_refresh_token'] && config['google_token_expires_at']
          say "\n❌ No authentication tokens found.", :red
          say "Please run 'google-services login' to authenticate with Google.", :yellow
          exit 1
        end
        
        # Warn if using environment variables
        if !config['client_id'] && ENV['GOOGLE_CLIENT_ID']
          say "⚠️  WARNING: Using GOOGLE_CLIENT_ID from environment", :yellow
        end
        if !config['client_secret'] && ENV['GOOGLE_CLIENT_SECRET']
          say "⚠️  WARNING: Using GOOGLE_CLIENT_SECRET from environment", :yellow
        end
        
        config['client_id'] ||= client_id
        config['client_secret'] ||= client_secret
        config
      end

      def get_authenticated_user(config)
        # Require real tokens
        unless config['google_token'] && config['google_refresh_token'] && config['google_token_expires_at']
          say "\n❌ Authentication required.", :red
          say "Please run 'google-services login' to authenticate with Google.", :yellow
          exit 1
        end
        
        Struct.new(:google_token, :google_refresh_token, :google_token_expires_at).new(
          config['google_token'],
          config['google_refresh_token'],
          Time.parse(config['google_token_expires_at'])
        )
      end
    end

    private

    def perform_oauth_flow(client_id, client_secret)
      require 'oauth2'
      
      # Create OAuth client
      client = OAuth2::Client.new(
        client_id,
        client_secret,
        site: 'https://accounts.google.com',
        authorize_url: '/o/oauth2/auth',
        token_url: '/o/oauth2/token'
      )
      
      # Define callback URL
      callback_url = 'http://localhost:3000/users/auth/google_oauth2/callback'
      
      say "\n📍 Using OAuth callback URL: #{callback_url}", :cyan
      say "   Make sure this is registered in your Google OAuth settings!", :yellow
      
      # Generate authorization URL with required scopes
      auth_url = client.auth_code.authorize_url(
        redirect_uri: callback_url,
        scope: [
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/documents',
          'https://www.googleapis.com/auth/drive'
        ].join(' '),
        access_type: 'offline',
        prompt: 'consent'
      )
      
      say "\n🌐 Opening browser for authentication..."
      say "If the browser doesn't open automatically, visit:"
      say auth_url, :cyan
      
      # Start local server to receive callback
      authorization_code = nil
      server = WEBrick::HTTPServer.new(Port: 3000, Logger: WEBrick::Log.new(nil, 0), AccessLog: [])
      
      server.mount_proc '/users/auth/google_oauth2/callback' do |req, res|
        authorization_code = req.query['code']
        if authorization_code
          res.body = <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <meta charset="UTF-8">
                <title>Authentication Successful</title>
              </head>
              <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
                <h1 style="color: #28a745;">✅ Authentication Successful!</h1>
                <p>You can close this window and return to your terminal.</p>
              </body>
            </html>
          HTML
          res.status = 200
          res['Content-Type'] = 'text/html; charset=UTF-8'
        else
          error = req.query['error'] || 'Unknown error'
          res.body = <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
                <meta charset="UTF-8">
                <title>Authentication Failed</title>
              </head>
              <body style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
                <h1 style="color: #dc3545;">❌ Authentication Failed</h1>
                <p>Error: #{error}</p>
                <p>Please try again.</p>
              </body>
            </html>
          HTML
          res.status = 400
          res['Content-Type'] = 'text/html; charset=UTF-8'
        end
        server.shutdown
      end
      
      # Open browser
      Thread.new { Launchy.open(auth_url) rescue nil }
      
      # Wait for callback
      say "\n⏳ Waiting for authentication...", :yellow
      server.start
      
      raise "No authorization code received" unless authorization_code
      
      # Exchange code for tokens
      token = client.auth_code.get_token(
        authorization_code,
        redirect_uri: callback_url
      )
      
      {
        access_token: token.token,
        refresh_token: token.refresh_token,
        expires_at: Time.at(token.expires_at)
      }
    end

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
  end
end 