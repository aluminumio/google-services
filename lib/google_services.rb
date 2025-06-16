require "google_services/version"
require "google_services/configuration"
require "google_services/errors"
require "google_services/base"
require "google_services/calendar"
require "google_services/docs"
require "google_services/meet"
require "google_services/value_objects"

# Only load CLI if Thor is available
begin
  require "google_services/cli"
rescue LoadError
  # CLI not available
end

module GoogleServices
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def calendar(credentials, calendar_id: 'primary')
      Calendar.new(credentials, calendar_id: calendar_id)
    end

    def docs(credentials)
      Docs.new(credentials)
    end

    def meet(credentials)
      Meet.new(credentials)
    end
  end
end 