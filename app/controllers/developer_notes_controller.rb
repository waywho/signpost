class DeveloperNotesController < ApplicationController
  before_action :set_developer

  def create
    @note = @developer.developer_notes.build(note_params)
    if @note.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @developer }
      end
    else
      redirect_to @developer
    end
  end

  private

  def set_developer
    @developer = Developer.find(params[:developer_id])
  end

  def note_params
    params.require(:developer_note).permit(:content, :note_type)
  end
end
