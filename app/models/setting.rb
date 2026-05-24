class Setting < ApplicationRecord
  self.primary_key = [:scope, :key]

  validates :scope, :key, :value, presence: true

  def self.get(scope, key, default: nil)
    find_by(scope: scope, key: key)&.value || default
  end

  def self.set(scope, key, value)
    upsert({ scope: scope, key: key, value: value, updated_at: Time.current }, unique_by: [:scope, :key])
  end
end
