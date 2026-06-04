module ApplicationHelper
  def loader_component(label: nil, hide: false)
    loading_label = "Loading #{label}".strip
    content_tag(:div, class: "loader gap-2 #{'hidden' if hide}") do
      safe_join([content_tag(:i, nil, class: "ph ph-spinner text-xl animate-spin"),
        content_tag(:p, "#{loading_label}…", class: "text-sm")])
    end
  end

  def loader_card(label: nil, hide: false)
    content_tag(:div, loader_component(label:, hide: false), class: "loaderCard card relative mbe-2 #{'hidden' if hide}")
  end
end
