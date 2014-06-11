$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
require "rack/contrib"
module Acme
  class Org < Grape::API
    use Rack::JSONP
    format :json
    after do
        ActiveRecord::Base.clear_active_connections!
    end
    desc "get organization list"
    get '/xplat_get_org_list' do
        orgs=[]
        AppBns.find_each do |app|
            orgs.push(app.organization) unless orgs.include?(app.organization)
        end
        orgs
    end

    desc "get app list by org"
    params do
        requires :org, type: String, desc: "org name"
    end
    get '/xplat_get_app_list_by_org' do
        org=params[:org].to_s.gsub("\"",'').gsub("'",'')
        result={}
        InstanceStatus.where("organization = ?",org).find_each do |instance|
                instance_hash=instance.serializable_hash
                result[instance_hash['space']]=[] unless result.has_key?(instance_hash['space'])
                result[instance_hash['space']].push(instance_hash['app_name'].split('_')[0]) unless result[instance_hash['space']].include?(instance_hash['app_name'].split('_')[0])
        end
        result
    end
  end
end
