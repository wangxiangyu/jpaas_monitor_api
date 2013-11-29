module Acme
  class API < Grape::API
    format :json
    mount ::Acme::LogMonitor
  end
end

