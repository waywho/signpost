require "async"
require "async/http/endpoint"
require "async/websocket/client"
require "json"

# Slack Socket Mode listener. Opens a WebSocket via apps.connections.open
# and dispatches events_api envelopes (reaction_added, message, app_mention)
# to background jobs. Reconnects automatically on transport errors or
# server-initiated disconnects.
class SlackSocketListener
  RECONNECT_DELAY = 5

  def self.start
    mode = Setting.get("global", "slack_capture_mode", default: "both")
    unless mode.in?(%w[socket both])
      puts "Capture mode is '#{mode}', Socket Mode not enabled. Exiting."
      return
    end

    app_token = EncryptedSetting.get("credentials", "slack_app_token")
    unless app_token
      puts "Missing slack_app_token in encrypted settings. Exiting."
      return
    end

    new(app_token: app_token).run
  end

  def initialize(app_token:)
    @app_token = app_token
    @emoji = Setting.get("global", "slack_brain_emoji", default: "brain")
    @watched_ids = WatchedChannel.enabled.pluck(:channel_id).to_set
  end

  def run
    loop do
      url = open_socket_url
      listen(url)
    rescue Interrupt
      puts "Interrupt received. Shutting down Socket Mode listener."
      return
    rescue => e
      puts "Socket Mode error: #{e.class}: #{e.message}"
      sleep RECONNECT_DELAY
    end
  end

  private

  def open_socket_url
    response = Slack::Web::Client.new(token: @app_token).apps_connections_open
    raise "apps.connections.open failed: #{response['error']}" unless response["ok"]
    response["url"]
  end

  def listen(url)
    endpoint = Async::HTTP::Endpoint.parse(url)
    puts "Connecting to Slack Socket Mode..."

    Async do
      Async::WebSocket::Client.connect(endpoint) do |connection|
        while (message = connection.read)
          envelope = JSON.parse(message.buffer)
          handle(connection, envelope)
        end
      end
    end.wait
  end

  def handle(connection, envelope)
    case envelope["type"]
    when "hello"
      puts "Socket Mode connected (num_connections=#{envelope['num_connections']})"
    when "events_api"
      ack(connection, envelope)
      dispatch(envelope.dig("payload", "event"))
    when "disconnect"
      puts "Socket Mode disconnect (reason=#{envelope['reason']}). Reconnecting..."
      raise "reconnect requested"
    end
  end

  def ack(connection, envelope)
    connection.write({ envelope_id: envelope["envelope_id"] }.to_json)
    connection.flush
  end

  def dispatch(event)
    return unless event

    case event["type"]
    when "reaction_added"
      dispatch_reaction(event)
    when "message"
      dispatch_message(event)
    when "app_mention"
      SlackCaptureJob.perform_later(
        channel_id: event["channel"],
        thread_ts: event["thread_ts"] || event["ts"],
        capture_reason: "mention"
      )
    end
  end

  def dispatch_reaction(event)
    return unless event["reaction"] == @emoji

    SlackCaptureJob.perform_later(
      channel_id: event.dig("item", "channel"),
      thread_ts: event.dig("item", "ts"),
      capture_reason: "brain_emoji"
    )
  end

  def dispatch_message(event)
    return if event["subtype"]

    channel_id = event["channel"]
    thread_ts = event["thread_ts"] || event["ts"]

    if event["text"]&.include?("<@")
      SlackCaptureJob.perform_later(channel_id: channel_id, thread_ts: thread_ts, capture_reason: "mention")
      return
    end

    return unless @watched_ids.include?(channel_id)
    channel = WatchedChannel.find_by(channel_id: channel_id)
    return unless channel&.capture_mode == "full_stream"

    SlackCaptureJob.perform_later(channel_id: channel_id, thread_ts: thread_ts, capture_reason: "channel_stream")
  end
end
