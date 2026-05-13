class HealthChecksController < ActionController::Base
  def db
    ActiveRecord::Base.connection.execute("SELECT 1")
    head :ok
  rescue StandardError
    head :service_unavailable
  end

  def queue
    if SolidQueue::Process.where("last_heartbeat_at > ?", 1.minute.ago).any?
      head :ok
    else
      head :service_unavailable
    end
  rescue StandardError
    head :service_unavailable
  end
end
