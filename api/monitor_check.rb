$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
require "rack/contrib"
require "digest"
require 'net/http'
require 'json'
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
module Acme
  class MonitorCheck < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
        def get_app_key(app,space,org)
            result=AppBns.where(:app_name=>app,:space=>space,:organization=>org)
            if result.empty?
                return nil
            else
                return result.first.app_key
            end
        end
        def add_domain_monitor?(app_key)
            result=DomainMonitorRaw.where(:app_key=>app_key)
            if result.empty?
                return false
            else
                return true
            end
        end
        def get_org_list
            list={}
            host="icf_2.jpaas-ng00.baidu.com"
            path="/api/orgs"
            http = Net::HTTP.new(host,80)
            headers = {
                'Authorization'=>"3FCPpbFZ5fAmES4YuMmtg1vGiT70vOgL3URTZmfb"
            }
            response=http.get(path, headers)
            result=JSON.parse response.body
            result.each do |org|
                list[org['id']]=org['name']
            end
            list
        end
        def get_space_list
        end
        def get_app_list
        end
    end
    desc "check domain monitor coverage"
    get "/check/domain_monitor_check" do
        result={}
        orgs=get_org_list
        return orgs
        
        orgs.each do |org|
            result[org]||={}
            spaces=['win']
            spaces.each do |space|
                result[org][space]||={}
                apps=['win']
                apps.each do  |app|
                    result[org][space][app]||={}
                    app_key=get_app_key(app,space,org)
                    if app_key.nil?
                        result[org][space][app]="WARNING: This app has't been online yet"
                        next
                    end
                    if add_domain_monitor?(app_key) and Noah3.domain_raw_completed?(app_key)
                        result[org][space][app]="OK, This app has domain monitor"
                    else
                        result[org][space][app]="WARNING, This app has't have any domain monitor yet"
                    end
                end
            end
        end
        return {:rescode=>0,:msg=>result}
    end
  end
end
