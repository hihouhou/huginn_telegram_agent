module Agents
  class TelegrambisAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule 'every_12h'

    description do
      <<-MD
      The Telegrambis Agent complements the very good telegram agent, it adds other interactions with the Telegram api.

      The `type` can be like pinned a message for example.

      `chat_id` for the target channel.

      `message_id` is needed to select the message for possible interactions like pinned message.

      `debug` is used for verbose mode.

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:

          {
            "ok": true,
            "result": true
          }
    MD

    def default_options
      {
        'chat_id' => '',
        'message_id' => '',
        'question' => '',
        'options' => '',
        'is_anonymous' => 'false',
        'poll_type' => 'regular',
        'debug' => 'false',
        'emit_events' => 'true',
        'expected_receive_period_in_days' => '7',
        'token' => ''
      }
    end

    form_configurable :chat_id, type: :string
    form_configurable :message_id, type: :string
    form_configurable :question, type: :string
    form_configurable :options, type: :string
    form_configurable :is_anonymous, type: :boolean
    form_configurable :poll_type, type: :string
    form_configurable :debug, type: :boolean
    form_configurable :emit_events, type: :boolean
    form_configurable :token, type: :string
    form_configurable :expected_receive_period_in_days, type: :string
    form_configurable :type, type: :array, values: ['pin_chat_message', 'unpin_chat_message', 'send_poll', 'stop_poll']

    def validate_options
      errors.add(:base, "type has invalid value: should be 'pin_chat_message', 'unpin_chat_message', 'send_poll', 'stop_poll'") if interpolated['type'].present? && !%w(pin_chat_message unpin_chat_message send_poll stop_poll).include?(interpolated['type'])

      unless options['chat_id'].present? || !['pin_chat_message' 'unpin_chat_message' 'send_poll' 'stop_poll'].include?(options['type'])
        errors.add(:base, "chat_id is a required field")
      end

      unless options['message_id'].present? || !['pin_chat_message' 'unpin_chat_message' 'stop_poll'].include?(options['type'])
        errors.add(:base, "message_id is a required field")
      end

      unless options['question'].present? || !['send_poll'].include?(options['type'])
        errors.add(:base, "question is a required field")
      end

      unless options['options'].present? || !['send_poll'].include?(options['type'])
        errors.add(:base, "options is a required field")
      end

      unless options['is_anonymous'].present? || !['send_poll'].include?(options['type'])
        errors.add(:base, "is_anonymous is a required field")
      end

      unless options['poll_type'].present? || !['send_poll'].include?(options['type'])
        errors.add(:base, "poll_type is a required field")
      end

      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      if options.has_key?('emit_events') && boolify(options['emit_events']).nil?
        errors.add(:base, "if provided, emit_events must be true or false")
      end

      unless options['token'].present?
        errors.add(:base, "token is a required field")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|
        interpolate_with(event) do
          log event
          trigger_action
        end
      end
    end

    def check
      trigger_action
    end

    private

    def log_curl_output(code,body)

      log "request status : #{code}"

      if interpolated['debug'] == 'true'
        log "body"
        log body
      end

    end

    def pin_chat_message

      uri = URI.parse("https://api.telegram.org/bot#{interpolated['token']}/pinChatMessage")
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request.body = JSON.dump({
        "chat_id" => interpolated['chat_id'],
        "message_id" => interpolated['message_id']
      })

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      log_curl_output(response.code,response.body)

      payload = JSON.parse(response.body)

      if interpolated['emit_events'] == 'true'
        payload['action'] = 'pinChatMessage'
        payload['chat_id'] = interpolated['chat_id']
        payload['message_id'] = interpolated['message_id']
        create_event payload: payload
      end

    end

    def unpin_chat_message

      uri = URI.parse("https://api.telegram.org/bot#{interpolated['token']}/unpinChatMessage")
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request.body = JSON.dump({
        "chat_id" => interpolated['chat_id'],
        "message_id" => interpolated['message_id']
      })

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      log_curl_output(response.code,response.body)

      payload = JSON.parse(response.body)

      if interpolated['emit_events'] == 'true'
        payload['action'] = 'unpinChatMessage'
        payload['chat_id'] = interpolated['chat_id']
        payload['message_id'] = interpolated['message_id']
        create_event payload: payload
      end

    end
#
#    def set_message_reaction
#
#      log JSON.dump({
#        "chat_id" => interpolated['chat_id'],
#        "message_id" => interpolated['message_id'],
#        "reaction" => [
#          {
#            "type" => "emoji",
#            "emoji" => interpolated['reaction']
#          }
#        ]
#      })
#
#
#      uri = URI.parse("https://api.telegram.org/bot#{interpolated['token']}/setMessageReaction")
#      request = Net::HTTP::Post.new(uri)
#      request.content_type = "application/json"
#      request.body = JSON.dump({
#        "chat_id" => interpolated['chat_id'],
#        "message_id" => interpolated['message_id'],
#        "reaction" => [
#          {
#            "type" => "emoji",
#            "emoji" => interpolated['reaction']
#          }
#        ]
#      })
#
#      req_options = {
#        use_ssl: uri.scheme == "https",
#      }
#
#      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
#        http.request(request)
#      end
#
#      log_curl_output(response.code,response.body)
#
#      payload = JSON.parse(response.body)
#
#      if interpolated['emit_events'] == 'true'
#        payload['action'] = 'setMessageReaction'
#        payload['chat_id'] = interpolated['chat_id']
#        payload['message_id'] = interpolated['message_id']
#        create_event payload: payload
#      end
#
#    end

    def send_poll

      uri = URI.parse("https://api.telegram.org/bot#{interpolated['token']}/sendPoll")
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request.body = JSON.dump({
        "chat_id" => interpolated['chat_id'],
        "question" => interpolated['question'],
        "options" => JSON.parse(interpolated['options']),
        "is_anonymous" => interpolated['is_anonymous'],
        "type" => interpolated['poll_type'],
      })

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      log_curl_output(response.code,response.body)

      payload = JSON.parse(response.body)

      if interpolated['emit_events'] == 'true'
        payload['action'] = 'sendPoll'
        payload['chat_id'] = interpolated['chat_id']
        create_event payload: payload
      end

    end

    def stop_poll

      uri = URI.parse("https://api.telegram.org/bot#{interpolated['token']}/stopPoll")
      request = Net::HTTP::Post.new(uri)
      request.content_type = "application/json"
      request.body = JSON.dump({
        "chat_id" => interpolated['chat_id'],
        "message_id" => interpolated['message_id']
      })

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      log_curl_output(response.code,response.body)

      payload = JSON.parse(response.body)

      if interpolated['emit_events'] == 'true'
        payload['action'] = 'stopPoll'
        payload['chat_id'] = interpolated['chat_id']
        payload['message_id'] = interpolated['message_id']
        create_event payload: payload
      end

    end

    def trigger_action

      case interpolated['type']
      when "pin_chat_message"
        pin_chat_message()
      when "unpin_chat_message"
        unpin_chat_message()
#      when "set_message_reaction"
#        set_message_reaction()
      when "send_poll"
        send_poll()
      when "stop_poll"
        stop_poll()
      else
        log "Error: type has an invalid value (#{interpolated['type']})"
      end
    end
  end
end
