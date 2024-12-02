# frozen_string_literal: true
class CreateDiscourseEventsEventRegistrations < ActiveRecord::Migration[7.1]
  def change
    create_table :discourse_events_event_registrations do |t|
      t.references :event,
                   index: true,
                   foreign_key: {
                     to_table: :discourse_events_events,
                   },
                   null: false
      t.references :user
      t.string :email, null: false
      t.string :uid
      t.string :name
      t.integer :status

      t.timestamps
    end

    add_index :discourse_events_event_registrations,
              %i[event_id email],
              unique: true,
              name: :idx_events_event_registration_event_emails
  end
end
