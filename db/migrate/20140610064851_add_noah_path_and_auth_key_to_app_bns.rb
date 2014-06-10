class AddNoahPathAndAuthKeyToAppBns < ActiveRecord::Migration
  def change
      change_table :app_bns do |t|
          t.string :noah_parentPath
          t.string :noah_authKey
      end
  end
end
