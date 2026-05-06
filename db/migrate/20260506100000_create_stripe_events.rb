class CreateStripeEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :stripe_events, id: false do |t|
      t.string   :id,          null: false, primary_key: true
      t.string   :type,        null: false
      t.text     :payload,     null: false
      t.datetime :received_at, null: false
    end
  end
end
