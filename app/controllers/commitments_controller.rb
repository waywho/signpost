class CommitmentsController < ApplicationController
  def index
    @overdue = Commitment.pending.where("due_date < ?", Date.current).order(:due_date)
    @due_soon = Commitment.due_soon.where("due_date >= ?", Date.current)
    @no_date = Commitment.pending.where(due_date: nil).order(created_at: :desc)
    @done_recent = Commitment.where(done: true).order(done_at: :desc).limit(10)
  end

  def new
    @commitment = Commitment.new
  end

  def create
    @commitment = Commitment.new(commitment_params)
    if @commitment.save
      redirect_to commitments_path, notice: "Commitment added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def done
    @commitment = Commitment.find(params[:id])
    @commitment.update!(done: true, done_at: Time.current)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to commitments_path }
    end
  end

  def destroy
    Commitment.find(params[:id]).destroy
    redirect_to commitments_path, notice: "Commitment removed.", status: :see_other
  end

  private

  def commitment_params
    params.require(:commitment).permit(:text, :stakeholder, :due_date, :source)
  end
end
