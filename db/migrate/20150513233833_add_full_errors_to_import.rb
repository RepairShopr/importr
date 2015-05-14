class AddFullErrorsToImport < ActiveRecord::Migration
  def change
    add_column :imports, :full_errors, :text
  end
end
