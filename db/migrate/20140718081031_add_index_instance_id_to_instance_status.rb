class AddIndexInstanceIdToInstanceStatus < ActiveRecord::Migration
    def change
        add_index(:instance_status, :instance_id)
    end
end
