class AddFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    # Profile
    add_column :users, :name,   :string, null: false, default: ""
    add_column :users, :role,   :string, null: false, default: "student"
    add_column :users, :locale, :string, null: false, default: "es"

    # Demographics
    add_column :users, :birthday, :date
    add_column :users, :country,  :string

    # GDPR
    add_column :users, :discarded_at,        :datetime
    add_column :users, :deletion_requested_at, :datetime
    add_column :users, :privacy_accepted_at, :datetime

    # Contact — encrypted in model
    add_column :users, :phone,    :string
    add_column :users, :whatsapp, :string

    # Minor
    add_column :users, :is_minor,         :boolean, null: false, default: false
    add_column :users, :guardian_name,    :string
    add_column :users, :guardian_email,   :string
    add_column :users, :guardian_phone,   :string
    add_column :users, :guardian_whatsapp, :string

    # Telegram
    add_column :users, :telegram_chat_id,   :string
    add_column :users, :telegram_link_token, :string

    # Notification preferences
    add_column :users, :notification_email,    :boolean, null: false, default: true
    add_column :users, :notification_telegram, :boolean, null: false, default: false

    # Payments
    add_column :users, :stripe_customer_id, :string

    add_index :users, :discarded_at
    add_index :users, :deletion_requested_at

    add_check_constraint :users, "role IN ('super_admin', 'student')", name: "valid_role"
  end
end
