class Commitments::CompletionsController < ApplicationController
  def create
    @commitment = Commitment.find(params[:commitment_id])
    @commitment.update!(done: true, done_at: Time.current)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to commitments_path }
    end
  end
end
