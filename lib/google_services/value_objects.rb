module GoogleServices
  # Simple value object for calendar events
  class Event
    attr_reader :id, :title, :start_time, :end_time, :location, 
                :url, :description, :created_at

    def initialize(attrs = {})
      @id = attrs[:id]
      @title = attrs[:title]
      @start_time = parse_time(attrs[:start_time])
      @end_time = parse_time(attrs[:end_time])
      @location = attrs[:location]
      @url = attrs[:url]
      @description = attrs[:description]
      @created_at = parse_time(attrs[:created_at])
    end

    def to_h
      {
        id: id,
        title: title,
        start_time: start_time,
        end_time: end_time,
        location: location,
        url: url,
        description: description,
        created_at: created_at
      }
    end

    private

    def parse_time(time)
      return nil if time.nil?
      return time if time.is_a?(Time) || time.is_a?(DateTime)
      Time.parse(time.to_s)
    rescue ArgumentError
      nil
    end
  end

  # Simple value object for documents
  class Document
    attr_reader :id, :title, :url, :created_at, :modified_at

    def initialize(attrs = {})
      @id = attrs[:id]
      @title = attrs[:title]
      @url = attrs[:url]
      @created_at = parse_time(attrs[:created_at])
      @modified_at = parse_time(attrs[:modified_at])
    end

    def to_h
      {
        id: id,
        title: title,
        url: url,
        created_at: created_at,
        modified_at: modified_at
      }
    end

    private

    def parse_time(time)
      return nil if time.nil?
      return time if time.is_a?(Time) || time.is_a?(DateTime)
      Time.parse(time.to_s)
    rescue ArgumentError
      nil
    end
  end

  # Simple value object for meetings
  class Meeting
    attr_reader :id, :title, :url, :meeting_code, :start_time

    def initialize(attrs = {})
      @id = attrs[:id]
      @title = attrs[:title]
      @url = attrs[:url]
      @meeting_code = attrs[:meeting_code]
      @start_time = parse_time(attrs[:start_time])
    end

    def to_h
      {
        id: id,
        title: title,
        url: url,
        meeting_code: meeting_code,
        start_time: start_time
      }
    end

    private

    def parse_time(time)
      return nil if time.nil?
      return time if time.is_a?(Time) || time.is_a?(DateTime)
      Time.parse(time.to_s)
    rescue ArgumentError
      nil
    end
  end
end 