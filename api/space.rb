$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
require "rack/contrib"

module Acme
  class Space < Grape::API
    use Rack::JSONP
    format :json
    desc "get the spaces belong to one org"
    params do
        requires :org, type: String, desc: "org name"
    end
    get '/xplat_get_space_by_org' do
        org=params[:org].to_s.gsub("\"",'').gsub("'",'')
        spaces=[]
        AppBns.where(:organization=>org).find_each do |app|
            spaces.push(app.space) unless spaces.include?(app.space)
        end
        spaces
    end
  end
end
