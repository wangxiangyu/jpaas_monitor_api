class AddTableDomainMonitorRaw < ActiveRecord::Migration
    def change
        create_table :domain_monitor_raw do |t|
            t.string :app_key
            t.string :name
            t.string :domain
            t.timestamps
        end
    end
end
