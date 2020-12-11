module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class ChatLogger
        class << self
          def log(robot, robot_id, data, type)
            @robot = robot

            return unless Lita.config.adapters.slack.log_chats
            log_location = Lita.config.adapters.slack.log_chats_location

            lita_log.debug('< ========================== ChatLogger Start ====')
            lita_log.debug("  robot: #{robot}") # - #{robot.inspect}")
            # lita_log.debug("  robot: #{robot} - #{robot.inspect}")
            lita_log.debug("  robot_id: #{robot_id}")
            lita_log.debug("  data: #{data}")
            lita_log.debug("  type: #{type}")
            lita_log.debug('  ================================================ >')

            ensure_log_dir

            room_id = data['channel'] || 'room-id-not-discovered'
            channel = Lita::Room.find_by_id(room_id)
            room_name = channel ? channel.name : 'room-name-not-discovered'
            log_chat = channel ? not_is_private?(channel) : false

            user_id = data['user']
            user = User.find_by_id(user_id)
            user_name = user ? user.name : 'user-name-not-discovered'
            message = data['text'] || 'message-not-discovered'

            case type
            when 'hello'
              room_id = 'Slack'
              room_name = 'Slack'
              user_name = 'Bot'
              message = 'Bot connected to Slack'
            when 'message'
              user_name, user_id, message = handle_message(data, user_name, user_id)
            when 'user_typing'
              log_chat = false
            else
              subtype = "Message SubType: #{data['subtype']} : " if data['subtype']
              message = "Message Type: #{type} : #{subtype}#{message}"
            end

            return unless log_chat

            log_file_name = "#{log_location}/#{room_id}-#{room_name}.log"
            File.open(log_file_name, 'a') do |f|
              f.puts "[#{Time.now}] [#{user_name}/#{user_id}] #{message}"
            end
          end

          def handle_message(data, user_name, user_id)
            message = data['text'] || 'message-not-discovered'
            case data['subtype']
            when 'message_changed'
              previous_message = data['previous_message']
              p_message = previous_message['text'] || 'message-not-discovered'

              new_message = data['message']
              user_id = new_message['user']
              user = User.find_by_id(user_id)
              user_name = user ? user.name : 'user-name-not-discovered'
              n_message = new_message['text'] || 'message-not-discovered'

              message = "Message changed: Previous message '#{p_message}' : New message '#{n_message}"
            when 'message_deleted'
              previous_message = data['previous_message']
              p_user_id = previous_message['user']
              p_user = User.find_by_id(p_user_id)
              p_user_name = p_user ? p_user.name : 'user-name-not-discovered'
              p_message = previous_message['text'] || 'message-not-discovered'
              # message_deleted does NOT show who deleted it!!!! ??????
              user_id = p_user_id
              user_name = p_user_name

              message = "Message deleted: Previous user '#{p_user_name}/#{p_user_id}' Previous message '#{p_message}'"
            else
              subtype = "Message SubType: #{data['subtype']} : " if data['subtype']
              message = "Message Type: #{data['type']} : #{subtype}#{message}"
            end
            [user_name, user_id, message]
          end

          def not_is_private?(room)
            private = @robot.chat_service.conversation_info(room)['channel']['is_private']
            lita_log.debug('Channel is private. Not logging this message.') if private
            !private
          end

          def ensure_log_dir
            dirname = Lita.config.adapters.slack.log_chats_location
            lita_log.debug("Creating channel log location dir : #{dirname}") unless File.directory?(dirname)
            FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
          end

          def lita_log
            Lita.logger
          end
        end
      end
    end
  end
end
