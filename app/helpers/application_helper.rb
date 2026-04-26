module ApplicationHelper
  def flash_alert_class(type)
    case type.to_sym
    when :notice, :success then "alert-success"
    when :alert, :error    then "alert-error"
    when :warning          then "alert-warning"
    else                        "alert-info"
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
