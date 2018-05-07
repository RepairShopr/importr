class AddErrorHandlingToImport < ActiveRecord::Migration
  def change
    add_column :imports, :errors_to_allow, :integer
    add_column :imports, :match_on_asset_serial, :boolean, null: false, default: false
  end
end
