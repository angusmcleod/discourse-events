# frozen_string_literal: true

describe DiscourseEvents::SourceController do
  fab!(:source) { Fabricate(:discourse_events_source) }
  fab!(:provider) { Fabricate(:discourse_events_provider) }
  fab!(:user) { Fabricate(:user, admin: true) }

  before { sign_in(user) }

  it "lists sources and providers" do
    get "/admin/plugins/events/source.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["sources"].first["name"]).to eq(source.name)
    expect(response.parsed_body["providers"].first["name"]).to eq(source.provider.name)
  end

  it "creates sources" do
    put "/admin/plugins/events/source/new.json",
        params: {
          source: {
            name: "my_source",
            provider_id: provider.id,
          },
        }

    expect(response.status).to eq(200)
    expect(response.parsed_body["source"]["name"]).to eq("my_source")
    expect(response.parsed_body["source"]["provider_id"]).to eq(provider.id)
  end

  it "handles invalid create params" do
    put "/admin/plugins/events/source/new.json",
        params: {
          source: {
            name: "inval$d source n4m3",
            provider_id: provider.id,
          },
        }

    expect(response.status).to eq(400)
    expect(response.parsed_body["errors"].first).to eq("Name is invalid")
  end

  it "updates sources" do
    new_name = "new_source_name"

    put "/admin/plugins/events/source/#{source.id}.json", params: { source: { name: new_name } }

    expect(response.status).to eq(200)
    expect(response.parsed_body["source"]["name"]).to eq(new_name)
  end

  it "handles invalid update params" do
    put "/admin/plugins/events/source/#{source.id}.json",
        params: {
          source: {
            name: "inval$d source n4m3",
          },
        }

    expect(response.status).to eq(400)
    expect(response.parsed_body["errors"].first).to eq("Name is invalid")
  end

  it "creates filters" do
    put "/admin/plugins/events/source/new.json",
        params: {
          source: {
            name: "my_source",
            provider_id: provider.id,
            filters: [
              {
                id: "new",
                query_column: "name",
                query_operator: "like",
                query_value: "Development",
              },
            ],
          },
        }
    expect(response.status).to eq(200)
    expect(response.parsed_body["source"]["filters"][0]["query_column"]).to eq("name")
    expect(response.parsed_body["source"]["filters"][0]["query_value"]).to eq("Development")
  end

  it "updates filters" do
    filter1 = Fabricate(:discourse_events_filter, model: source)
    filter2 = Fabricate(:discourse_events_filter, model: source)

    put "/admin/plugins/events/source/#{source.id}.json",
        params: {
          source: {
            filters: [
              {
                id: filter1.id,
                query_column: filter1.query_column,
                query_operator: filter1.query_operator,
                query_value: "New Value",
              },
            ],
          },
        }
    expect(response.status).to eq(200)

    source.reload
    expect(source.filters.size).to eq(1)
    expect(source.filters.first.query_value).to eq("New Value")
  end

  it "destroys sources" do
    delete "/admin/plugins/events/source/#{source.id}.json"

    expect(response.status).to eq(200)
    expect(DiscourseEvents::Source.exists?(source.id)).to eq(false)
  end

  it "enqueues a source import" do
    expect_enqueued_with(job: :discourse_events_import_source, args: { source_id: source.id }) do
      post "/admin/plugins/events/source/#{source.id}.json"
    end

    expect(response.status).to eq(200)
  end
end
