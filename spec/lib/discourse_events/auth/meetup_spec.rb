# frozen_string_literal: true

require "rails_helper"

describe DiscourseEvents::Auth::Meetup do
  let(:state) { "1234" }
  let(:code) { "1234567" }
  let(:client_id) { "12345" }
  let(:client_secret) { "12345" }
  let(:redirect_uri) { "https://redirect-uri.com" }
  let(:access_token) { "1234567" }
  let(:new_access_token) { "123456789" }
  let(:refresh_token) { "123456" }
  let(:new_refresh_token) { "12345678910" }
  let(:expires_in) { 3600 }
  let(:access_response) {
    {
      "access_token": access_token,
      "token_type": "bearer",
      "expires_in": expires_in,
      "refresh_token": refresh_token
    }
  }
  let(:refresh_response) {
    {
      "access_token": new_access_token,
      "token_type": "bearer",
      "expires_in": expires_in,
      "refresh_token": new_refresh_token
    }
  }
  let(:provider) {
    Fabricate(:discourse_events_provider,
      provider_type: "meetup",
      client_id: client_id,
      client_secret: client_secret
    )
  }

  it "generates an authorization url" do
    auth = DiscourseEvents::Auth::Meetup.new(provider.id)

    expect(auth.authorization_url(state)).to eq(
      "https://secure.meetup.com/oauth2/authorize?client_id=#{provider.client_id}&response_type=code&redirect_uri=#{provider.redirect_uri}&state=#{state}"
    )
  end

  it "gets a token" do
    freeze_time

    auth = DiscourseEvents::Auth::Meetup.new(provider.id)

    stub_request(:post, "#{auth.base_url}/access")
      .to_return(body: access_response.to_json, headers: { "Content-Type" => "application/json" }, status: 200)

    expect_enqueued_with(job: :discourse_events_refresh_token, args: { provider_id: provider.id, current_site_id: "default" }) do
      auth.request_token(code)
    end

    provider.reload
    expect(provider.token).to eq(access_token)
    expect(provider.refresh_token).to eq(refresh_token)
    expect(provider.token_expires_at).to eq_time(Time.now + expires_in.seconds)
    expect(provider.authenticated?).to eq(true)
  end

  it "refreshes a token" do
    freeze_time

    provider.token = access_token
    provider.refresh_token = refresh_token
    provider.token_expires_at = Time.now - 1.hour
    provider.save!

    auth = DiscourseEvents::Auth::Meetup.new(provider.id)

    stub_request(:post, "#{auth.base_url}/access")
      .to_return(body: refresh_response.to_json, headers: { "Content-Type" => "application/json" }, status: 200)

    expect_enqueued_with(job: :discourse_events_refresh_token, args: { provider_id: provider.id, current_site_id: "default" }) do
      auth.request_token(code)
    end

    provider.reload
    expect(provider.token).to eq(new_access_token)
    expect(provider.refresh_token).to eq(new_refresh_token)
    expect(provider.token_expires_at).to eq_time(Time.now + expires_in.seconds)
    expect(provider.authenticated?).to eq(true)
  end

  it "handles a failure to get a token" do
    freeze_time

    auth = DiscourseEvents::Auth::Meetup.new(provider.id)

    stub_request(:post, "#{auth.base_url}/access")
      .to_return(headers: { "Content-Type" => "application/json" }, status: 400)

    auth.request_token(code)

    provider.reload
    expect(provider.token).to eq(nil)
    expect(provider.refresh_token).to eq(nil)
    expect(provider.token_expires_at).to eq(nil)
    expect(provider.authenticated?).to eq(false)
    expect(DiscourseEvents::Log.where(level: 'error').size).to eq(1)
  end

  it "handles a failure to refresh a token" do
    freeze_time

    expires_at = Time.now - 1.hour
    provider.token = access_token
    provider.refresh_token = refresh_token
    provider.token_expires_at = expires_at
    provider.save!

    auth = DiscourseEvents::Auth::Meetup.new(provider.id)

    stub_request(:post, "#{auth.base_url}/access")
      .to_return(headers: { "Content-Type" => "application/json" }, status: 400)

    auth.request_token(code)

    freeze_time(3.days.from_now)

    provider.reload
    expect(provider.token).to eq(access_token)
    expect(provider.refresh_token).to eq(refresh_token)
    expect(provider.token_expires_at).to eq_time(expires_at)
    expect(provider.authenticated?).to eq(false)
    expect(DiscourseEvents::Log.where(level: 'error').size).to eq(1)
  end
end
