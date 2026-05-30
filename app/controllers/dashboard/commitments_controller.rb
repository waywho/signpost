class Dashboard::CommitmentsController < ApplicationController
  def show
    @due = Commitment.due_soon.where("due_date >= ?", Date.current)
    @overdue = Commitment.pending.where("due_date < ?", Date.current).order(:due_date)
  end
end
