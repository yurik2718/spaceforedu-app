class MessagesController < ApplicationController
  before_action :set_conversation

  def create
    @message = @conversation.messages.new(message_params.merge(user: Current.user))
    authorize @message

    if @message.save
      respond_to do |format|
        format.turbo_stream { head :no_content }
        format.html { redirect_to @conversation }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("message_form",
            partial: "messages/form",
            locals: { conversation: @conversation, message: @message }),
            status: :unprocessable_entity
        end
        format.html { redirect_to @conversation, alert: @message.errors.full_messages.to_sentence }
      end
    end
  end

  private

    def set_conversation
      @conversation = Conversation.includes(homologation_request: :user).find(params[:conversation_id])
    end

    def message_params
      params.require(:message).permit(:body)
    end
end
