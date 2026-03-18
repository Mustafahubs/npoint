class AddFlaggedMaliciousToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :flagged_malicious, :boolean, default: false, null: false
  end
end
