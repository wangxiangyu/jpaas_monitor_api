require "net/http"
require "cgi"

    class Http
        class << self
            def http_get(domain,path,params)
                return Net::HTTP.get(domain, "#{path}?".concat(params.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&'))) unless params.nil?
                return Net::HTTP.get(domain, path)
            end
            def http_post(domain,path,params)
                uri = URI.parse(domain.to_s+path.to_s)
                return Net::HTTP.post_form(uri,params)
            end
        end
    end
