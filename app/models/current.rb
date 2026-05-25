class Current < ActiveSupport::CurrentAttributes
  attribute :setting_cache

  def setting_cache
    super || self.setting_cache = {}
  end
end
