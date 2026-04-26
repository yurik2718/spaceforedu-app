class CreateHomologationRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :homologation_requests do |t|
      t.references :user, null: false, foreign_key: true

      # Core
      t.string  :subject,      null: false
      t.text    :description
      t.string  :service_type, null: false
      t.string  :status,       null: false, default: "draft"
      t.boolean :privacy_accepted, null: false, default: false

      # Education details
      t.string  :education_system
      t.string  :university
      t.integer :year
      t.string  :studies_finished
      t.string  :studies_spain
      t.string  :study_type_spain
      t.string  :language_certificate
      t.string  :language_knowledge
      t.string  :identity_card
      t.string  :passport
      t.text    :document_checklist, default: "{}"

      # Pipeline (admin internal)
      t.string  :pipeline_stage
      t.text    :pipeline_notes

      # Payment
      t.decimal  :payment_amount, precision: 10, scale: 2
      t.datetime :payment_confirmed_at
      t.integer  :payment_confirmed_by
      t.string   :stripe_payment_intent_id

      # Status tracking
      t.datetime :status_changed_at
      t.integer  :status_changed_by

      # Soft delete
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :homologation_requests, :status
    add_index :homologation_requests, :discarded_at
    add_index :homologation_requests, :pipeline_stage
    add_index :homologation_requests, :updated_at
    add_index :homologation_requests, [ :user_id, :status ]

    add_foreign_key :homologation_requests, :users, column: :payment_confirmed_by
    add_foreign_key :homologation_requests, :users, column: :status_changed_by

    add_check_constraint :homologation_requests,
      "status IN ('draft','submitted','in_review','awaiting_reply','awaiting_payment','payment_confirmed','in_progress','resolved','closed')",
      name: "valid_status"
  end
end
