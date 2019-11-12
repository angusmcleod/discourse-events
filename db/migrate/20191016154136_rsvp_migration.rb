class RsvpMigration < ActiveRecord::Migration[6.0]
  def change
    custom_fields = TopicCustomField.where(name: 'event_going')
    custom_fields.each do |custom_field|
      going = custom_field.value.split ','
      next if going.empty?
      going_ids = []

      going.each do |v|
        next if v.empty? || v.to_i != 0 #its an integer in quotes so its either an event created using latest code or already migrated
        begin
          user_id = User.find_by(username: v).id
        rescue ActiveRecord::RecordNotFound => e
          print "invalid username #{v}" #safely ignored invalid user id
        else
          going_ids.push user_id
        end
      end

      custom_field.value = going_ids.to_json
      custom_field.save
      puts "RSVP for topic: #{custom_field.topic_id} migrated successfully"
    end
  end
end
