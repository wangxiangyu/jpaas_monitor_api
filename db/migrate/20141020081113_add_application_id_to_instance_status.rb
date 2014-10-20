class AddApplicationIdToInstanceStatus < ActiveRecord::Migration
  def change
      change_table :instance_status do |t|
          t.string :application_id
      end
  end
end
