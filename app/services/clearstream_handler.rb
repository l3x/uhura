# frozen_string_literal: true

class ClearstreamHandler < ServiceHandlerBase
  # rubocop:disable Metrics/MethodLength
  def self.send(message_vo)
    # Populate attributes required for request
    clearstream_vo = create_clearstream_msg(message_vo)
    # ClearstreamMessageWorker.perform_async(clearstream_vo)
    ClearstreamMessageJob.perform_later(clearstream_vo)

    msg = "Asynchronously sent SMS: (#{message_vo.team_name}:#{message_vo.email_subject}) "
    msg += "from (#{message_vo.manager_name}) to (#{message_vo.mobile_number})"
    log_info(msg)
    ReturnVo.new(value: return_accepted("clearstream_msg": msg), error: nil)
  rescue StandardError => e
    err_msg = get_err_msg(e)
    # Log Clearstream subscription warnings if necessary. Note Uhura does not submit create_subscriber requests.
    if err_msg&.include?('supplied subscribers is invalid') # "At least one of the supplied subscribers is invalid."
      # If the subscriber is invalid, let's assume that they've not been registered with Clearstream.io
      # So, an entity outside of Uhura should create the subscriber see that they opt in before returning to Uhura.
      action_msg = {
        "error_from_clearstream": err_msg,
        "assumed_meaning": "This receiver w/ mobile_number (#{message_vo.mobile_number}) not registered in Clearstream",
        "action": "Research whether receiver_sso_id (#{message_vo.receiver_sso_id}) is valid."
      }
      err_msg = {
        "msg": err_msg,
        "action_required:": action_msg
      }
    elsif err_msg&.include?('You must send your message to at least one subscriber')
      # Since Uhura does not submit subscription requests, this block should never be executed
      action_msg = {
        "error_from_clearstream": err_msg,
        "action": "Research status of Clearstream subscription for receiver_sso_id (#{message_vo.receiver_sso_id})"
      }
      err_msg = {
        "msg": err_msg,
        "action_required:": action_msg
      }
    end
    handle_clearstream_msg_error(err_msg, message_vo)
  end
  # rubocop:enable Metrics/MethodLength

  def self.create_clearstream_msg(message_vo)
    ClearstreamSmsVo.new(
      receiver_sso_id: message_vo.receiver_sso_id,
      team_name: message_vo.team_name,
      sms_message: message_vo.sms_message,
      message_id: message_vo.message_id
    ).vo
  end

  def self.handle_clearstream_msg_error(err_msg, message_vo)
    log_error("err_msg (#{err_msg}) - message_vo (#{message_vo})")
    # An error occurs while processing the request. Record ERROR status.
    clearstream_msg = ClearstreamMsg.create!(
      response: {
        error: err_msg
      },
      status: 'ERROR'
    )
    # Link clearstream_msg to message
    message = Message.find(message_vo.message_id)
    message.clearstream_msg = clearstream_msg
    message.save!
    ReturnVo.new_err(err_msg)
  end

  # Called from ClearstreamMessageWorker
  # rubocop:disable Metrics/AbcSize
  def self.send_msg(data)
    message_id = data[:clearstream_vo][:message_id]
    # Request Clearstream client to send message
    response = ClearstreamClient::MessageClient.new(data: data[:clearstream_vo],
                                                    resource: 'messages').send_message
    # Record Clearstream response
    clearstream_msg = ClearstreamMsg.create!(sent_to_clearstream: Time.current,
                                             response: response['data'])
    clearstream_msg.got_response_at = Time.current
    clearstream_msg.status = response['data']['status']
    clearstream_msg.clearstream_id = response['data']['id'] # <= Use clearstream_id as correlation id in webhook

    if clearstream_msg.save! && link_clearstream_msg_to_message(message_id, clearstream_msg.id)
      return ReturnVo.new_value(clearstream_msg: clearstream_msg)
    else
      return ReturnVo.new_err(clearstream_msg.errors || "Error for clearstream_id (#{clearstream_id})")
    end
  end
  # rubocop:enable Metrics/AbcSize

  def self.link_clearstream_msg_to_message(message_id, clearstream_msg_id)
    clearstream_msg = ClearstreamMsg.find_by(id: clearstream_msg_id)
    if clearstream_msg.nil?
      log_error("Unable to find clearstream_msg (#{clearstream_msg_id}). Did not link message (#{message_id})")
      return false
    end
    message = Message.find_by(id: message_id)
    if message.nil?
      log_error("Unable to find message (#{message_id}). Did not link clearstream_msg (#{clearstream_msg_id})")
      return false
    end
    message.clearstream_msg_id = clearstream_msg_id
    message.save!
  end
end
