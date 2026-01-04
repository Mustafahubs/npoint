class AddIndexToDocumentsLastAccessedAt < ActiveRecord::Migration[8.1]
  def change
    add_index :documents, :last_accessed_at
  end
end
