module GoogleServices
  class Configuration
    attr_accessor :client_id, :client_secret, :token_expiry_buffer,
                  :default_calendar

    def initialize
      @token_expiry_buffer = 60
      @default_calendar = 'primary'
    end
  end
end 