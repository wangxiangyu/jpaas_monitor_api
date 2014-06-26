class AddMgrPortToInstanceStatus < ActiveRecord::Migration
  def change
      change_table :instance_status do |t|
          t.string :instance_mgr_host_port
      end
  end
end
