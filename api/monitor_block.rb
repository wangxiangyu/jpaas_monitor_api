require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
require "rack/contrib"

module Acme
  class MonitorBlock < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
    end
    namespace :monitor_block do
        desc "block monitor"
        params do
            requires :bns, type: String, desc: "bns"
            requires :time, type: Integer, desc: "time" 
        end
        get '/block' do
            bns=format(params['bns'])
            time=format(params['time'])
            result=`/home/work/dashboard/jpaas_monitor_api/lib/montool.py -b #{bns} -d #{time} 2>&1`
            if result == 'OK'
                return {:rescode=>0,:msg=>"ok"}
            else
                return {:rescode=>-1,:msg=>"Failed: #{result}"}
            end
        end

        desc "unblock monitor"
        params do
            requires :bns, type: String, desc: "bns"
        end
        get '/unblock' do
            bns=format(params['bns'])
            result=`/home/work/dashboard/jpaas_monitor_api/lib/montool.py -u #{bns} 2>&1`
            if result == 'OK'
                return {:rescode=>0,:msg=>"ok"}
            else
                return {:rescode=>-1,:msg=>"Failed: #{result}"}
            end
        end

        desc "query about monitor"
        params do
            requires :bns, type: String, desc: "bns"
        end
        get '/query' do
            bns=format(params['bns'])
            result=`/home/work/dashboard/jpaas_monitor_api/lib/montool.py -s #{bns} 2>&1`
            if result.include?(" blocked ") or result.include?(" unblocked ")
                return {:rescode=>0,:msg=>"#{result}"}
            else
                return {:rescode=>-1,:msg=>"Failed: #{result}"}
            end
        end
    end
  end
end
