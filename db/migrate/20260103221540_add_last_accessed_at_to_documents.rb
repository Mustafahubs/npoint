class AddLastAccessedAtToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :last_accessed_at, :datetime
  end
end
