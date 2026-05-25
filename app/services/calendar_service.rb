class CalendarService
  def initialize(ical_url: nil)
    @url = ical_url || EncryptedSetting.get("credentials", "google_ical_url")
  end

  def configured?
    @url.present?
  end

  def today_events
    events_between(Date.current.beginning_of_day, Date.current.end_of_day)
  end

  def upcoming_events(hours: 24)
    events_between(Time.current, hours.hours.from_now)
  end

  def events_between(start_time, end_time)
    return [] unless configured?

    feed = fetch_feed
    return [] unless feed

    calendars = Icalendar::Calendar.parse(feed)
    return [] if calendars.empty?

    calendars.flat_map(&:events).filter_map do |event|
      event_start = event.dtstart&.to_time
      event_end = event.dtend&.to_time
      next unless event_start && event_start >= start_time && event_start <= end_time

      attendees = extract_attendees(event)
      {
        title: event.summary.to_s,
        start_time: event_start,
        end_time: event_end,
        description: event.description.to_s,
        location: event.location.to_s,
        attendees: attendees,
        is_oneone: detect_oneone(event, attendees),
        matched_developer: match_developer(attendees)
      }
    end.sort_by { |e| e[:start_time] }
  rescue => e
    Rails.logger.error("CalendarService error: #{e.message}")
    []
  end

  private

  def fetch_feed
    uri = URI.parse(@url)
    response = Net::HTTP.get_response(uri)
    response.is_a?(Net::HTTPSuccess) ? response.body : nil
  rescue => e
    Rails.logger.error("CalendarService fetch error: #{e.message}")
    nil
  end

  def extract_attendees(event)
    return [] unless event.attendee

    event.attendee.map do |attendee|
      email = attendee.to_s.sub("mailto:", "").strip
      name = attendee.ical_params["cn"]&.first
      { email: email, name: name }
    end
  end

  def detect_oneone(event, attendees)
    return true if attendees.size == 2
    title = event.summary.to_s.downcase
    title.match?(/1[:\-\s]?1|one.on.one|1on1|catch.up/)
  end

  def match_developer(attendees)
    return nil if attendees.empty?

    attendees.each do |att|
      email_prefix = att[:email].to_s.split("@").first&.downcase
      next unless email_prefix.present?

      dev = Developer.find_by("LOWER(github_handle) = ? OR LOWER(slack_handle) = ? OR LOWER(name) LIKE ?",
                              email_prefix, email_prefix, "%#{email_prefix}%")
      return dev if dev
    end

    attendees.each do |att|
      next unless att[:name].present?
      dev = Developer.where("LOWER(name) LIKE ?", "%#{att[:name].downcase}%").first
      return dev if dev
    end

    nil
  end
end
