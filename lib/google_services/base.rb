require 'oauth2'
require 'googleauth'

module GoogleServices
  class Base
    attr_reader :credentials

    def initialize(credentials)
      @credentials = normalize_credentials(credentials)
      validate_credentials!
    end

    private

    def configuration
      GoogleServices.configuration
    end

    def oauth_client
      @oauth_client ||= OAuth2::Client.new(
        configuration.client_id || ENV['GOOGLE_CLIENT_ID'],
        configuration.client_secret || ENV['GOOGLE_CLIENT_SECRET'],
        site: 'https://accounts.google.com',
        authorize_url: '/o/oauth2/auth',
        token_url: '/o/oauth2/token'
      )
    end

    def authorize_services(*services, scopes:)
      return unless credentials[:google_token]
      
      creds = user_credentials(scopes: scopes)
      
      services.each do |service|
        service.authorization = creds
      end
    end

    def user_credentials(scopes: [])
      validate_refresh_token!
      
      access_token = build_access_token
      access_token = refresh_token_if_needed(access_token)
      
      Google::Auth::UserRefreshCredentials.new(
        client_id: configuration.client_id || ENV['GOOGLE_CLIENT_ID'],
        client_secret: configuration.client_secret || ENV['GOOGLE_CLIENT_SECRET'],
        refresh_token: credentials[:google_refresh_token],
        access_token: access_token.token,
        expires_at: access_token.expires_at,
        scope: scopes
      )
    end

    def validate_refresh_token!
      unless credentials[:google_refresh_token]
        raise MissingTokenError, "Missing Google refresh token. Please re-authenticate with Google."
      end
    end

    def build_access_token
      OAuth2::AccessToken.new(
        oauth_client,
        credentials[:google_token],
        refresh_token: credentials[:google_refresh_token],
        expires_at: credentials[:google_token_expires_at].to_i
      )
    end

    def refresh_token_if_needed(access_token)
      return access_token unless token_expired_or_expiring?(access_token)
      
      refresh_token!(access_token)
    rescue OAuth2::Error => e
      raise TokenExpiredError, "Your Google authorization has expired. Please sign in again. (#{e.message})"
    end

    def token_expired_or_expiring?(access_token)
      access_token.expired? || 
      (access_token.expires_at && access_token.expires_at < Time.now.to_i + configuration.token_expiry_buffer)
    end

    def refresh_token!(access_token)
      refreshed_token = access_token.refresh!
      
      # Update credentials if it's an object that responds to setters
      if @original_credentials.respond_to?(:google_token=)
        @original_credentials.google_token = refreshed_token.token
        @original_credentials.google_refresh_token = refreshed_token.refresh_token if @original_credentials.respond_to?(:google_refresh_token=)
        @original_credentials.google_token_expires_at = Time.at(refreshed_token.expires_at) if @original_credentials.respond_to?(:google_token_expires_at=)
      end
      
      # Update our internal credentials hash
      @credentials[:google_token] = refreshed_token.token
      @credentials[:google_refresh_token] = refreshed_token.refresh_token
      @credentials[:google_token_expires_at] = Time.at(refreshed_token.expires_at)
      
      refreshed_token
    end

    def with_error_handling
      yield
    rescue Google::Apis::AuthorizationError => e
      raise AuthorizationError, e.message
    rescue Google::Apis::ClientError => e
      case e.status_code
      when 404
        raise NotFoundError, e.message
      when 429
        raise QuotaExceededError, e.message
      else
        raise ApiError, "#{e.status_code}: #{e.message}"
      end
    rescue => e
      raise Error, e.message
    end

    def normalize_credentials(creds)
      @original_credentials = creds
      
      case creds
      when Hash
        {
          google_token: creds[:google_token] || creds['google_token'],
          google_refresh_token: creds[:google_refresh_token] || creds['google_refresh_token'],
          google_token_expires_at: parse_expires_at(creds[:google_token_expires_at] || creds['google_token_expires_at'])
        }
      else
        # Assume it's an object that responds to the required methods
        {
          google_token: creds.google_token,
          google_refresh_token: creds.google_refresh_token,
          google_token_expires_at: parse_expires_at(creds.google_token_expires_at)
        }
      end
    end

    def parse_expires_at(value)
      case value
      when Time
        value
      when Integer, Float
        Time.at(value)
      when String
        Time.parse(value)
      else
        value
      end
    end

    def validate_credentials!
      required = [:google_token, :google_refresh_token, :google_token_expires_at]
      missing = required.select { |key| credentials[key].nil? }
      
      unless missing.empty?
        raise ConfigurationError, "Credentials must include: #{missing.join(', ')}"
      end
    end
  end
end 