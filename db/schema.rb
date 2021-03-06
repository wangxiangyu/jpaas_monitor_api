# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20141020081113) do

  create_table "app_bns", :force => true do |t|
    t.string   "name"
    t.string   "organization"
    t.string   "space"
    t.string   "app_name"
    t.string   "app_key"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.string   "noah_parentPath"
    t.string   "noah_authKey"
    t.string   "backend"
  end

  add_index "app_bns", ["app_key"], :name => "index_app_bns_on_app_key"

  create_table "bns_instance_register", :force => true do |t|
    t.string   "app_key"
    t.string   "cluster_num"
    t.string   "instance_index"
    t.string   "bns_instance_id"
    t.string   "host"
    t.string   "instance_key"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.string   "version"
  end

  add_index "bns_instance_register", ["app_key"], :name => "index_bns_instance_register_on_app_key"

  create_table "dea_list", :force => true do |t|
    t.string   "uuid"
    t.string   "ip"
    t.string   "cluster_num"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "time"
  end

  add_index "dea_list", ["ip"], :name => "index_dea_list_on_ip"
  add_index "dea_list", ["uuid"], :name => "index_dea_list_on_uuid"

  create_table "domain_monitor_alarm", :force => true do |t|
    t.string   "raw_key"
    t.string   "name"
    t.string   "mail"
    t.string   "sms"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "domain_monitor_alarm", ["raw_key"], :name => "index_domain_monitor_alarm_on_raw_key"

  create_table "domain_monitor_item", :force => true do |t|
    t.string   "raw_key"
    t.string   "name"
    t.string   "cycle"
    t.string   "req_content"
    t.string   "res_check"
    t.string   "mon_idc"
    t.string   "item_key"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "req_type"
    t.string   "port"
  end

  add_index "domain_monitor_item", ["raw_key", "item_key"], :name => "index_domain_monitor_item_on_raw_key_and_item_key"

  create_table "domain_monitor_raw", :force => true do |t|
    t.string   "app_key"
    t.string   "name"
    t.string   "domain"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "raw_key"
  end

  add_index "domain_monitor_raw", ["app_key", "raw_key"], :name => "index_domain_monitor_raw_on_app_key_and_raw_key"

  create_table "domain_monitor_rule", :force => true do |t|
    t.string   "item_key"
    t.string   "name"
    t.string   "item_name"
    t.string   "filter"
    t.string   "alert"
    t.string   "rule_key"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "compare"
    t.string   "threshold"
  end

  add_index "domain_monitor_rule", ["item_key", "rule_key"], :name => "index_domain_monitor_rule_on_item_key_and_rule_key"

  create_table "http_user_defined_monitor_alarm", :force => true do |t|
    t.string   "raw_key"
    t.string   "name"
    t.string   "max_alert_times"
    t.string   "remind_interval_second"
    t.string   "mail"
    t.string   "sms"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  create_table "http_user_defined_monitor_raw", :force => true do |t|
    t.string   "app_key"
    t.string   "name"
    t.string   "cycle"
    t.string   "method"
    t.string   "target"
    t.string   "raw_key"
    t.string   "req_type"
    t.string   "port"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "http_user_defined_monitor_rule", :force => true do |t|
    t.string   "raw_key"
    t.string   "name"
    t.string   "monitor_item"
    t.string   "compare"
    t.string   "threshold"
    t.string   "filter"
    t.string   "alert"
    t.string   "disable_time"
    t.string   "rule_key"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "instance_num_expected", :force => true do |t|
    t.integer  "app_id"
    t.string   "app_name"
    t.string   "cluster_num"
    t.string   "organization"
    t.string   "space"
    t.integer  "instance_num_expected"
    t.datetime "created_at",            :null => false
    t.datetime "updated_at",            :null => false
  end

  create_table "instance_status", :force => true do |t|
    t.integer  "time"
    t.string   "host"
    t.string   "app_name"
    t.integer  "instance_index"
    t.string   "cluster_num"
    t.string   "organization"
    t.string   "space"
    t.string   "bns_node"
    t.string   "uris"
    t.string   "state"
    t.string   "warden_handle"
    t.string   "warden_container_path"
    t.string   "state_starting_timestamp"
    t.text     "port_info"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.string   "noah_monitor_port"
    t.string   "warden_host_ip"
    t.string   "instance_id"
    t.string   "cpu_usage"
    t.string   "mem_usage"
    t.string   "fds_usage"
    t.string   "disk_quota"
    t.string   "mem_quota"
    t.string   "fds_quota"
    t.string   "instance_mgr_host_port"
    t.integer  "to_del_cnt",               :default => 3
    t.string   "state_running_timestamp"
    t.string   "disk_usage"
    t.string   "application_id"
  end

  add_index "instance_status", ["app_name", "organization", "space"], :name => "index_instance_status_on_app_name_and_organization_and_space"
  add_index "instance_status", ["host"], :name => "host"
  add_index "instance_status", ["host"], :name => "index_instance_status_on_host"
  add_index "instance_status", ["instance_id"], :name => "index_instance_status_on_instance_id"
  add_index "instance_status", ["instance_id"], :name => "index_name"
  add_index "instance_status", ["instance_id"], :name => "instance_id", :length => {"instance_id"=>"50"}
  add_index "instance_status", ["warden_handle"], :name => "index_instance_status_on_warden_handle"
  add_index "instance_status", ["warden_handle"], :name => "warden_handle"

  create_table "log_monitor_alarm", :force => true do |t|
    t.string   "raw_key"
    t.string   "name"
    t.string   "max_alert_times"
    t.string   "remind_interval_second"
    t.string   "mail"
    t.string   "sms"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  add_index "log_monitor_alarm", ["raw_key"], :name => "index_log_monitor_alarm_on_raw_key"

  create_table "log_monitor_item", :force => true do |t|
    t.string   "raw_key"
    t.string   "item_name_prefix"
    t.string   "cycle"
    t.string   "match_str"
    t.integer  "threshold"
    t.string   "filter_str"
    t.string   "item_key"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "log_monitor_item", ["raw_key", "item_key"], :name => "index_log_monitor_item_on_raw_key_and_item_key"

  create_table "log_monitor_raw", :force => true do |t|
    t.string   "app_key"
    t.string   "name"
    t.string   "cycle"
    t.string   "method"
    t.string   "target"
    t.string   "params"
    t.string   "log_filepath"
    t.string   "raw_key"
    t.string   "limit_rate"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "log_monitor_raw", ["app_key", "raw_key"], :name => "index_log_monitor_raw_on_app_key_and_raw_key"

  create_table "log_monitor_rule", :force => true do |t|
    t.string   "item_key"
    t.string   "name"
    t.string   "compare"
    t.string   "threshold"
    t.string   "filter"
    t.string   "alert"
    t.string   "disable_time"
    t.string   "rule_key"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "log_monitor_rule", ["item_key", "rule_key"], :name => "index_log_monitor_rule_on_item_key_and_rule_key"

  create_table "proc_monitor_alarm", :force => true do |t|
    t.string   "raw_key"
    t.string   "name"
    t.string   "max_alert_times"
    t.string   "remind_interval_second"
    t.string   "mail"
    t.string   "sms"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  add_index "proc_monitor_alarm", ["raw_key"], :name => "index_proc_monitor_alarm_on_raw_key"

  create_table "proc_monitor_raw", :force => true do |t|
    t.string   "app_key"
    t.string   "name"
    t.string   "cycle"
    t.string   "method"
    t.string   "target"
    t.string   "params"
    t.string   "raw_key"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "proc_monitor_raw", ["app_key", "raw_key"], :name => "index_proc_monitor_raw_on_app_key_and_raw_key"

  create_table "proc_monitor_rule", :force => true do |t|
    t.string   "raw_key"
    t.string   "name"
    t.string   "monitor_item"
    t.string   "compare"
    t.string   "threshold"
    t.string   "filter"
    t.string   "alert"
    t.string   "disable_time"
    t.string   "rule_key"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "proc_monitor_rule", ["raw_key", "rule_key"], :name => "index_proc_monitor_rule_on_raw_key_and_rule_key"

  create_table "user_defined_monitor_alarm", :force => true do |t|
    t.string   "raw_key"
    t.string   "name"
    t.string   "max_alert_times"
    t.string   "remind_interval_second"
    t.string   "mail"
    t.string   "sms"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  add_index "user_defined_monitor_alarm", ["raw_key"], :name => "index_user_defined_monitor_alarm_on_raw_key"

  create_table "user_defined_monitor_raw", :force => true do |t|
    t.string   "app_key"
    t.string   "name"
    t.string   "cycle"
    t.string   "method"
    t.string   "target"
    t.string   "raw_key"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "user_defined_monitor_raw", ["app_key", "raw_key"], :name => "index_user_defined_monitor_raw_on_app_key_and_raw_key"

  create_table "user_defined_monitor_rule", :force => true do |t|
    t.string   "raw_key"
    t.string   "name"
    t.string   "monitor_item"
    t.string   "compare"
    t.string   "threshold"
    t.string   "filter"
    t.string   "alert"
    t.string   "disable_time"
    t.string   "rule_key"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "user_defined_monitor_rule", ["raw_key", "rule_key"], :name => "index_user_defined_monitor_rule_on_raw_key_and_rule_key"

end
