class CreateRequestDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :request_documents do |t|
      t.references :homologation_request, null: false, foreign_key: true
      t.string     :kind,                  null: false
      t.timestamps
    end

    add_index :request_documents, [ :homologation_request_id, :kind ], unique: true
  end
end
