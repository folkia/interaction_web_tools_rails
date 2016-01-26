window.Chat = class Chat
  @EVENTS_PATH: 'interaction_web_tools/events'
  @CHAT_BODY: '.chat-body'
  @CHAT_CLOSE: '.chat-stop'
  @MESSAGES_DIV: '.chat-messages'

  constructor: ->
    @started = false

  init: ->
    @started = true
    @pollMessages()

  stop: ->
    @started = false
    $(@constructor.CHAT_BODY).hide()
    $(@constructor.CHAT_CLOSE).hide()

  pollMessages: ->
    $.get Chat.EVENTS_PATH, (data) ->
      InteractionWebTools.chat.renderMessages data.events

      $.each data.events, (index, event) ->
        if (event.type == 'participantStateChanged' and
            event.state == 'disconnected')
          return InteractionWebTools.chat.started = false

      if InteractionWebTools.chat.started
        setTimeout InteractionWebTools.chat.pollMessages, 1000

  sendMessage: (message) ->
    return false unless message
    return @notifyConversationEnd() unless @started
    that = @
    $.post @constructor.EVENTS_PATH, { event: { content: message } }, (data) ->
      that.renderMessages data.events

  renderMessages: (messages) ->
    return false unless @started
    $(@constructor.CHAT_BODY).show()
    $(@constructor.CHAT_CLOSE).show()
    messages = $.grep messages, (el) -> el.type == 'text'
    messagesDiv = $(@constructor.MESSAGES_DIV)
    $.each messages, (index, message) ->
      InteractionWebTools.chat.displayMessage message
    messagesDiv.scrollTop messagesDiv[0].scrollHeight if messages.length

  notifyConversationEnd: ->
    # TODO: extract message content to I18n
    # TODO: add I18n.js
    @displayMessage
      participant_type: 'system'
      content: 'Agent has left the conversation. Please call back'

  displayMessage: (message) ->
    $(@constructor.MESSAGES_DIV).append(
      "<div class='message-#{message.participant_type.toLowerCase()}'>
       #{message.content}
       </div>"
    )
