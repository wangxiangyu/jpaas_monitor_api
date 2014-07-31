require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
require "rack/contrib"
require "securerandom"

module Acme
  class DoAlarm < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def do_alarm(receiver,msg)
            gem_server="emp01.baidu.com:15003"
            `gsmsend -s #{gem_server} #{receiver}@#{msg}`
        end
        def get_receivers(app,space,org)
            host="icf_2.jpaas-ng00.baidu.com"
            path="/api/spaces/#{space_id}/apps"
            path="/api/apps/users?org=#{org}&space=#{space}&app=#{app}"
            http = Net::HTTP.new(host,80)
            headers = {
                'Authorization'=>"3FCPpbFZ5fAmES4YuMmtg1vGiT70vOgL3URTZmfb"
            }
            response=http.get(path, headers)
            receivers=[]
            receivers=JSON.parse response.body
            return receivers
        end
    end
    namespace :do_alarm do
        after do
            ActiveRecord::Base.clear_active_connections!
        end
        desc "do alarm by app info"
        params do
            requires :app, type: String, desc: "app name without version"
            requires :space, type: String, desc: "space name"
            requires :org, type: String, desc: "organization name"
            requires :msg, type: String, desc: "alarm message"
        end
        get "/by_app_info" do
            receivers=get_receivers(app,space,org)
            receivers.each do  |receiver|
                do_alarm(receiver['mobile'],msg)
            end
        end
    end
  end
end
