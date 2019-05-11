class Clearstream

  def self.link_clearstream_msg_to_message(message_id, clearstream_msg_id)
    clearstream_msg = ClearstreamMsg.find_by(id: clearstream_msg_id)
    if clearstream_msg.nil?
      log_error("Unable to find clearstream_msg (#{clearstream_msg_id}). Did not link message (#{message_id})")
      return false
    end
    message = Message.find_by(id: message_id)
    if clearstream_msg.nil?
      log_error("Unable to find message (#{message_id}). Did not link clearstream_msg (#{clearstream_msg_id})")
      return false
    end
    message.clearstream_msg_id = clearstream_msg_id
  end

  def self.send(message_vo)
    # Populate and sanitize data
    data = ClearstreamSmsVo.new(
        receiver_email: message_vo.receiver_email,
        sms_message: message_vo.sms_message
    ).get()

    clearstream_msg = ClearstreamMsg.create!(sent_to_clearstream: Time.now,
                                          sms_json: data,
                                          clearstream_response: nil)

    cs_client = ClearstreamClient::MessageClient.new({data: data, resource: 'messages'})
    response = cs_client.create

    clearstream_msg.sms_json = response.to_json
    clearstream_msg.got_response_at = Time.now
    clearstream_msg.clearstream_response = response['data']['status']

    if clearstream_msg.save! && self.link_clearstream_msg_to_message(message_vo.message_id,  clearstream_msg.id)
      return ReturnVo.new({value: return_accepted(clearstream_msg), error: nil})
    else
      err = clearstream_msg.errors || "Error for clearstream_id (#{clearstream_id})"
      return ReturnVo.new({value: nil, error: error_json = return_error(err, :unprocessable_entity)})
    end
  rescue StandardError => err
    msg = "send_via_clearstream: #{err.message}"
    log_error(msg)
    return ReturnVo.new({value: nil, error: error_json = return_error(msg, :unprocessable_entity)})
  end
end
