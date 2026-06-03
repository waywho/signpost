class ActionItem < ApplicationRecord
  belongs_to :slack_topic
  belongs_to :slack_thread
  belongs_to :suggested_developer, class_name: "Developer", optional: true
  belongs_to :delegation, optional: true

  enum :status, { pending: 0, actioned: 1, dismissed: 2, ignored: 3, resolved: 4 }
  enum :action_type, { create_ticket: 0, delegate: 1, acknowledge: 2, discuss: 3, ignore: 4 }

  validates :priority, presence: true
  validates :slack_topic_id, uniqueness: true

  scope :actionable, -> { pending.where(action_type: [ :create_ticket, :delegate ]) }
  scope :discussions, -> { pending.where(action_type: :discuss) }
  scope :acknowledgements, -> { pending.where(action_type: :acknowledge) }
  scope :by_priority, -> { order(:priority) }
end
