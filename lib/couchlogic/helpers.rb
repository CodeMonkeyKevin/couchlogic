module Couchlogic
  
private
  
  # Sanitize URL parameter
  def s(param)
    URI.escape param
  end
  
end