$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
require "rack/contrib"
module Acme
  class Cluster < Grape::API
    use Rack::JSONP
    format :json
    helpers do
        def format(s)
            s.to_s.gsub(/^"/,"").gsub(/"$/,"").gsub(/^'/,"").gsub(/'$/,"")
        end
    end
    after do
        ActiveRecord::Base.clear_active_connections!
    end
    desc "get organization list"
    params do
        requires :cluster_num, type: String, desc: "cluster num"
    end
    get '/get_host_list' do
        cluster_num=format(params['cluster_num'])
        hosts=[]
        AllHosts.where(:cluster=>cluster_num).find_each do |host|
            hosts << host.host
        end
        hosts
    end
  end
end
