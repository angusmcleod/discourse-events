# frozen_string_literal: true

describe DiscourseEvents::ConnectionController do
  fab!(:category)
  fab!(:source) { Fabricate(:discourse_events_source) }
  fab!(:connection) { Fabricate(:discourse_events_connection, source: source) }
  fab!(:event) { Fabricate(:discourse_events_event, source: connection.source) }
  fab!(:user) { Fabricate(:user, admin: true) }

  before { sign_in(user) }

  it "lists connections and sources" do
    get "/admin/events/connection.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["connections"].first["id"]).to eq(connection.id)
    expect(response.parsed_body["sources"].first["name"]).to eq(connection.source.name)
  end

  it "lists clients" do
    if SiteSetting.respond_to?(:calendar_enabled)
      SiteSetting.calendar_enabled = true
      SiteSetting.discourse_post_event_enabled = true
    end

    skip("Discourse Events is not installed") unless DiscourseEvents::DiscourseEventsSyncer.ready?

    get "/admin/events/connection.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["clients"]).to match_array(%w[discourse_events events])
  end

  it "creates connections" do
    put "/admin/events/connection/new.json",
        params: {
          connection: {
            user: {
              username: user.username,
            },
            category_id: category.id,
            source_id: source.id,
            client: "events",
          },
        }

    expect(response.status).to eq(200)
    expect(response.parsed_body["connection"]["client"]).to eq("events")
    expect(response.parsed_body["connection"]["source_id"]).to eq(source.id)
    expect(response.parsed_body["connection"]["category_id"]).to eq(category.id)
  end

  it "handles invalid create params" do
    put "/admin/events/connection/new.json",
        params: {
          connection: {
            user: {
              username: user.username,
            },
            category_id: -1,
            source_id: source.id,
            client: "events",
          },
        }

    expect(response.status).to eq(400)
    expect(response.parsed_body["errors"].first).to eq("Category can't be blank")
  end

  it "updates connections" do
    new_client = "discourse_events"

    put "/admin/events/connection/#{connection.id}.json",
        params: {
          connection: {
            client: new_client,
          },
        }

    expect(response.status).to eq(200)
    expect(response.parsed_body["connection"]["client"]).to eq(new_client)
  end

  it "handles invalid update params" do
    put "/admin/events/connection/#{connection.id}.json",
        params: {
          connection: {
            client: "invalid_client",
          },
        }

    expect(response.status).to eq(400)
    expect(response.parsed_body["errors"].first).to eq(
      "Client invalid_client is not a valid connection client",
    )
  end

  it "destroys connections" do
    delete "/admin/events/connection/#{connection.id}.json"

    expect(response.status).to eq(200)
    expect(DiscourseEvents::Connection.exists?(connection.id)).to eq(false)
  end

  it "enqueues a connection sync" do
    expect_enqueued_with(
      job: :discourse_events_sync_connection,
      args: {
        connection_id: connection.id,
      },
    ) { post "/admin/events/connection/#{connection.id}.json" }

    expect(response.status).to eq(200)
  end

  it "creates filters" do
    put "/admin/events/connection/#{connection.id}.json",
        params: {
          connection: {
            client: "discourse_events",
            filters: [{ id: "new", query_column: "name", query_value: "Development" }],
          },
        }
    expect(response.status).to eq(200)

    connection.reload
    expect(connection.filters.first.query_column).to eq("name")
    expect(connection.filters.first.query_value).to eq("Development")
  end

  it "updates filters" do
    filter1 = Fabricate(:discourse_events_connection_filter, connection: connection)
    filter2 = Fabricate(:discourse_events_connection_filter, connection: connection)

    put "/admin/events/connection/#{connection.id}.json",
        params: {
          connection: {
            client: "discourse_events",
            filters: [
              { id: filter1.id, query_column: filter1.query_column, query_value: "New Value" },
            ],
          },
        }
    expect(response.status).to eq(200)

    connection.reload
    expect(connection.filters.size).to eq(1)
    expect(connection.filters.first.query_value).to eq("New Value")
  end
end
