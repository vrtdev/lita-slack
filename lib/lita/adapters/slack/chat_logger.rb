# frozen_string_literal: true

require 'date'

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

            ensure_log_dir

            room_id = data['channel'] || 'room-id-not-discovered'
            channel = Lita::Room.find_by_id(room_id)
            room_name = channel ? channel.name : 'room-name-not-discovered'
            log_chat = channel ? not_is_private?(channel) : false

            if  !log_chat ||
                type == 'user_typing'
              return
            end

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
            # when 'user_typing'
            #   No logging of 'user_typing' events
            else
              subtype = "Message SubType: #{data['subtype']} : " if data['subtype']
              message = "Message Type: #{type} : #{subtype}#{message} (unhandled)"
            end

            # return unless log_chat

            lita_log.debug('< ========================== ChatLogger Start ====')
            # lita_log.debug("  robot: #{robot}")
            lita_log.debug("  robot_id: #{robot_id}")
            lita_log.debug("  data: #{data}")
            lita_log.debug("  type: #{type}")
            lita_log.debug('  ================================================ >')

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
              p_dt = dt(previous_message['ts'])

              new_message = data['message']
              user_id = new_message['user']
              user = User.find_by_id(user_id)
              user_name = user ? user.name : 'user-name-not-discovered'
              n_message = new_message['text'] || 'message-not-discovered'

              message = "Message changed: Previous message : #{p_dt} - '#{p_message}' : New message '#{n_message}"
              message += handle_message_files(previous_message, 'Previous: ')
              message += handle_message_files(new_message, 'New:      ')
            when 'message_deleted'
              previous_message = data['previous_message']
              p_user_id = previous_message['user']
              p_user = User.find_by_id(p_user_id)
              p_user_name = p_user ? p_user.name : 'user-name-not-discovered'
              p_message = previous_message['text'] || 'message-not-discovered'
              p_dt = dt(previous_message['ts'])
              # message_deleted does NOT show who deleted it!!!! ??????
              user_id = p_user_id
              user_name = p_user_name

              message = "Message deleted: Previous user '#{p_user_name}/#{p_user_id}' Previous message : #{p_dt} - '#{p_message}'"
              message += handle_message_files(previous_message, 'Deleted: ')
            when 'message_replied' # Slack thread
              # Maybe not log these. repetition of message already logged.
              reply = data['message']
              r_user_id = reply['user']
              r_user = User.find_by_id(r_user_id)
              r_user_name = r_user ? r_user.name : 'user-name-not-discovered'
              r_message = reply['text'] || 'message-not-discovered'
              r_dt = dt(reply['thread_ts'])

              user_id = r_user_id
              user_name = r_user_name

              message = "Thread datetime : #{r_dt} - '#{r_message}'"
            when 'bot_message'
              # message from other bot
              user_name = data['username']
              user_id = data['bot_id']

              bot_profile = data['bot_profile']
              bot_name = bot_profile['name'] || ''

              attachments = data['attachments']

              message = "Bot message from '#{bot_name}'"
              attachments.each do |attachment|
                message += "\n\t#{attachment['fallback']}"
              end
            else
              subtype = "Message SubType: #{data['subtype']} : " if data['subtype']
              message = "#{subtype}#{message}"
            end

            message = "Reply to thread with datetime : #{dt(data['thread_ts'])}\n\t#{message}" if data['thread_ts']

            message += handle_message_files(data)

            [user_name, user_id, message]
          end

          def dt(timestamp)
            Time.at(timestamp.to_f).to_datetime
          end

          def handle_message_files(data, prefix = '')
            filedata = ''
            if data['files']
              lita_log.debug('  Data has files.')
              data['files'].each do |file|
                lita_log.debug("  File: url: #{file['url_private_download']}")
                filedata += "\n\t#{prefix}url_private_download: #{file['url_private_download']}"
              end
            end
            filedata
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
