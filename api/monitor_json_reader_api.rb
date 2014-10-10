require "net/http"
$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "rack/contrib"

module YamlParser
  def self.call(object, env)
    data = YAML.load object
    out = {value: data}
    if data.is_a? Hash
      out.merge!(data)
    end
    out
  end
end

module Acme
    class JsonReader < Grape::API
        use Rack::JSONP
        format :json
        rescue_from :all
	content_type :yaml, "text/yaml"
	parser :yaml, YamlParser
        helpers do
            def add_log_monitor(app_key, log_monitor_hash)
                validate_k log_monitor_hash, 'raws'
                raws = log_monitor_hash['raws'].clone
                pre_clean("log_monitor", app_key)
                raws.each do |raw|
                    raw_key = nil
                    send_local_api("log_monitor", "add_raw", {'app_key' => app_key}, raw, ["items","alert"]) do |reply|
                        raw_key = reply['raw_key']
                    end
                    validate_k raw, 'items'
                    raw['items'].each do |item|
                        item_key = nil
                        send_local_api("log_monitor", "add_item", {'raw_key' => raw_key}, item, ["rules"]) do |reply|
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
            def add_domain_monitor(app_key, domain_monitor_hash)
                validate_k domain_monitor_hash, 'raws'
                raws = domain_monitor_hash['raws'].clone
                pre_clean("domain_monitor", app_key)
                raws.each do |raw|
                    raw_key = nil
                    send_local_api("domain_monitor", "add_raw", {'app_key' => app_key}, raw, ["items","alert"]) do |reply|
                        raw_key = reply['raw_key']
                    end
                    validate_k raw, 'items'
                    raw['items'].each do |item|
                        item_key = nil
                        send_local_api("domain_monitor", "add_item", {'raw_key' => raw_key}, item, ["rules"]) do |reply|
                            item_key = reply['item_key']
                        end
                        validate_k item, 'rules'
                        item['rules'].each do |rule|
                            send_local_api("domain_monitor", "add_rule", {'item_key' => item_key}, rule)              
                        end
                    end
                    alert = raw['alert']
                    send_local_api("domain_monitor", "add_alert", {'raw_key' => raw_key}, alert)
                end
            end
            def add_proc_monitor(app_key, proc_monitor_hash)
                validate_k proc_monitor_hash, 'raws'
                raws = proc_monitor_hash['raws'].clone
                pre_clean("proc_monitor", app_key)
                raws.each do |raw|
                    raw_key = nil
                    send_local_api("proc_monitor", "add_raw", {'app_key' => app_key}, raw, ["rules","alert"]) do |reply|
                        raw_key = reply['raw_key']
                    end
                    validate_k raw, 'rules'
                    raw['rules'].each do |rule|
                        send_local_api("proc_monitor", "add_rule", {'raw_key' => raw_key}, rule)              
                    end
                    alert = raw['alert']
                    send_local_api("proc_monitor", "add_alert", {'raw_key' => raw_key}, alert)
                end
            end
            def add_udm_monitor(app_key, udm_monitor_hash)
                validate_k udm_monitor_hash, 'raws'
                raws = udm_monitor_hash['raws'].clone
                pre_clean("user_defined_monitor", app_key)
                raws.each do |raw|
                    raw_key = nil
                    send_local_api("user_defined_monitor", "add_raw", {'app_key' => app_key}, raw, ["rules","alert"]) do |reply|
                        raw_key = reply['raw_key']
                    end
                    validate_k raw, 'rules'
                    raw['rules'].each do |rule|
                        send_local_api("user_defined_monitor", "add_rule", {'raw_key' => raw_key}, rule)              
                    end
                    alert = raw['alert']
                    send_local_api("user_defined_monitor", "add_alert", {'raw_key' => raw_key}, alert)
                end
            end
            def add_http_monitor(app_key, http_monitor_hash)
                validate_k http_monitor_hash, 'raws'
                raws = http_monitor_hash['raws'].clone
                pre_clean("http_user_defined_monitor", app_key)
                raws.each do |raw|
                    raw_key = nil
                    send_local_api("http_user_defined_monitor", "add_raw", {'app_key' => app_key}, raw, ["rules","alert"]) do |reply|
                        raw_key = reply['raw_key']
                    end
                    validate_k raw, 'rules'
                    raw['rules'].each do |rule|
                        send_local_api("http_user_defined_monitor", "add_rule", {'raw_key' => raw_key}, rule)              
                    end
                    alert = raw['alert']
                    send_local_api("http_user_defined_monitor", "add_alert", {'raw_key' => raw_key}, alert)
                end
            end
            def pre_clean(namespace, app_key)
                case namespace
                    when "http_user_defined_monitor"
                        raws = summary_request(namespace, "get_http_user_defined_monitor_by_app_key", app_key)
                        cleaner(namespace, raws, 'raw') 
                    when "domain_monitor"
                        raws = summary_request(namespace, "get_domain_monitor_by_app_key", app_key)
                        cleaner(namespace, raws, 'raw')
                    when "user_defined_monitor"
                        raws = summary_request(namespace, "get_user_defined_monitor_by_app_key", app_key)
                        cleaner(namespace, raws, 'raw')
                    when "proc_monitor"
                        raws = summary_request(namespace, "get_proc_monitor_by_app_key", app_key)
                        cleaner(namespace, raws, 'raw')
                    when "log_monitor"
                        raws = summary_request(namespace, "get_log_monitor_by_app_key", app_key)
                        cleaner(namespace, raws, 'raw') 
                end
            end
            def summary_request(namespace, api, app_key)
                raws = []
                begin 
                send_local_api(namespace, api, {"app_key" => app_key}, {}) do |reply|
                    raws = reply['raw'] 
                    raws ||= reply['raws']
                end
                raws 
                rescue
                    MyConfig.logger.debug("No monitor found for app: #{app_key}. New app inserting.")
                end
            end
            def cleaner(namespace, array, clean_key="")
                if array.nil? 
                    return
                end
                array.each do |element|
                    if element['items'] != nil
                        cleaner(namespace, element['items'], "item")
                    elsif element['rules'] != nil
                        cleaner(namespace, element['rules'], "rule")
                    end
                    if clean_key == "raw" && !element['alert'].nil? && !element['alert'].empty?
                        send_local_api(namespace, "del_alert", {"raw_key" => element['raw_key']}, {}) do |reply|
                            MyConfig.logger.debug("delete del_alert #{element['raw_key']}")
                        end
                    end
                    to_del_key = "#{clean_key}_key"
                    send_local_api(namespace, "del_#{clean_key}", {"#{to_del_key}" => element[to_del_key]}, {}) do |reply|
                        MyConfig.logger.debug("delete del_#{clean_key} #{element[to_del_key]}")
                    end
                end
            end
            def validate_k(hash, check_key)
                unless hash.has_key?(check_key) && ! hash[check_key].nil? && hash[check_key].length > 0
                    raise "input hash: #{hash.keys}, where #{check_key} not given"
                end
            end
            def send_local_api(namespace, api_name, key, hash, exclude_keys=nil, &callback)
                params_hash = hash.clone
                unless exclude_keys.nil?
                    exclude_keys.each do |exclude_key|
                        params_hash.delete(exclude_key) unless exclude_key.nil?
                    end
                end
                params_hash.merge!(key)
                params = split_hash(params_hash)
                uri = URI(URI.escape("http://127.0.0.1:8002/#{namespace}/#{api_name}?#{params}"))
                http = Net::HTTP.new(uri.host, uri.port)
                request = Net::HTTP::Get.new(uri.request_uri)
                MyConfig.logger.debug("request:#{uri.request_uri}")
                response = http.request(request)
                resbody = JSON.parse(response.body)
                rescode = resbody['rescode']
                if response.code != '200' || rescode != 0
                    raise "Local api request failed. \n URI: #{uri} \n RES_STAT: #{response.code} \n RESCODE: #{rescode} \n RES_BODY: #{response.body}"
                end
                callback.call(resbody) unless callback.nil?
            end
            def split_hash(hash)
                tiny_string = ''
                hash.each do |key,value|
                    pavalue = ""
                    unless value.is_a?(String)
                        raise "The value of #{key} is not a string"
                    end
                    pavalue = value
                    tiny_string << "&#{key}='#{pavalue}'" 
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
                #TODO enable at_least
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
                    #MyConfig.logger.warn(e.message)
		            MyConfig.logger.warn(e.backtrace.inspect)
	        	    error!({:rescode => -1, :result => "error", :msg => e.message}, 400)
                end
            end #end_of_post
        end #end_of_namespace
    end #end_of_class
end #end_of_module
