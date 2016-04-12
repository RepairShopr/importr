class IndexImportOnUuid < ActiveRecord::Migration
  def change
    add_index :imports, :uuid
  end
end
