require 'spec_helper'

RSpec.describe GoogleServices do
  it "has a version number" do
    expect(GoogleServices::VERSION).not_to be nil
  end

  describe ".configure" do
    it "allows configuration" do
      GoogleServices.configure do |config|
        config.client_id = "test_client_id"
        config.client_secret = "test_client_secret"
      end

      expect(GoogleServices.configuration.client_id).to eq("test_client_id")
      expect(GoogleServices.configuration.client_secret).to eq("test_client_secret")
    end
  end

  describe "service initialization" do
    let(:credentials_hash) do
      {
        google_token: "token",
        google_refresh_token: "refresh_token",
        google_token_expires_at: Time.now + 3600
      }
    end

    let(:credentials_object) do
      double("User",
        google_token: "token",
        google_refresh_token: "refresh_token",
        google_token_expires_at: Time.now + 3600
      )
    end

    context "with hash credentials" do
      it "creates a calendar service" do
        calendar = GoogleServices.calendar(credentials_hash)
        expect(calendar).to be_a(GoogleServices::Calendar)
      end

      it "creates a docs service" do
        docs = GoogleServices.docs(credentials_hash)
        expect(docs).to be_a(GoogleServices::Docs)
      end

      it "creates a meet service" do
        meet = GoogleServices.meet(credentials_hash)
        expect(meet).to be_a(GoogleServices::Meet)
      end
    end

    context "with object credentials" do
      it "creates a calendar service" do
        calendar = GoogleServices.calendar(credentials_object)
        expect(calendar).to be_a(GoogleServices::Calendar)
      end

      it "creates a docs service" do
        docs = GoogleServices.docs(credentials_object)
        expect(docs).to be_a(GoogleServices::Docs)
      end

      it "creates a meet service" do
        meet = GoogleServices.meet(credentials_object)
        expect(meet).to be_a(GoogleServices::Meet)
      end
    end
  end
end 