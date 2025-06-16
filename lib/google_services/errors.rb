module GoogleServices
  class Error < StandardError; end
  
  class AuthorizationError < Error; end
  class TokenExpiredError < AuthorizationError; end
  class MissingTokenError < AuthorizationError; end
  
  class ApiError < Error; end
  class QuotaExceededError < ApiError; end
  class NotFoundError < ApiError; end
  
  class ConfigurationError < Error; end
end 