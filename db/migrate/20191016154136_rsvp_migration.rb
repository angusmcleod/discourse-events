class RsvpMigration < ActiveRecord::Migration[5.2]
  def up
    custom_fields = TopicCustomField.where(name: 'event_going')

    custom_fields.each do |custom_field|
      going = custom_field.value.split ','

      if going.empty?
        custom_field.value = []
        custom_field.save
        next
      end

      going_ids = User.where(username: going).pluck(:id)
      custom_field.value = going_ids.to_json
      custom_field.save
      puts "RSVP for topic: #{custom_field.topic_id} migrated successfully\n"
    end
  end
end
