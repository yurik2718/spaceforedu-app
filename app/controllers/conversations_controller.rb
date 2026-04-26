class ConversationsController < ApplicationController
  def show
    @conversation = Conversation.includes(homologation_request: :user).find(params[:id])
    authorize @conversation

    @conversation.mark_read_for!(Current.user)
    @messages = @conversation.messages.includes(:user).order(:created_at)
    @message  = Message.new
  end
end
