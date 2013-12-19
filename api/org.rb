$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
module Acme
  class Org < Grape::API
    format :txt
    desc "get organization list"
    get '/xplat_get_org_list' do
        orgs=[]
        AppBns.find_each do |app|
            orgs.push(app.organization) unless orgs.include?(app.organization)
        end
        orgs.to_json
    end
  end
end
