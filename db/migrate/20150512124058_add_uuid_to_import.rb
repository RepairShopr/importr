class AddUuidToImport < ActiveRecord::Migration
  def change
    add_column :imports, :uuid, :string
  end
end
