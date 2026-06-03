class ApplicationFormBuilder < ActionView::Helpers::FormBuilder
  INPUT_HELPERS = %i[
    text_field password_field email_field url_field telephone_field phone_field
    number_field search_field color_field date_field datetime_field
    datetime_local_field month_field time_field week_field text_area file_field
  ].freeze

  INPUT_HELPERS.each do |helper|
    define_method(helper) do |method, options = {}|
      super(method, merge_class(options, "input"))
    end
  end

  def select(method, choices = nil, options = {}, html_options = {}, &block)
    super(method, choices, options, merge_class(html_options, "input"), &block)
  end

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    super(method, collection, value_method, text_method, options, merge_class(html_options, "input"))
  end

  def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
    super(method, merge_class(options, "input"), checked_value, unchecked_value)
  end

  private

  def merge_class(options, klass)
    classes = ([ klass ] + options[:class].to_s.split).uniq
    options.merge(class: classes.join(" "))
  end
end
