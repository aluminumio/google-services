# frozen_string_literal: true

require_relative "lib/google_services/version"

Gem::Specification.new do |spec|
  spec.name = "google-services"
  spec.version = GoogleServices::VERSION
  spec.authors = ["Jonathan Siegel"]
  spec.email = ["<248302+usiegj00@users.noreply.github.com>"]

  spec.summary = "Simple Ruby interface for Google Calendar, Docs, and Meet APIs"
  spec.description = "A clean, simple API for integrating Google services into Ruby applications"
  spec.homepage = "https://github.com/aluminumio/google-services"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/aluminumio/google-services"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "bin"
  spec.executables = ["google-services"]
  spec.require_paths = ["lib"]

  # Google API dependencies
  spec.add_dependency "google-apis-calendar_v3", "~> 0.45"
  spec.add_dependency "google-apis-docs_v1", "~> 0.33"
  spec.add_dependency "google-apis-drive_v3", "~> 0.66"
  spec.add_dependency "google-apis-meet_v2", "~> 0.10"
  spec.add_dependency "googleauth", "~> 1.13"
  
  # OAuth
  spec.add_dependency "oauth2", "~> 2.0"
  
  # Environment variables
  spec.add_dependency "dotenv", "~> 3.0"
  
  # Date/Time extensions
  spec.add_dependency "activesupport", ">= 6.1"
  
  # CLI
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-table", "~> 0.12"
  spec.add_dependency "launchy", "~> 2.5"
  spec.add_dependency "webrick", "~> 1.8"
  
  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "pry", "~> 0.14"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
