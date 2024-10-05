# frozen_string_literal: true

require "rails_helper"

describe DiscourseEvents::PublishManager do
  fab!(:category)
  fab!(:user) { Fabricate(:user, trust_level: TrustLevel[1]) }
  fab!(:source) { Fabricate(:discourse_events_source, category: category, user: user) }
  fab!(:topic) { Fabricate(:topic, category: category) }
  fab!(:post) { Fabricate(:post, topic: topic, user: user) }
  let!(:event_start) { "2017-09-18T16:00:00+08:00" }
  let!(:event_hash) do
    OmniEvent::EventHash.new(
      provider: :developer,
      data: {
        event_start: event_start,
      },
      metadata: {
        uid: "12345",
      },
    )
  end

  def enable_events
    category.custom_fields["events_enabled"] = true
    category.save_custom_fields(true)
  end

  def enable_publication
    source.import_type = DiscourseEvents::Source.import_types[:import_publish]
    source.save!
  end

  def create_post_event(event_id: nil)
    topic.custom_fields["event_start"] = event_start.to_datetime.to_i
    topic.custom_fields["event_id"] = event_id if event_id
    topic.save_custom_fields(true)
    topic.reload
  end

  def enable_rsvp
    topic.custom_fields["event_rsvp"] = true
    topic.save_custom_fields(true)
    topic.reload
  end

  before { enable_subscription(:business) }

  describe "#create_event" do
    let!(:manager) { DiscourseEvents::PublishManager.new(post, "create") }

    context "with events enabled" do
      before { enable_events }

      context "with a post event" do
        before { create_post_event }

        context "without publishable sources" do
          it "creates an event" do
            manager.publish
            expect(DiscourseEvents::Event.exists?(start_time: event_start)).to eq(true)
          end

          it "creates an event topic" do
            manager.publish
            expect(DiscourseEvents::EventTopic.exists?(topic_id: topic.id)).to eq(true)
          end
        end

        context "with publishable sources" do
          before { enable_publication }

          it "sends create_event to the right publisher" do
            DiscourseEvents::Publisher::DiscourseEvents
              .any_instance
              .expects(:create_event)
              .once
              .returns(event_hash)
            manager.publish
          end

          context "when publication succeeds" do
            before do
              DiscourseEvents::Publisher
                .any_instance
                .expects(:create_event)
                .once
                .returns(event_hash)
            end

            it "creates an event" do
              manager.publish
              expect(DiscourseEvents::Event.exists?(start_time: event_start)).to eq(true)
            end

            it "creates an event topic" do
              manager.publish
              expect(DiscourseEvents::EventTopic.exists?(topic_id: topic.id)).to eq(true)
            end

            it "creates event sources" do
              manager.publish
              event = DiscourseEvents::Event.find_by(start_time: event_start)
              expect(
                DiscourseEvents::EventSource.exists?(
                  uid: "12345",
                  source_id: source.id,
                  event_id: event.id,
                ),
              ).to eq(true)
            end
          end
        end
      end
    end
  end

  describe "#update_event" do
    let!(:manager) { DiscourseEvents::PublishManager.new(post, "update") }

    before do
      enable_events
      enable_publication
    end

    context "with an updated event" do
      let!(:event) { Fabricate(:discourse_events_event, start_time: event_start) }
      let!(:event_topic) do
        Fabricate(:discourse_events_event_topic, event: event, topic: post.topic)
      end
      let!(:event_source) do
        Fabricate(
          :discourse_events_event_source,
          event: event,
          source: source,
          uid: event_hash.metadata.uid,
        )
      end
      let!(:updated_event_start) { "2017-10-13T18:00:00+08:00" }
      let!(:updated_event_hash) do
        updated_event_hash = event_hash.dup
        updated_event_hash.data.event_start = updated_event_start
        updated_event_hash
      end

      before do
        create_post_event(event_id: event.id)
        topic.custom_fields["event_start"] = updated_event_start.to_datetime.to_i
        topic.save_custom_fields(true)
      end

      it "sends update_event to the right publisher" do
        DiscourseEvents::Publisher::DiscourseEvents
          .any_instance
          .expects(:update_event)
          .once
          .returns(updated_event_hash)
        manager.publish
      end

      context "when publication succeeds" do
        before do
          DiscourseEvents::Publisher
            .any_instance
            .expects(:update_event)
            .once
            .returns(updated_event_hash)
        end

        it "updates the event" do
          manager.publish
          expect(event.reload.start_time).to eq(updated_event_start)
        end
      end
    end
  end

  describe "#destroy_event" do
    let!(:manager) { DiscourseEvents::PublishManager.new(post, "destroy") }

    before do
      enable_events
      enable_publication
    end

    context "with an event" do
      let!(:event) { Fabricate(:discourse_events_event, start_time: event_start) }
      let!(:event_topic) do
        Fabricate(:discourse_events_event_topic, event: event, topic: post.topic)
      end
      let!(:event_source) do
        Fabricate(
          :discourse_events_event_source,
          event: event,
          source: source,
          uid: event_hash.metadata.uid,
        )
      end

      before { create_post_event(event_id: event.id) }

      it "sends destroy_event to the right publisher" do
        DiscourseEvents::Publisher::DiscourseEvents
          .any_instance
          .expects(:destroy_event)
          .once
          .returns(event_hash)
        manager.publish
      end

      context "when publication succeeds" do
        before do
          DiscourseEvents::Publisher.any_instance.expects(:destroy_event).once.returns(event_hash)
        end

        it "destroys the event" do
          manager.publish
          expect(DiscourseEvents::Event.exists?(event.id)).to eq(false)
        end
      end
    end
  end

  describe "#update_registrations" do
    fab!(:user2) { Fabricate(:user) }
    fab!(:event) { Fabricate(:discourse_events_event) }
    fab!(:event_topic) { Fabricate(:discourse_events_event_topic, event: event, topic: topic) }

    context "with discourse_events" do
      def update_event_going(event_going = [])
        topic.custom_fields["event_going"] = event_going
        topic.save_custom_fields(true)
        DiscourseEvent.trigger(:discourse_events_rsvps_updated, topic)
      end

      context "with events enabled" do
        before { enable_events }

        context "with a post event" do
          before { create_post_event(event_id: event.id) }

          context "with rsvp enabled" do
            before { enable_rsvp }

            context "with registrations" do
              fab!(:event_registration1) do
                Fabricate(
                  :discourse_events_event_registration,
                  event: event,
                  user: user,
                  email: user.email,
                  status: "confirmed",
                )
              end
              fab!(:event_registration2) do
                Fabricate(
                  :discourse_events_event_registration,
                  event: event,
                  user: user2,
                  email: user2.email,
                  status: "declined",
                )
              end

              it "updates registrations when rsvps are updated" do
                update_event_going([user.id, user2.id])
                expect(event_registration2.status).to eq("confirmed")
              end
            end
          end
        end
      end
    end

    context "with discourse_calendar" do
      before do
        unless defined?(DiscoursePostEvent) == "constant"
          skip("Discourse Calendar is not installed")
        end

        SiteSetting.calendar_enabled = true
        SiteSetting.discourse_post_event_enabled = true

        event_topic.client = "discourse_calendar"
        event_topic.save!

        DiscoursePostEvent::Event.create!(
          id: post.id,
          original_starts_at: Time.now + 1.hours,
          original_ends_at: Time.now + 2.hours,
        )
      end

      it "creates a registration when an invitee is created" do
        DiscoursePostEvent::Invitee.create_attendance!(user.id, post.id, "going")

        registration = DiscourseEvents::EventRegistration.find_by(user_id: user.id)
        expect(registration).to be_present
        expect(registration.status).to eq("confirmed")
      end

      context "with registrations" do
        before do
          DiscoursePostEvent::Invitee.create_attendance!(user.id, post.id, "going")
          DiscoursePostEvent::Invitee.create_attendance!(user2.id, post.id, "not_going")
        end

        it "updates registrations when attendence is updated" do
          invitee = DiscoursePostEvent::Invitee.find_by(user_id: user2.id, post_id: post.id)
          invitee.update_attendance!("going")

          registration = DiscourseEvents::EventRegistration.find_by(user_id: user2.id)
          expect(registration.status).to eq("confirmed")
        end
      end
    end
  end
end
