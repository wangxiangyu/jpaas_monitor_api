class AddTableHttpUserDefinedMonitorRaw < ActiveRecord::Migration
    def change
        create_table :http_user_defined_monitor_raw do |t|
            t.string :app_key
            t.string :name
            t.string :cycle
            t.string :method
            t.string :target
            t.string :raw_key
            t.string :req_type
            t.string :port
            t.timestamps
        end
    end
end
