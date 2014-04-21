class AddRawKeyToDomainMonitorRaw < ActiveRecord::Migration
    def change
        change_table :domain_monitor_raw do |t|
            t.string :raw_key
        end
    end
end

