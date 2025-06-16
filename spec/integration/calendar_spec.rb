require 'spec_helper'

RSpec.describe GoogleServices::Calendar, :integration do
  # Skip these tests unless credentials are provided via environment variables
  before(:all) do
    unless ENV['GOOGLE_TEST_TOKEN'] && ENV['GOOGLE_TEST_REFRESH_TOKEN']
      skip "Set GOOGLE_TEST_TOKEN and GOOGLE_TEST_REFRESH_TOKEN to run integration tests"
    end
  end

  let(:credentials) do
    {
      google_token: ENV['GOOGLE_TEST_TOKEN'],
      google_refresh_token: ENV['GOOGLE_TEST_REFRESH_TOKEN'],
      google_token_expires_at: Time.now + 3600
    }
  end

  let(:calendar) { GoogleServices.calendar(credentials) }
  let(:test_event_ids) { [] }

  after(:each) do
    # Clean up any test events created
    test_event_ids.each do |event_id|
      begin
        calendar.delete_event(event_id)
      rescue GoogleServices::NotFoundError
        # Already deleted
      end
    end
  end

  describe "#create_event" do
    it "creates a calendar event" do
      event = calendar.create_event(
        title: "Test Event - #{Time.now}",
        start_time: 1.hour.from_now,
        duration: 30,
        description: "This is a test event created by google-services gem specs"
      )

      expect(event).to be_a(GoogleServices::Event)
      expect(event.id).not_to be_nil
      expect(event.title).to match(/Test Event/)
      expect(event.url).to match(/calendar\.google\.com/)

      test_event_ids << event.id
    end

    it "creates an event with attendees" do
      event = calendar.create_event(
        title: "Test Meeting - #{Time.now}",
        start_time: 2.hours.from_now,
        duration: 60,
        attendees: ["test@example.com"]
      )

      expect(event).to be_a(GoogleServices::Event)
      test_event_ids << event.id
    end
  end

  describe "#list_events" do
    it "lists events for today" do
      # Create an event for today
      event = calendar.create_event(
        title: "Test Event Today - #{Time.now}",
        start_time: 30.minutes.from_now,
        duration: 15
      )
      test_event_ids << event.id

      events = calendar.list_events(date: Date.today)
      expect(events).to be_an(Array)
      expect(events.map(&:id)).to include(event.id)
    end
  end

  describe "#find_event" do
    it "finds an existing event" do
      created = calendar.create_event(
        title: "Test Find Event - #{Time.now}",
        start_time: 1.hour.from_now
      )
      test_event_ids << created.id

      found = calendar.find_event(created.id)
      expect(found.id).to eq(created.id)
      expect(found.title).to eq(created.title)
    end

    it "raises NotFoundError for non-existent event" do
      expect {
        calendar.find_event("non-existent-id")
      }.to raise_error(GoogleServices::NotFoundError)
    end
  end

  describe "#update_event" do
    it "updates an event" do
      event = calendar.create_event(
        title: "Original Title - #{Time.now}",
        start_time: 1.hour.from_now
      )
      test_event_ids << event.id

      updated = calendar.update_event(event.id, title: "Updated Title")
      expect(updated.title).to eq("Updated Title")
    end
  end

  describe "#delete_event" do
    it "deletes an event" do
      event = calendar.create_event(
        title: "To Be Deleted - #{Time.now}",
        start_time: 1.hour.from_now
      )

      result = calendar.delete_event(event.id)
      expect(result).to be true

      expect {
        calendar.find_event(event.id)
      }.to raise_error(GoogleServices::NotFoundError)
    end
  end
end 