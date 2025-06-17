require 'google/apis/calendar_v3'
require 'active_support/core_ext/date'
require 'active_support/core_ext/time'
require 'active_support/core_ext/numeric/time'

module GoogleServices
  class Calendar < Base
    API_SCOPES = [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events'
    ].freeze

    def initialize(credentials, calendar_id: nil)
      super(credentials)
      @calendar_id = calendar_id || configuration.default_calendar
      @service = Google::Apis::CalendarV3::CalendarService.new
    end

    def create_event(title:, start_time:, duration: 60, description: nil, 
                     location: nil, attendees: [], time_zone: nil, **options)
      with_error_handling do
        @service.authorization = user_credentials(scopes: API_SCOPES)
        
        # Calculate end time from duration (in minutes)
        end_time = options[:end_time] || (start_time + duration.minutes)

        event = Google::Apis::CalendarV3::Event.new(
          summary: title,
          description: description,
          location: location,
          start: {
            date_time: start_time.iso8601,
            time_zone: time_zone
          },
          end: {
            date_time: end_time.iso8601,
            time_zone: time_zone
          }
        )

        # Add attendees if provided
        unless attendees.empty?
          event.attendees = Array(attendees).map { |email| { email: email } }
        end

        # Add any additional options
        options.each do |key, value|
          event.send("#{key}=", value) if event.respond_to?("#{key}=")
        end

        result = @service.insert_event(@calendar_id, event)
        
        Event.new(
          id: result.id,
          title: result.summary,
          start_time: result.start.date_time,
          end_time: result.end.date_time,
          location: result.location,
          url: result.html_link,
          created_at: result.created
        )
      end
    end

    def list_events(date: Date.today, limit: 100, time_min: nil, time_max: nil)
      with_error_handling do
        @service.authorization = user_credentials(scopes: API_SCOPES)
        
        # Default to full day if specific times not provided
        time_min ||= date.beginning_of_day.iso8601
        time_max ||= date.end_of_day.iso8601

        result = @service.list_events(
          @calendar_id,
          max_results: limit,
          single_events: true,
          order_by: 'startTime',
          time_min: time_min,
          time_max: time_max
        )

        result.items.map do |item|
          Event.new(
            id: item.id,
            title: item.summary,
            start_time: item.start.date_time || item.start.date,
            end_time: item.end.date_time || item.end.date,
            location: item.location,
            url: item.html_link,
            description: item.description
          )
        end
      end
    end

    def find_event(event_id)
      with_error_handling do
        @service.authorization = user_credentials(scopes: API_SCOPES)
        
        result = @service.get_event(@calendar_id, event_id)
        
        Event.new(
          id: result.id,
          title: result.summary,
          start_time: result.start.date_time || result.start.date,
          end_time: result.end.date_time || result.end.date,
          location: result.location,
          url: result.html_link,
          description: result.description
        )
      end
    end

    def update_event(event_id, updates = {})
      with_error_handling do
        @service.authorization = user_credentials(scopes: API_SCOPES)
        
        # Get existing event
        event = @service.get_event(@calendar_id, event_id)
        
        # Apply updates
        updates.each do |key, value|
          case key
          when :title
            event.summary = value
          when :description
            event.description = value
          when :location
            event.location = value
          when :start_time
            event.start = { date_time: value.iso8601 }
          when :end_time
            event.end = { date_time: value.iso8601 }
          end
        end
        
        result = @service.update_event(@calendar_id, event_id, event)
        
        Event.new(
          id: result.id,
          title: result.summary,
          start_time: result.start.date_time || result.start.date,
          end_time: result.end.date_time || result.end.date,
          location: result.location,
          url: result.html_link,
          description: result.description
        )
      end
    end

    def delete_event(event_id)
      with_error_handling do
        @service.authorization = user_credentials(scopes: API_SCOPES)
        @service.delete_event(@calendar_id, event_id)
        true
      end
    end

    def timezone
      with_error_handling do
        @service.authorization = user_credentials(scopes: API_SCOPES)
        calendar = @service.get_calendar(@calendar_id)
        calendar.time_zone
      end
    end
  end
end 