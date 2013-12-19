$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"

module Acme
  class Space < Grape::API
    format :txt
    desc "get the spaces belong to one org"
    get '/xplat_get_space_by_org' do
        org=params[:org].to_s.gsub("\"",'').gsub("'",'')
        spaces=[]
        AppBns.where(:organization=>org).find_each do |app|
            spaces.push(app.space) unless spaces.include?(app.space)
        end
        spaces.to_json
    end
  end
end
