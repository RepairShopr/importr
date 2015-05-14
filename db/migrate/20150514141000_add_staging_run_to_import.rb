class AddStagingRunToImport < ActiveRecord::Migration
  def change
    add_column :imports, :staging_run, :boolean, default: false
  end
end
