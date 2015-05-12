class AddSubdomainToImport < ActiveRecord::Migration
  def change
    add_column :imports, :subdomain, :string
  end
end
