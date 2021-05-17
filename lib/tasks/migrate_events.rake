
desc "migrate the events plugin data to discourse-calendar events data"

task "events:migrate_events", [:remove_actual] => :environment do |_, args|
  topics = Topic.all.select { |topic| topic.has_event? }
  event_markdown = <<~EV_MARKDOWN
    \n
    [event %s %s status="public" allowedGroups="trust_level_0"]
    [/event]
  EV_MARKDOWN
  start_string = "start=\"%s\""
  end_string = "end=\"%s\""

  puts "", "Total #{topics.count} event topics found"
  
  topics.each do |topic|
    event_data = topic.event
    e_start = event_data[:start].to_time.strftime("%F %T")
    start_arg = sprintf(start_string, e_start)
    replace_args = [start_arg]

    e_end = event_data[:end].present? ? event_data[:end].to_time.strftime("%F %T") : ""
    end_arg = sprintf(end_string, e_end)
    replace_args.push(end_arg)

    final_markdown = sprintf(
      event_markdown, 
      *replace_args
    )

    first_post = topic.first_post
    first_post.raw = first_post.raw + final_markdown
    first_post.save
    DiscoursePostEvent::Event.update_from_raw(first_post)

    migrate_rsvp_users(topic, first_post)
    puts "", "Successfully migrated the event data for Topic: #{topic.id}.", ""

    if args[:remove_actual]
      fields = topic.custom_fields.keys.select { |key| key.match(/^event_/) }
      fields.each do |field|
        topic.custom_fields[field] = nil
      end

      topic.save_custom_fields(true)
      puts "", "Removed the old events data for Topic: #{topic.id}.", ""
    end
  end

  puts "", "Finished!!"
end

def migrate_rsvp_users(topic, first_post)
  rsvp_enabled = topic.event[:rsvp]
  return unless !!rsvp_enabled
  return unless ("DiscoursePostEvent::Invitee".constantize.is_a?(Class) rescue false)
  rsvp_data = topic.custom_fields[:event_going]
  return unless rsvp_data.present?

  puts "", "Importing invitees for Topic: #{topic.id} ...", ""
  p "Importing user ids #{rsvp_data.inspect}"
  rsvp_data.each do |user_id|
    DiscoursePostEvent::Invitee.create(
      user_id: user_id,
      post_id: first_post.id,
      status: DiscoursePostEvent::Invitee.statuses[:going]
    )
  end

  puts "", "Imported Successfully", ""
end
