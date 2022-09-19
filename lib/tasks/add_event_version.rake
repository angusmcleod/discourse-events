# frozen_string_literal: true

desc "adds event version for using in ical feed for the event posts"

task "events:add_event_version" => :environment do
  topic_ids = TopicCustomField.where(name: 'event_start').pluck(:topic_id)
  topic_ids = topic_ids.select { |topic_id|  TopicCustomField.where(topic_id: topic_id, name: 'event_version').empty? }

  topic_ids.each do |topic_id|
    TopicCustomField.new(topic_id: topic_id, name: 'event_version', value: 1).save
    puts "event_version for topic id #{topic_id} saved successfully"
  end
end
