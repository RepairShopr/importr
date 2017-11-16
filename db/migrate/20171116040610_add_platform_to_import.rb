class AddPlatformToImport < ActiveRecord::Migration
  def change
    add_column :imports, :platform, :string
  end
end
