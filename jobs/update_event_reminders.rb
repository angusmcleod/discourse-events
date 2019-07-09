module Jobs
  class UpdateEventReminders < Jobs::Base
    def execute(args = {})
      topics = []

      if args[:topic_id]
        topics.push(Topic.find(args[:topic_id]))
      else
        topics = TopicQuery.list_agenda(remove_past: true)
      end

      topics.each do |topic|
        if args[:added_usernames] || args[:removed_usernames]
          if args[:added_usernames].present?
            users(args[:added_usernames]).each do |user|
              update_event_reminder(topic, user, 'add')
            end
          end

          if args[:removed_usernames].present?
            users(args[:removed_usernames]).each do |user|
              update_event_reminder(topic, user, 'remove')
            end
          end
        else
          topic.delete_event_reminder

          if SiteSetting.events_enabled && SiteSetting.events_reminders_enabled
            update_event_reminder(topic, topic.user, 'add')

            if SiteSetting.events_rsvp && topic.event_rsvp
              users(topic.event_going).each do |user|
                update_event_timer(user, 'add')
              end
            end
          end
        end
      end
    end

    def users(usernames)
      usernames.map { |username| User.find_by(username: username) }
    end

    def update_event_reminder(topic, user, type)
      hours_before = SiteSetting.events_reminders_hours_before
      hours = type == 'add' ? ((topic.event[:start].to_time - Time.now) / 1.hours) - hours_before : nil
      result = topic.set_or_create_event_reminder(hours, user)
    end
  end
end
