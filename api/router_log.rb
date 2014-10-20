$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
require "rack/contrib"
require "net/http"
module Acme
  class RouterLog < Grape::API
    use Rack::JSONP
    format :json
    helpers do
    end
    namespace :routerlog do
        after do
            ActiveRecord::Base.clear_active_connections!
        end
        desc "get 502 info (detail)from router.log"
        params do
            requires :from_time, type: String, desc: "start time"
            requires :to_time, type: String, desc: "end time"
            optional :idc, type: String, desc: "show idc or not" , values: ['yes','no'], default: 'no'
            optional :instance_addr, type: String, desc: "show instance_addr or not", values: ['yes','no'], default: 'no'
            optional :error_type, type: String, desc: "show error_type or not", values: ['yes','no'], default: 'no'
            optional :app_id, type: String, desc: "show app_id or not", values: ['yes','no'], default: 'no'
            optional :cluster, type: String, desc: "show cluster or not", values: ['yes','no'], default: 'no'
            optional :router, type: String, desc: "show router or not", values: ['yes','no'], default: 'no'
        end
        get '/get_502_info' do
            from_time=format(params['from_time'])
            to_time=format(params['to_time'])
            idc_need=format(params['idc'])
            instance_addr_need=format(params['instance_addr'])
            error_type_need=format(params['error_type'])
            app_id_need=format(params['app_id'])
            cluster_need=format(params['cluster'])
            router_need=format(params['router'])
            result=[]
            result_from_jiuze=JSON.parse(Net::HTTP.get("api.aqueducts.baidu.com","/v1/events?product=jpaas&service=router-error&item=page_view&calculation=count&from=#{from_time}&to=#{to_time}&period=10&detail=true",80))
            return result if result_from_jiuze.size==0
            result_from_jiuze.each do |event|
                result_event={}
                result_event['event_time']=event["event_time"]
                result_event['log_info']={}
                event["tags"]["idc&instance_addr&error_type&app_id&cluster&router&idc"].each do |info,count|
                    info_array=info.split('&')
                    idc=info_array[0]
                    instance_addr=info_array[1]
                    error_type=info_array[2]
                    app_id=info_array[3]
                    cluster=info_array[4]
                    router=info_array[5]
                    key=''
                    key=key+idc+'&' if idc_need == 'yes'
                    key=key+instance_addr+'&' if instance_addr_need == 'yes'
                    key=key+error_type+'&' if error_type_need == 'yes'
                    key=key+app_id+'&' if app_id_need == 'yes'
                    key=key+cluster+'&' if cluster_need == 'yes'
                    key=key+router if router_need == 'yes'
                    key.sub!(/&$/,'')
                    if result_event['log_info'].has_key?(key)
                        result_event['log_info'][key]['count']+=count.to_i
                    else
                        result_event['log_info'][key]={}
                        result_event['log_info'][key]['idc']=idc if idc_need == 'yes'
                        result_event['log_info'][key]['instance_addr']=instance_addr if instance_addr_need == 'yes'
                        result_event['log_info'][key]['error_type']=error_type if error_type_need == 'yes'
                        result_event['log_info'][key]['app_id']=app_id if app_id_need == 'yes'
                        result_event['log_info'][key]['cluster']=cluster if cluster_need == 'yes'
                        result_event['log_info'][key]['router']=router if router_need == 'yes'
                        result_event['log_info'][key]['count']=count.to_i
                    end
                end
                result << result_event
            end
            return result
        end
        desc "get 502 info (num sum) from router.log"
        params do
            requires :from_time, type: String, desc: "start time"
            requires :to_time, type: String, desc: "end time"
            optional :idc, type: String, desc: "show idc or not" , values: ['yes','no'], default: 'no'
            optional :instance_addr, type: String, desc: "show instance_addr or not", values: ['yes','no'], default: 'no'
            optional :error_type, type: String, desc: "show error_type or not", values: ['yes','no'], default: 'no'
            optional :app_id, type: String, desc: "show app_id or not", values: ['yes','no'], default: 'no'
            optional :cluster, type: String, desc: "show cluster or not", values: ['yes','no'], default: 'no'
            optional :router, type: String, desc: "show router or not", values: ['yes','no'], default: 'no'
        end
        get '/get_502_sum' do
            from_time=format(params['from_time'])
            to_time=format(params['to_time'])
            idc_need=format(params['idc'])
            instance_addr_need=format(params['instance_addr'])
            error_type_need=format(params['error_type'])
            app_id_need=format(params['app_id'])
            cluster_need=format(params['cluster'])
            router_need=format(params['router'])
            result={}
            result_from_jiuze=JSON.parse(Net::HTTP.get("api.aqueducts.baidu.com","/v1/events?product=jpaas&service=router-error&item=page_view&calculation=count&from=#{from_time}&to=#{to_time}&period=10&detail=true",80))
            return result if result_from_jiuze.size==0
            result_from_jiuze.each do |event|
                event["tags"]["idc&instance_addr&error_type&app_id&cluster&router&idc"].each do |info,count|
                    info_array=info.split('&')
                    idc=info_array[0]
                    instance_addr=info_array[1]
                    error_type=info_array[2]
                    app_id=info_array[3]
                    cluster=info_array[4]
                    router=info_array[5]
                    key=''
                    key=key+idc+'&' if idc_need == 'yes'
                    key=key+instance_addr+'&' if instance_addr_need == 'yes'
                    key=key+error_type+'&' if error_type_need == 'yes'
                    key=key+app_id+'&' if app_id_need == 'yes'
                    key=key+cluster+'&' if cluster_need == 'yes'
                    key=key+router if router_need == 'yes'
                    key.sub!(/&$/,'')
                    if result.has_key?(key)
                        result[key]['count']+=count.to_i
                    else
                        result[key]={}
                        result[key]['idc']=idc if idc_need == 'yes'
                        result[key]['instance_addr']=instance_addr if instance_addr_need == 'yes'
                        result[key]['error_type']=error_type if error_type_need == 'yes'
                        result[key]['app_id']=app_id if app_id_need == 'yes'
                        result[key]['cluster']=cluster if cluster_need == 'yes'
                        result[key]['router']=router if router_need == 'yes'
                        result[key]['count']=count.to_i
                    end
                end
            end
            result_sort=[]
            p result
            result.each do |key,info|
                if result_sort.size ==0
                    result_sort << info
                else
                    index=0
                    result_sort.each do |item|
                        if info['count'] >= item['count']
                            result_sort.insert(index,info)
                            break
                        end
                        if index==result_sort.size-1
                            result_sort.insert(result_sort.size,info)
                            break
                        end
                        index=index+1
                    end
                end
            end
            return result_sort
        end
    end
  end
end
