class EncryptedSetting < ApplicationRecord
  self.primary_key = [:scope, :key]

  encrypts :value

  validates :scope, :key, :value, presence: true

  def self.get(scope, key)
    find_by(scope: scope, key: key)&.value
  rescue ActiveRecord::Encryption::Errors::Decryption
    nil
  end

  def self.set(scope, key, value)
    record = find_or_initialize_by(scope: scope, key: key)
    record.update!(value: value)
    record
  end
end
