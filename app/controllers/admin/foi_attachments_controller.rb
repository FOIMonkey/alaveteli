##
# Controller to manage FoiAttachment instances
#
class Admin::FoiAttachmentsController < AdminController
  before_action :set_foi_attachment, :set_incoming_message, :set_info_request
  before_action :check_info_request

  def edit
  end

  def update
    if @foi_attachment.update(foi_attachment_params)
      @info_request.log_event(
        'edit_attachment',
        attachment_id: @foi_attachment.id,
        editor: admin_current_user,
        old_prominence: @foi_attachment.prominence_previously_was,
        prominence: @foi_attachment.prominence,
        old_prominence_reason: @foi_attachment.prominence_reason_previously_was,
        prominence_reason: @foi_attachment.prominence_reason
      )
      @info_request.expire

      flash[:notice] = 'Attachment successfully updated.'
      redirect_to edit_admin_incoming_message_path(@incoming_message)

    else
      render action: 'edit'
    end
  end

  private

  def foi_attachment_params
    params.require(:foi_attachment).permit(:prominence, :prominence_reason)
  end

  def set_foi_attachment
    @foi_attachment = FoiAttachment.find(params[:id])
  end

  def set_incoming_message
    @incoming_message = @foi_attachment&.incoming_message
  end

  def set_info_request
    @info_request = @incoming_message&.info_request
  end

  def check_info_request
    return if can? :admin, @info_request

    raise ActiveRecord::RecordNotFound
  end
end