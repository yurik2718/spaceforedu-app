# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_26_080005) do
  create_table "conversations", force: :cascade do |t|
    t.datetime "admin_last_read_at"
    t.datetime "created_at", null: false
    t.integer "homologation_request_id", null: false
    t.datetime "last_message_at"
    t.datetime "student_last_read_at"
    t.datetime "updated_at", null: false
    t.index ["homologation_request_id"], name: "index_conversations_on_homologation_request_id", unique: true
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
  end

  create_table "homologation_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "discarded_at"
    t.text "document_checklist", default: "{}"
    t.string "education_system"
    t.string "identity_card"
    t.string "language_certificate"
    t.string "language_knowledge"
    t.string "passport"
    t.decimal "payment_amount", precision: 10, scale: 2
    t.datetime "payment_confirmed_at"
    t.integer "payment_confirmed_by"
    t.text "pipeline_notes"
    t.string "pipeline_stage"
    t.boolean "privacy_accepted", default: false, null: false
    t.string "service_type", null: false
    t.string "status", default: "draft", null: false
    t.datetime "status_changed_at"
    t.integer "status_changed_by"
    t.string "stripe_payment_intent_id"
    t.string "studies_finished"
    t.string "studies_spain"
    t.string "study_type_spain"
    t.string "subject", null: false
    t.string "university"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "year"
    t.index ["discarded_at"], name: "index_homologation_requests_on_discarded_at"
    t.index ["pipeline_stage"], name: "index_homologation_requests_on_pipeline_stage"
    t.index ["status"], name: "index_homologation_requests_on_status"
    t.index ["updated_at"], name: "index_homologation_requests_on_updated_at"
    t.index ["user_id", "status"], name: "index_homologation_requests_on_user_id_and_status"
    t.index ["user_id"], name: "index_homologation_requests_on_user_id"
    t.check_constraint "status IN ('draft','submitted','in_review','awaiting_reply','awaiting_payment','payment_confirmed','in_progress','resolved','closed')", name: "valid_status"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "emailed_at"
    t.integer "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.datetime "read_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "read_at"], name: "index_notifications_on_user_id_and_read_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.date "birthday"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "deletion_requested_at"
    t.datetime "discarded_at"
    t.string "email_address", null: false
    t.string "guardian_email"
    t.string "guardian_name"
    t.string "guardian_phone"
    t.string "guardian_whatsapp"
    t.boolean "is_minor", default: false, null: false
    t.string "locale", default: "es", null: false
    t.string "name", default: "", null: false
    t.boolean "notification_email", default: true, null: false
    t.boolean "notification_telegram", default: false, null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.datetime "privacy_accepted_at"
    t.string "role", default: "student", null: false
    t.string "stripe_customer_id"
    t.string "telegram_chat_id"
    t.string "telegram_link_token"
    t.datetime "updated_at", null: false
    t.string "whatsapp"
    t.index ["deletion_requested_at"], name: "index_users_on_deletion_requested_at"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.check_constraint "role IN ('super_admin', 'student')", name: "valid_role"
  end

  add_foreign_key "conversations", "homologation_requests"
  add_foreign_key "homologation_requests", "users"
  add_foreign_key "homologation_requests", "users", column: "payment_confirmed_by"
  add_foreign_key "homologation_requests", "users", column: "status_changed_by"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "sessions", "users"
end
