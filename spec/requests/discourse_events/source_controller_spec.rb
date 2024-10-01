# frozen_string_literal: true

describe DiscourseEvents::SourceController do
  fab!(:source) { Fabricate(:discourse_events_source) }
  fab!(:provider) { Fabricate(:discourse_events_provider) }
  fab!(:user) { Fabricate(:user, admin: true) }

  before { sign_in(user) }

  it "lists sources and providers" do
    get "/admin/plugins/events/source.json"

    expect(response.status).to eq(200)
    expect(response.parsed_body["sources"].map { |s| s["id"] }).to include(source.id)
    expect(response.parsed_body["providers"].map { |p| p["id"] }).to include(source.provider.id)
  end

  context "with a subscription" do
    before { enable_subscription(:business) }

    it "creates sources" do
      put "/admin/plugins/events/source/new.json", params: { source: { provider_id: provider.id } }

      expect(response.status).to eq(200)
      expect(response.parsed_body["source"]["provider_id"]).to eq(provider.id)
    end

    it "handles invalid create params" do
      put "/admin/plugins/events/source/new.json", params: { source: { topic_sync: "inval$d" } }

      expect(response.status).to eq(400)
      expect(response.parsed_body["errors"].first).to eq(
        "You supplied invalid parameters to the request: topic_sync",
      )
    end

    it "updates sources" do
      category = Fabricate(:category)

      put "/admin/plugins/events/source/#{source.id}.json",
          params: {
            source: {
              category_id: category.id,
            },
          }

      expect(response.status).to eq(200)
      expect(response.parsed_body["source"]["category_id"]).to eq(category.id)
    end

    it "handles invalid update params" do
      put "/admin/plugins/events/source/#{source.id}.json",
          params: {
            source: {
              import_type: "inval$d",
            },
          }

      expect(response.status).to eq(400)
      expect(response.parsed_body["errors"].first).to eq(
        "You supplied invalid parameters to the request: import_type",
      )
    end

    it "creates filters" do
      put "/admin/plugins/events/source/new.json",
          params: {
            source: {
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
      expect_enqueued_with(job: :discourse_events_import_events, args: { source_id: source.id }) do
        post "/admin/plugins/events/source/#{source.id}/import.json"
      end

      expect(response.status).to eq(200)
    end

    context "when import period is added" do
      before { freeze_time }

      it "enqueues a source import" do
        expect_enqueued_with(
          job: :discourse_events_import_events,
          args: {
            source_id: source.id,
          },
          at: 5.minutes.from_now,
        ) do
          put "/admin/plugins/events/source/#{source.id}.json",
              params: {
                source: {
                  import_period: DiscourseEvents::Source::IMPORT_PERIODS["5_minutes"],
                },
              }
          expect(response.status).to eq(200)
        end
      end
    end

    context "when import period is removed" do
      before do
        source.import_period = DiscourseEvents::Source::IMPORT_PERIODS["5_minutes"]
        source.save!
      end

      it "removes enqueued imports" do
        Jobs
          .expects(:cancel_scheduled_job)
          .with(:discourse_events_import_events, source_id: source.id)
          .once
        put "/admin/plugins/events/source/#{source.id}.json",
            params: {
              source: {
                import_period: nil,
              },
            }
        expect(response.status).to eq(200)
      end
    end
  end
end
