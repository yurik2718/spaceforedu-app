class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user,      null: false, foreign_key: true
      t.references :notifiable, polymorphic: true, null: false
      t.string     :title,     null: false
      t.text       :body
      t.datetime   :read_at
      t.datetime   :emailed_at
      t.timestamps
    end

    add_index :notifications, [ :user_id, :read_at ]
    add_index :notifications, [ :user_id, :created_at ]
  end
end
