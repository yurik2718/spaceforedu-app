module ApplicationHelper
  def flash_alert_class(type)
    case type.to_sym
    when :notice, :success then "alert-success"
    when :alert, :error    then "alert-error"
    when :warning          then "alert-warning"
    else                        "alert-info"
    end
  end

  def status_badge_class(status)
    case status
    when "draft"                        then "badge-neutral"
    when "submitted", "in_review"       then "badge-info"
    when "awaiting_reply",
         "awaiting_payment"             then "badge-warning"
    when "payment_confirmed", "resolved" then "badge-success"
    when "in_progress"                  then "badge-primary"
    when "closed"                       then "badge-neutral"
    else                                     "badge-neutral"
    end
  end

  def nav_link_class(section)
    current_page_section?(section) ? "active" : ""
  end

  private
    def current_page_section?(section)
      request.path.start_with?("/#{section}")
    end
end
