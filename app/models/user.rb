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

  def initials
    name.split.first(2).map { _1[0].upcase }.join.presence || email_address[0].upcase
  end
end
