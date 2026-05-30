class Dashboard::ActiveDelegationsController < ApplicationController
  def show
    @delegations = Delegation.active.by_urgency.includes(:developer)
  end
end
