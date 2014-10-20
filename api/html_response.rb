$:.unshift(File.expand_path("../lib/", File.dirname(__FILE__)))
require "config"
require "database"
require "rack/contrib"
require "digest"
require 'net/http'
require 'json'
$:.unshift(File.expand_path("../lib/noah3.0", File.dirname(__FILE__)))
require "noah3.0"
module Acme
  class Html< Grape::API
    format :txt
    helpers do
    end
    get "/html/check/instance_num_blance_check_ng00_ng01" do
        header 'Content-Type', 'text/html'
        error_apps=JSON.parse(Net::HTTP.get('127.0.0.1','/check/instance_num_blance_check_ng00_ng01',8002))
        response_template=%{
        <DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
    
        <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
            <head>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
                <title>Instance num blance check result between ng00 and ng01</title>
            </head>
            <body>
                <table border="1">
                    <tr>
                        <td>app_name</td>
                        <td>organization</td>
                        <td>space</td>
                        <td>instance_num_ng00</td>
                        <td>instance_num_ng01</td>
                    </tr>
                    <% error_apps.each do |error_app| %>
                        <tr>
                            <td><%= error_app['app_name'] %></td>
                            <td><%= error_app['organization'] %></td>
                            <td><%= error_app['space'] %></td>
                            <td><%= error_app['instance_num_ng00'] %></td>
                            <td><%= error_app['instance_num_ng01'] %></td>
                        </tr>
                    <% end %>
                </table>
            </body>
        </html>
        }
        ERB.new(response_template).result(binding)
    end

    get "/html/router/router_502_log" do
        header 'Content-Type', 'text/html'
        #error_apps=JSON.parse(Net::HTTP.get('127.0.0.1','/check/instance_num_blance_check_ng00_ng01',8002))
        response_template=%{
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
            <head>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
                <title>router_502_log</title>
                <link rel="stylesheet" href="http://cdn.bootcss.com/bootstrap/3.2.0/css/bootstrap.min.css">
                <script type="text/javascript" src="http://console-jpaas.baidu.com/hatch_static/javascripts/lib/jquery-1-9-0-min.js"></script>
                <script type="text/javascript" src="http://console-jpaas.baidu.com/site_media//js/lib/My97DatePicker/WdatePicker.js"></script>
            </head>
            <body>
                <form name="input" action="router_502_log_sum" method="get">
                    <input type="checkbox" name="router" />
                    router
                    <input type="checkbox" name="cluster" />
                    cluster
                    <input type="checkbox" name="app_name" />
                    app_name
                    <input type="checkbox" name="error_type" />
                    error_type
                    <input type="checkbox" name="instance_addr" />
                    instance_addr
                    <input type="checkbox" name="idc" />
                    idc
                    </br>
                    <div class="col-xs-6">
                    Time: From
                    <input class="domain-trend-chart-begin Wdate" name="begin_time" data-require="true" onfocus="WdatePicker({dateFmt:'yyyy-MM-dd HH:mm:ss',maxDate:'%y/%M/%d %H:%m:%s'})" type="text">
                    To
                    <input class="domain-trend-chart-begin Wdate" name="end_time" data-require="true" onfocus="WdatePicker({dateFmt:'yyyy-MM-dd HH:mm:ss',maxDate:'%y/%M/%d %H:%m:%s'})" type="text">
                    </div>
                    </br>
                    <input type="submit" value="Submit" />
                </form>
             </body>
        </html>
        }
        ERB.new(response_template).result(binding)
    end


    desc "get 502 info (num sum) from router.log html response"
    params do
        requires :begin_time, type: String, desc: "start time"
        requires :end_time, type: String, desc: "end time"
        optional :idc, type: String, desc: "show idc or not", default: 'no'
        optional :instance_addr, type: String, desc: "show instance_addr or not", default: 'no'
        optional :error_type, type: String, desc: "show error_type or not", default: 'no'
        optional :app_name, type: String, desc: "show app_name or not", default: 'no'
        optional :cluster, type: String, desc: "show cluster or not", default: 'no'
        optional :router, type: String, desc: "show router or not", default: 'no'
    end
    get "/html/router/router_502_log_sum" do
        header 'Content-Type', 'text/html'
        idc_need=format(params['idc'])
        instance_addr_need=format(params['instance_addr'])
        error_type_need=format(params['error_type'])
        app_name_need=format(params['app_name'])
        cluster_need=format(params['cluster'])
        router_need=format(params['router'])
        begin_time=format(params['begin_time'])
        end_time=format(params['end_time'])
        begin_time_sec_to_now=Time.now.to_i-Time.parse(begin_time).to_i
        end_time_sec_to_now=Time.now.to_i-Time.parse(end_time).to_i
        if begin_time_sec_to_now < end_time_sec_to_now
            return "begin time must be later than end time"
        end
        request=""
        request=request+"idc=yes"+"&" if idc_need == 'on'
        request=request+"instance_addr=yes"+"&" if instance_addr_need == 'on'
        request=request+"error_type=yes"+"&" if error_type_need == 'on'
        request=request+"app_name=yes"+"&" if app_name_need == 'on'
        request=request+"cluster=yes"+"&" if cluster_need == 'on'
        request=request+"router=yes"+"&" if router_need == 'on'
        request.sub!(/&$/,'')
        router_502_sum=JSON.parse(Net::HTTP.get('127.0.0.1',"/routerlog/get_502_sum?from_time=-#{begin_time_sec_to_now}s&to_time=-#{end_time_sec_to_now}s&#{request}",8002))
        response_template=%{
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
            <head>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
                <title>router_502_log</title>
                <link rel="stylesheet" href="http://cdn.bootcss.com/bootstrap/3.2.0/css/bootstrap.min.css">
            </head>
            <body>
                <table border="1" align="center">
                    <tr>
                        <% if router_need == 'on' %>
                            <td align="center" >router</td>
                        <% end %>
                        <% if cluster_need == 'on' %>
                            <td align="center" >cluster</td>
                        <% end %>
                        <% if app_name_need == 'on' %>
                            <td align="center" >app_name</td>
                        <% end %>
                        <% if error_type_need == 'on' %>
                            <td align="center" >error_type</td>
                        <% end %>
                        <% if instance_addr_need == 'on' %>
                            <td align="center" >instance_addr</td>
                        <% end %>
                        <% if idc_need == 'on' %>
                            <td align="center" >idc</td>
                        <% end %>
                            <td align="center" >count</td>
                    </tr>
                    <% router_502_sum.each do |info| %>
                        <tr>
                            <% if info.has_key?("router") %>
                                <td align="center" ><%= info['router'] %></td>
                            <% end %>
                            <% if info.has_key?("cluster") %>
                                <td align="center" ><%= info['cluster'] %></td>
                            <% end %>
                            <% if info.has_key?("app_name") %>
                                <td align="center" ><%= info['app_name'] %></td>
                            <% end %>
                            <% if info.has_key?("error_type") %>
                                <td align="center" ><%= info['error_type'] %></td>
                            <% end %>
                            <% if info.has_key?("instance_addr") %>
                                <td align="center" ><%= info['instance_addr'] %></td>
                            <% end %>
                            <% if info.has_key?("idc") %>
                                <td align="center" ><%= info['idc'] %></td>
                            <% end %>
                                <td align="center" ><%= info['count'] %></td>
                        </tr>
                    <% end %>
                </table>
             </body>
        </html>
        }
        ERB.new(response_template).result(binding)
    end
  end
end
