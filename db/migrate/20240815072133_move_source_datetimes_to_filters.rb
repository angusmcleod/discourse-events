# frozen_string_literal: true
class MoveSourceDatetimesToFilters < ActiveRecord::Migration[7.1]
  def up
    filters = []
    DiscourseEvents::Source.all.each do |source|
      filters += [
        {
          model_id: source.id,
          model_type: "DiscourseEvents::Source",
          query_column: DiscourseEvents::Filter.query_columns[:start_time],
          query_operator: DiscourseEvents::Filter.query_operators[:greater_than],
          query_value: source.read_attribute(:from_time)
        },
        {
          model_id: source.id,
          model_type: "DiscourseEvents::Source",
          query_column: DiscourseEvents::Filter.query_columns[:start_time],
          query_operator: DiscourseEvents::Filter.query_operators[:less_than],
          query_value: source.read_attribute(:to_time)
        },
      ]
    end
    DiscourseEvents::Filter.insert_all(filters)
  end

  def down
  end
end
