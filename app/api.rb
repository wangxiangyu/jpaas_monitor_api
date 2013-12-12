module Acme
  class API < Grape::API
    format :json
    mount ::Acme::LogMonitor
    mount ::Acme::Org
    mount ::Acme::Space
    mount ::Acme::App
    mount ::Acme::RegisterRouterBns
  end
end

