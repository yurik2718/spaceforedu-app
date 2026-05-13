class UserAnonymizationJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user&.deletion_requested_at?

    user.anonymize!
  end
end
