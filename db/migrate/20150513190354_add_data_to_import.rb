class AddDataToImport < ActiveRecord::Migration
  def change
    add_column :imports, :data, :text
  end
end
