class AddRowsToProcessToImport < ActiveRecord::Migration
  def change
    add_column :imports, :rows_to_process, :integer
  end
end
