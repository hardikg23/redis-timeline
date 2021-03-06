module Timeline
 
  module NotificationHelper
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      def track_notification(name, options={})
        @name = name
        @actor = options[:actor]
        @object = options[:object]
        @target = options[:target]
        @followers = set_follower(options[:followers])
        @mentionable = options[:mentionable]
        @read = options[:read] || false

        add_activity_to_subscribed_user(@followers,notification_activity) if @followers.present?
        add_mentions(notification_activity)
      end

      def add_activity_to_subscribed_user(followers, activity_item)
        followers.each do |follower|
          add_to_redis "user:id:#{follower.id}:notification", activity_item
          trim_notification "user:id:#{follower.id}:notification"
        end
      end

      def add_to_redis(list, activity_item)
        Timeline.redis.lpush list, Timeline.encode(activity_item)
      end

      def trim_notification(list)
        Timeline.redis.ltrim list, 0, 29
      end

      def add_mentions(activity_item)
        return unless @mentionable
        @mentionable.each do |mention|
          if user = @actor.class.where("coalesce(display_name, login) = ?",mention)
            add_activity_to_subscribed_user(user, activity_item)
          end
        end
      end

      def set_as_read_notification(user, read, options= {})
        notifications = get_unread_notification(user, options)
        notifications.each do |index, notification|
          Timeline.redis.lset("user:id:#{user.id}:notification",index, Timeline.encode(reset_read_activity(notification, read)))
        end
      end

      def get_unread_notification(user, options= {})
        result = {}
        Timeline.redis.lrange("user:id:#{user.id}:notification", options[:start] || 0, options[:end] || 10).each_with_index do |item, index|
          data = Timeline.decode(item)
          result.merge!(index => data) unless data["read"]
        end
        result
      end


      private
        def notification_activity
          {
            verb: @name,
            actor: @actor,
            object: @object,
            target: @target,
            created_at: Time.now,
            read: @read
          }
        end

        def set_follower(follower)
          if follower.is_a?(Array)
            follower
          elsif follower.present?
            [follower]
          else
            []
          end
        end

       def reset_read_activity(activity, read)
        {
          verb: activity["verb"],
          actor: activity["actor"],
          object: activity["object"],
          target: activity["target"],
          created_at: activity["created_at"],
          read: read
        }
      end

    end
  end
end
