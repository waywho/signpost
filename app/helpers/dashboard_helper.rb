module DashboardHelper
  def error_component(error_message)
    return unless error_message

    content_tag(:div, class: "flex items-center gap-half") do
      safe_join([ content_tag(:i, class: "ph ph-warning"),
        content_tag(:span, error_message, class: "text-sm") ])
    end
  end
end
