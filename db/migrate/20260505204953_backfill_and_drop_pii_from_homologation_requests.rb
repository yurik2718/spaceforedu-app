class BackfillAndDropPiiFromHomologationRequests < ActiveRecord::Migration[8.1]
  def up
    say_with_time "backfilling identity_card / passport onto users" do
      User.reset_column_information
      HomologationRequest.reset_column_information

      ActiveRecord::Base.connection.exec_query(
        "SELECT user_id, identity_card, passport FROM homologation_requests " \
        "WHERE (identity_card IS NOT NULL AND identity_card != '') " \
        "   OR (passport      IS NOT NULL AND passport      != '') " \
        "ORDER BY id DESC"
      ).each do |row|
        user = User.find_by(id: row["user_id"])
        next unless user

        user.identity_card = row["identity_card"] if user.identity_card.blank? && row["identity_card"].present?
        user.passport      = row["passport"]      if user.passport.blank?      && row["passport"].present?
        user.save!(validate: false) if user.changed?
      end
    end

    remove_column :homologation_requests, :identity_card, :string
    remove_column :homologation_requests, :passport,      :string
  end

  def down
    add_column :homologation_requests, :identity_card, :string
    add_column :homologation_requests, :passport,      :string
  end
end
