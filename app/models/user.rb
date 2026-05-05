class User < ApplicationRecord
  has_secure_password
  has_many :sessions,               dependent: :destroy
  has_many :homologation_requests,  dependent: :destroy
  has_many :messages,               dependent: :destroy
  has_many :notifications,          dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  attribute :privacy_accepted, :boolean

  validates :email_address, presence: true, uniqueness: true
  validates :name,          presence: true

  encrypts :phone, :whatsapp, :guardian_phone, :guardian_whatsapp, :identity_card, :passport

  scope :kept, -> { where(discarded_at: nil) }

  def super_admin? = role == "super_admin"
  def student?     = role == "student"
  def has_passport? = passport.present?

  def initials
    name.split.first(2).map { _1[0].upcase }.join.presence || email_address[0].upcase
  end

  def notify(notifiable:, title_key:, body_key:, **vars)
    I18n.with_locale(locale) do
      notifications.create!(
        notifiable: notifiable,
        title:      I18n.t(title_key, **vars),
        body:       I18n.t(body_key,  **vars)
      )
    end
  end
end
