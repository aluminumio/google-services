require 'google/apis/calendar_v3'
require 'google/apis/meet_v2'

module GoogleServices
  class Meet < Base
    API_SCOPES = [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
      'https://www.googleapis.com/auth/meetings.space.created'
    ].freeze

    def initialize(credentials)
      super(credentials)
      @calendar_service = Google::Apis::CalendarV3::CalendarService.new
      @meet_service = Google::Apis::MeetV2::MeetService.new
    end

    def create(title, start_time: Time.now, duration: 60, description: nil)
      with_error_handling do
        @calendar_service.authorization = user_credentials(scopes: API_SCOPES)
        
        # Create event with Google Meet conferencing
        event = Google::Apis::CalendarV3::Event.new(
          summary: title,
          description: description,
          start: {
            date_time: start_time.iso8601,
            time_zone: Time.zone&.name || 'UTC'
          },
          end: {
            date_time: (start_time + duration.minutes).iso8601,
            time_zone: Time.zone&.name || 'UTC'
          },
          conference_data: {
            create_request: {
              request_id: SecureRandom.uuid,
              conference_solution_key: {
                type: 'hangoutsMeet'
              }
            }
          }
        )

        # Insert the event with conferencing
        result = @calendar_service.insert_event(
          configuration.default_calendar,
          event,
          conference_data_version: 1
        )

        Meeting.new(
          id: result.conference_data&.conference_id,
          title: result.summary,
          url: result.conference_data&.entry_points&.first&.uri,
          meeting_code: result.conference_data&.conference_id,
          start_time: result.start.date_time
        )
      end
    end

    def create_space(access_type: 'OPEN')
      with_error_handling do
        @meet_service.authorization = user_credentials(scopes: API_SCOPES)
        
        space_config = Google::Apis::MeetV2::SpaceConfig.new
        space_config.access_type = access_type
        
        space = Google::Apis::MeetV2::Space.new(config: space_config)
        result = @meet_service.create_space(space)
        
        Meeting.new(
          id: result.name,
          url: result.meeting_uri,
          meeting_code: result.meeting_code
        )
      end
    end


  end
end 