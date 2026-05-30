class Developers::PrepsController < ApplicationController
  def create
    @developer = Developer.find(params[:developer_id])
    @briefing = OneOnePrepService.new.prep(@developer)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @developer }
    end
  rescue => e
    @error = e.message
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @developer, alert: "Prep failed: #{e.message}" }
    end
  end
end
