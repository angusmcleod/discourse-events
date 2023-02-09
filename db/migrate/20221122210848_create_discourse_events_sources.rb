# frozen_string_literal: true
class CreateDiscourseEventsSources < ActiveRecord::Migration[7.0]
  def change
    create_table :discourse_events_sources do |t|
      t.string      :name, null: false
      t.references  :provider, null: false, foreign_key: { to_table: :discourse_events_providers }
      t.json        :source_options, default: {}
      t.datetime    :from_time
      t.datetime    :to_time
      t.string      :status
      t.string      :taxonomy

      t.timestamps
    end

    add_index :discourse_events_sources, [:name], unique: true, if_not_exists: true
  end
end
