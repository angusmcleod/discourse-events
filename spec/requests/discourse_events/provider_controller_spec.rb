# frozen_string_literal: true

describe DiscourseEvents::ProviderController do
  fab!(:provider) { Fabricate(:discourse_events_provider) }
  fab!(:user) { Fabricate(:user, admin: true) }

  before { sign_in(user) }

  it "lists providers" do
    get "/admin/plugins/events/provider.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["providers"].first["name"]).to eq(provider.name)
  end

  it "creates providers" do
    put "/admin/plugins/events/provider/new.json",
        params: {
          provider: {
            name: "my_provider",
            provider_type: "icalendar",
          },
        }

    expect(response.status).to eq(200)
    expect(response.parsed_body["provider"]["name"]).to eq("my_provider")
    expect(response.parsed_body["provider"]["provider_type"]).to eq("icalendar")
  end

  it "handles invalid create params" do
    put "/admin/plugins/events/provider/new.json",
        params: {
          provider: {
            name: "inval$d provider n4m3",
            provider_type: "icalendar",
          },
        }

    expect(response.status).to eq(400)
    expect(response.parsed_body["errors"].first).to eq(
      "Name inval$d provider n4m3 is not a valid name",
    )
  end

  it "updates providers" do
    new_name = "new_provider_name"

    put "/admin/plugins/events/provider/#{provider.id}.json",
        params: {
          provider: {
            name: new_name,
          },
        }

    expect(response.status).to eq(200)
    expect(response.parsed_body["provider"]["name"]).to eq(new_name)
  end

  it "handles invalid update params" do
    put "/admin/plugins/events/provider/#{provider.id}.json",
        params: {
          provider: {
            name: "inval$d provider n4m3",
          },
        }

    expect(response.status).to eq(400)
    expect(response.parsed_body["errors"].first).to eq(
      "Name inval$d provider n4m3 is not a valid name",
    )
  end

  it "destroys provider" do
    delete "/admin/plugins/events/provider/#{provider.id}.json"

    expect(response.status).to eq(200)
    expect(DiscourseEvents::Provider.exists?(provider.id)).to eq(false)
  end

  context "with authorization" do
    before do
      provider.client_id = "1234"
      provider.client_secret = "5678"
      provider.provider_type = "meetup"
      provider.save!
    end

    it "redirects to authorization url" do
      get "/admin/plugins/events/provider/#{provider.id}/authorize"

      expect(response.status).to eq(302)
      state = read_secure_session["#{described_class::AUTH_SESSION_KEY}-#{user.id}"]
      expect(response).to redirect_to(provider.authorization_url(state))
    end

    it "handles authorization redirects" do
      state = "#{SecureRandom.hex}:#{provider.id}"
      code = "1234"
      write_secure_session("#{described_class::AUTH_SESSION_KEY}-#{user.id}", state)

      DiscourseEvents::Provider.any_instance.stubs(:request_token).returns(nil)
      DiscourseEvents::Provider.any_instance.expects(:request_token).with(code).once

      get "/admin/plugins/events/provider/redirect", params: { state: state, code: code }

      expect(response.status).to eq(302)
      expect(response).to redirect_to("/admin/plugins/events/provider")
    end
  end
end
