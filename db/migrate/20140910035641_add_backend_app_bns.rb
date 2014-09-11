class AddBackendAppBns < ActiveRecord::Migration
  def change
      change_table :app_bns do |t|
          t.string :backend
      end
  end
end
