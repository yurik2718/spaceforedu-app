class EncryptGuardianContactFields < ActiveRecord::Migration[8.1]
  # guardian_name and guardian_email are now declared with `encrypts` in User model.
  # This migration re-encrypts any existing plain-text values so they are stored
  # in the same format as all other encrypted PII fields (phone, passport, etc.).
  def up
    ActiveRecord::Encryption.config.support_unencrypted_data = true

    User.find_each do |user|
      next if user[:guardian_email].blank? && user[:guardian_name].blank?
      user.encrypt
    end
  ensure
    ActiveRecord::Encryption.config.support_unencrypted_data = false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
