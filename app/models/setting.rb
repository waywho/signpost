class Setting < ApplicationRecord
  self.primary_key = [:scope, :key]

  validates :scope, :key, :value, presence: true

  def self.get(scope, key, default: nil)
    cache_key = "#{scope}/#{key}"
    unless Current.setting_cache.key?(cache_key)
      Current.setting_cache[cache_key] = find_by(scope:, key:)&.value
    end
    Current.setting_cache[cache_key] || default
  end

  def self.set(scope, key, value)
    Current.setting_cache.delete("#{scope}/#{key}")
    upsert({ scope:, key:, value:, updated_at: Time.current }, unique_by: [:scope, :key])
  end
end
