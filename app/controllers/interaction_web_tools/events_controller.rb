module InteractionWebTools
  class EventsController < ApplicationController
    def index
      provider_id = load_chat
      @events = poll_events(provider_id).events
    end

    def create
      provider_id = load_chat
      @events = ChatResponse.parse(client.send_message(provider_id, params[:event][:content])).events
      render 'index'
    end

    private

    def poll_events(provider_id, retry_count = 5)
      return if retry_count < 1
      poll_response = ChatResponse.parse(client.poll(provider_id))
      if poll_response.failure?
        session['interaction_web_tools']['provider_id'] = nil
        provider_id = load_chat
        return poll_events(provider_id, retry_count - 1 )
      end
      poll_response
    end

    def load_chat
      session['interaction_web_tools'] ||= {}
      provider_id = session['interaction_web_tools']['provider_id']
      unless provider_id
        provider_id = ChatResponse.parse(client.start).chat_id
        session['interaction_web_tools']['provider_id'] = provider_id
      end
      provider_id
    end

    def client
      InteractionWebTools::IninChatAdapter.new
    end

    def event_params
      params.require(:event).permit(:content).symbolize_keys
    end
  end
end
