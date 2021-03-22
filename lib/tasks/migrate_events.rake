
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
  topics.each do |topic|
    event_data = topic.event
    e_start = event_data[:start].to_time.strftime("%F %T")
    start_arg = sprintf(start_string, e_start)
    replace_args = [start_arg]

    e_end = event_data[:end].present? ? event_data[:start].to_time.strftime("%F %T") : ""
    end_arg = sprintf(start_string, e_start)
    replace_args.push(end_arg)

    final_markdown = sprintf(
      event_markdown, 
      *replace_args
    )

    first_post = topic.first_post
    first_post.raw = first_post.raw + final_markdown
    first_post.save
    first_post.rebake!(priority: :normal)

    if args[:remove_actual]
      fields = topic.custom_fields.keys.select { |key| key.match(/^event_/) }
      fields.each do |field|
        topic.custom_fields[field] = nil
      end

      topic.save_custom_fields(true)
    end
  end
end
