class AddI18nKeysToNotifications < ActiveRecord::Migration[8.1]
  def change
    add_column :notifications, :title_key, :string
    add_column :notifications, :body_key,  :string
    add_column :notifications, :i18n_vars, :text
    change_column_null :notifications, :title, true
  end
end
