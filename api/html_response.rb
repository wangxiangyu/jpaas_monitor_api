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
  end
end
