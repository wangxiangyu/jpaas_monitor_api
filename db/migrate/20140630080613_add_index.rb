class AddIndex < ActiveRecord::Migration
    def change
        add_index(:app_bns, :app_key)
        add_index(:bns_instance_register, :app_key)
        add_index(:dea_list, :uuid)
        add_index(:domain_monitor_alarm, :raw_key)
        add_index(:domain_monitor_item, [:raw_key,:item_key])
        add_index(:domain_monitor_raw, [:app_key,:raw_key])
        add_index(:domain_monitor_rule, [:item_key,:rule_key])
        add_index(:instance_status, [:app_name,:organization,:space])
        add_index(:log_monitor_alarm, :raw_key)
        add_index(:log_monitor_item, [:raw_key,:item_key])
        add_index(:log_monitor_raw, [:app_key,:raw_key])
        add_index(:log_monitor_rule, [:item_key,:rule_key])
        add_index(:proc_monitor_alarm, :raw_key)
        add_index(:proc_monitor_raw, [:app_key,:raw_key])
        add_index(:proc_monitor_rule, [:raw_key,:rule_key])
        add_index(:user_defined_monitor_alarm, :raw_key)
        add_index(:user_defined_monitor_raw, [:app_key,:raw_key])
        add_index(:user_defined_monitor_rule, [:raw_key,:rule_key])
    end
end
