class Notification < ApplicationRecord
  belongs_to :user, strict_loading: false
  belongs_to :notifiable, polymorphic: true

  serialize :i18n_vars, coder: JSON

  scope :unread, -> { where(read_at: nil) }

  after_create_commit -> { broadcast_prepend_to user, target: "notifications" }
  after_create_commit -> { NotificationJob.perform_later(self) }

  def title
    title_key ? I18n.t(title_key, **render_vars, locale: user.locale) : self[:title]
  end

  def body
    body_key ? I18n.t(body_key, **render_vars, locale: user.locale) : self[:body]
  end

  def mark_read!
    return if read_at?
    update!(read_at: Time.current)
  end

  private
    def render_vars
      vars = (i18n_vars || {}).symbolize_keys
      if vars[:status_code]
        vars[:status] = I18n.t("requests.status.#{vars.delete(:status_code)}", locale: user.locale)
      end
      vars
    end
end
