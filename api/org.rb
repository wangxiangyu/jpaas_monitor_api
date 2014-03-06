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
  end
end
