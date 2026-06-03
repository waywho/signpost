require "test_helper"
require "icalendar"

class CalendarServiceTest < ActiveSupport::TestCase
  def build_ical(events)
    cal = Icalendar::Calendar.new
    events.each do |e|
      event = Icalendar::Event.new
      event.dtstart = Icalendar::Values::DateTime.new(e[:start])
      event.dtend = Icalendar::Values::DateTime.new(e[:end])
      event.summary = e[:title]
      if e[:attendees]
        e[:attendees].each do |att|
          attendee = Icalendar::Values::CalAddress.new("mailto:#{att[:email]}")
          attendee.ical_params = { "cn" => [ att[:name] ] } if att[:name]
          event.append_attendee(attendee)
        end
      end
      cal.add_event(event)
    end
    cal.to_ical
  end

  test "configured? returns false without URL" do
    assert_not CalendarService.new(ical_url: nil).configured?
  end

  test "configured? returns true with URL" do
    assert CalendarService.new(ical_url: "https://example.com/cal.ics").configured?
  end

  test "today_events parses iCal feed" do
    feed = build_ical([ {
      title: "Team standup",
      start: Time.current.change(hour: 10),
      end: Time.current.change(hour: 10, min: 30)
    } ])

    service = CalendarService.new(ical_url: "https://example.com/cal.ics")
    service.define_singleton_method(:fetch_feed) { feed }

    events = service.today_events
    assert_equal 1, events.size
    assert_equal "Team standup", events.first[:title]
  end

  test "detect_oneone identifies 2-person meetings" do
    feed = build_ical([ {
      title: "Sync",
      start: Time.current.change(hour: 14),
      end: Time.current.change(hour: 14, min: 30),
      attendees: [
        { email: "me@company.com", name: "Me" },
        { email: "alice@company.com", name: "Alice" }
      ]
    } ])

    service = CalendarService.new(ical_url: "https://example.com/cal.ics")
    service.define_singleton_method(:fetch_feed) { feed }

    events = service.today_events
    assert events.first[:is_oneone]
  end

  test "detect_oneone identifies by title" do
    feed = build_ical([ {
      title: "1:1 with Bob",
      start: Time.current.change(hour: 15),
      end: Time.current.change(hour: 15, min: 30),
      attendees: [
        { email: "me@company.com" },
        { email: "bob@company.com" },
        { email: "room@company.com" }
      ]
    } ])

    service = CalendarService.new(ical_url: "https://example.com/cal.ics")
    service.define_singleton_method(:fetch_feed) { feed }

    events = service.today_events
    assert events.first[:is_oneone]
  end

  test "match_developer finds developer by name" do
    create(:developer, name: "Alice Johnson")

    feed = build_ical([ {
      title: "Sync",
      start: Time.current.change(hour: 11),
      end: Time.current.change(hour: 11, min: 30),
      attendees: [
        { email: "me@company.com", name: "Me" },
        { email: "alice.johnson@company.com", name: "Alice Johnson" }
      ]
    } ])

    service = CalendarService.new(ical_url: "https://example.com/cal.ics")
    service.define_singleton_method(:fetch_feed) { feed }

    events = service.today_events
    assert_equal "Alice Johnson", events.first[:matched_developer]&.name
  end

  test "returns empty array when not configured" do
    service = CalendarService.new(ical_url: nil)
    assert_equal [], service.today_events
  end
end
