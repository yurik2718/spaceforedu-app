class AddEncryptedIdAndPassportToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :identity_card, :string
    add_column :users, :passport, :string
  end
end
