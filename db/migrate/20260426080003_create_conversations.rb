class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :homologation_request, null: false, foreign_key: true, index: { unique: true }
      t.datetime :last_message_at
      t.datetime :student_last_read_at
      t.datetime :admin_last_read_at
      t.timestamps
    end

    add_index :conversations, :last_message_at
  end
end
