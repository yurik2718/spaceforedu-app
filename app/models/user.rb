class User < ApplicationRecord
  has_secure_password
  has_many :sessions,               dependent: :destroy
  has_many :homologation_requests,  dependent: :destroy
  has_many :messages,               dependent: :destroy
  has_many :notifications,          dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  attribute :privacy_accepted, :boolean

  validates :email_address,   presence: true, uniqueness: true
  validates :name,            presence: true
  validates :privacy_accepted, acceptance: true, on: :create

  before_create { self.privacy_accepted_at = Time.current if privacy_accepted? }

  encrypts :phone, :whatsapp, :guardian_phone, :guardian_whatsapp, :identity_card, :passport,
           :telegram_chat_id, :telegram_link_token

  scope :kept, -> { where(discarded_at: nil) }

  def self.super_admin = kept.where(role: "super_admin").order(:id).first

  def super_admin? = role == "super_admin"
  def student?     = role == "student"
  def has_passport? = passport.present?

  def initials
    name.split.first(2).map { _1[0].upcase }.join.presence || email_address[0].upcase
  end

  def notify(notifiable:, title_key:, body_key:, **vars)
    notifications.create!(
      notifiable: notifiable,
      title_key:  title_key,
      body_key:   body_key,
      i18n_vars:  vars
    )
  end
end
