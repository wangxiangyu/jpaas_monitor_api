class AddIndexHostWardenHandleToInstanceStatus < ActiveRecord::Migration
    def change
        add_index(:instance_status, :host)
        add_index(:instance_status, :warden_handle)
    end
end
