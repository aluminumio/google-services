# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-12-17

### Added
- Comprehensive folder operations for Google Drive/Docs
  - List all folders with `docs.list_folders()`
  - List folder contents with `docs.list_folder_contents(folder_name)`
  - Create folders with `docs.create_folder(name, parent_folder: nil)`
  - Delete folders with `docs.delete_folder(name, force: false)`
- CLI commands for folder management
  - `google-services docs folders` - List all folders
  - `google-services docs folder <name>` - List folder contents
  - `google-services docs create-folder <name>` - Create a folder
  - `google-services docs delete-folder <name>` - Delete a folder
- New `Folder` value object for folder operations
- Support for creating documents in specific folders
- OAuth authentication flow with local callback server
- Environment variable support with `.env` files
- Non-interactive mode with `-y`/`--yes` flag for automation
- ActiveSupport for date/time extensions

### Changed
- OAuth callback URL now uses port 3000 instead of 9292
- OAuth callback path changed to `/users/auth/google_oauth2/callback`
- CLI now requires real authentication (no more mock tokens)
- Improved error messages and UTF-8 support in OAuth success page
- **BREAKING**: Minimum Ruby version increased from 3.0 to 3.2 (required by zeitwerk dependency)

### Fixed
- Character encoding issues in OAuth callback HTML responses
- Date extension methods by adding ActiveSupport dependency
- Thor CLI subcommand organization

## [0.1.0] - 2024-12-15

### Added
- Initial release
- Google Calendar API integration
- Google Docs API integration
- Google Meet API integration
- Basic CLI tool
- Token refresh functionality 