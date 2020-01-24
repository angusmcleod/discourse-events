class RsvpMigration < ActiveRecord::Migration[6.0]
  def up
    custom_fields = TopicCustomField.where(name: 'event_going')

    custom_fields.each do |custom_field|
      going = custom_field.value.split ','
      next if going.empty?

      going_ids = User.where(username: going).pluck(:id)
      custom_field.value = going_ids.to_json
      custom_field.save
      puts "RSVP for topic: #{custom_field.topic_id} migrated successfully\n"
    end
  end
end
