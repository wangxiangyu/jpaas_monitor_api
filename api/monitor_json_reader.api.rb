require "net/http"
require "digest"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
require "rack/contrib"
require "securerandom"

module Acme
    class JsonReader < Grape::API
        use Rack::JSONP
        format :json
        rescue_from :all
        helpers do
            def add_log_monitor(app_key, log_monitor_hash)
                validate_k log_monitor_hash, 'raws'
                raws = log_monitor_hash['raws'].clone
		MyConfig.logger.warn(raws)
                raws.each do |raw|
                    raw_key = nil
                    send_local_api("log_monitor", "add_raw", {'app_key' => app_key}, raw, "items") do |reply|
                        raw_key = reply['raw_key']
			MyConfig.logger.warn(reply)
                    end
		    MyConfig.logger.warn("raw_key: #{raw_key}")
                    validate_k raw, 'items'
                    raw['items'].each do |item|
                        item_key = nil
                        send_local_api("log_monitor", "add_item", {'raw_key' => raw_key}, raw, "rules") do |reply|
                            item_key = reply['item_key']
                        end
                        validate_k item, 'rules'
                        item['rules'].each do |rule|
                            send_local_api("log_monitor", "add_rule", {'item_key' => item_key}, rule)              
                        end
                    end
                    alert = raw['alert']
                    send_local_api("log_monitor", "add_alert", {'raw_key' => raw_key}, alert)
                end
            end
            def add_domain_monitor(app_key, monitor_hash)

            end
            def add_proc_monitor(app_key, monitor_hash)

            end
            def add_usr_defined_monitor(app_key, monitor_hash)

            end
            def add_http_usr_defined_monitor(app_key, monitor_hash)
          
            end

            def validate_k(hash, check_key)
                unless hash.has_key?(check_key) && ! hash[check_key].nil? && hash[check_key].length > 0
                    raise "input hash: #{hash.keys}, where #{check_key} not given"
                end
            end
            def send_local_api(namespace, api_name, key, hash, exclude_key=nil, &callback)
                params_hash = hash.clone
		MyConfig.logger.warn("paramsi_hash:#{params_hash},key:#{key}")
                params_hash.merge!(key)
                params = split_hash(params_hash)
                uri = URI("http://127.0.0.1:8002/#{namespace}/#{api_name}?#{params}")
                http = Net::HTTP.new(uri.host, uri.port)
                request = Net::HTTP::Get.new(uri.request_uri)
                response = http.request(request)
                callback.call(response.body)
            end
            def split_hash(hash)
                tiny_string = ''
                hash.each do |key,value |
                    tiny_string << "&#{key}=#{value}" 
                end
                tiny_string
            end
	end #end_of_helpers
        namespace :json_reader do
            after do
                ActiveRecord::Base.clear_active_connections!
            end
            desc "add monitor in json"
            params do
                requires :app_key, type: String, desc: "app key"
                optional :log, type: Hash, desc: "log monitor config"
                optional :domain, type: Hash, desc: "domain monitor config"
                optional :proc, type: Hash, desc: "proc monitor config" 
                optional :udm, type: Hash,  desc: "udm monitor config"
                optional :http, type: Hash, desc: "http monitor config"
                #at_least_one_of :log, :domain, :proc, :udm, :http
            end
            post '/add_monitor' do
                app_key = params[:app_key]
                begin
                    add_log_monitor(app_key, params['log']) unless params['log'].nil?
                    add_domain_monitor(app_key, params['domain']) unless params['domain'].nil?
                    add_proc_monitor(app_key, params['proc']) unless params['proc'].nil?
                    add_udm_monitor(app_key, params['udm']) unless params['udm'].nil?
                    add_http_monitor(app_key, params['http']) unless params['http'].nil?
		    return {:rescode => 0, :result => "success"}
                rescue Exception => e
                    #TODO LOGGER TOBE ADD
                    MyConfig.logger.warn(e.message)
		    MyConfig.logger.warn(e.backtrace.inspect)
		    error!({:rescode => -1, :result => "error", :msg => e.message}, 400)
                end
            end #end_of_post
        end #end_of_namespace
=begin
	private 
        def validate_k(hash, check_key)
            unless hash.has_key(check_key) && ! hash[check_key].nil? && hash[check_key].length > 0
                raise "input hash: #{hash.keys}, where #{check_key} not given"
            end
        end
        def send_local_api(namespace, api_name, key, hash, exclude_key=nil, &callback)
            params_hash = hash.clone
            params_hash = params_hash.delete(exclude_key) unless exclude_key.nil?
            params_hash.merge!(key)
            params = split_hash(params_hash)
            uri = URI.parse("http://127.0.0.1:8002/#{namespace}/#{api_name}?#{params}")
            http = Net::HTTP.new(uri.host, uri.port)
            request = Net::HTTP::Get.new(uri.request_uri)
            response = http.request(request)
            callback.call(response.body)
        end
        def split_hash(hash)
            tiny_string = ''
            hash.each do |key,value |
                tiny_string << "&#{key}=#{value}" 
            end
            tiny_string
        end
        
        class << self
            def validate_k(hash, check_key)
                unless hash.has_key?(check_key) && ! hash[check_key].nil? && hash[check_key].length > 0
		#unless hash.has_key(check_key) 
                    raise "input hash: #{hash.keys}, where #{check_key} not given"
                end
            end
            def send_local_api(namespace, api_name, key, hash, exclude_key=nil, &callback)
                params_hash = hash.clone
                #params_hash = params_hash.delete(exclude_key) unless exclude_key.nil?
		MyConfig.logger.warn("paramsi_hash:#{params_hash},key:#{key}")
                params_hash.merge!(key)
                params = split_hash(params_hash)
                uri = URI("http://127.0.0.1:8002/#{namespace}/#{api_name}?#{params}")
                http = Net::HTTP.new(uri.host, uri.port)
                request = Net::HTTP::Get.new(uri.request_uri)
                response = http.request(request)
                callback.call(response.body)
            end
            def split_hash(hash)
                tiny_string = ''
                hash.each do |key,value |
                    tiny_string << "&#{key}=#{value}" 
                end
                tiny_string
            end
	end	#end_of_metaclass
=end
    end #end_of_class
end #end_of_module
