# frozen_string_literal: true

require 'date'

module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class ChatLogger
        class << self
          def log(robot, robot_id, data, type)
            return unless Lita.config.adapters.slack.log_chats

            log_location = Lita.config.adapters.slack.log_chats_location
            ensure_log_dir

            room_id = data['channel'] || data.dig('item', 'channel') || 'no-channel-id'
            channel = Lita::Room.find_by_id(room_id) if room_id != 'no-channel-id'
            room_name = channel.class != NilClass ? channel.name : 'room-name-not-discovered'
            log_chat = channel.class != NilClass ? not_is_private?(robot.chat_service.conversation_info(channel)) : true

            events_not_to_log = %w[user_typing file_public file_shared]
            return if !log_chat || events_not_to_log.include?(type)

            ts = data['event_ts']
            user_id = data['user']
            user_name = user_name_from_id(user_id)
            message = data['text'] || ''

            lita_log.debug('< ========================== ChatLogger Start ====')
            lita_log.debug("  robot_id: #{robot_id}")
            lita_log.debug("  data: #{data}")
            lita_log.debug("  type: #{type}")
            lita_log.debug('  ================================================ >')

            case type
            when 'hello'
              room_id = 'Slack'
              room_name = 'Slack'
              user_id = robot_id
              user_name = user_name_from_id(user_id)
              message = 'Bot connected to Slack'
            when 'message'
              user_name, user_id, message = handle_message(data, user_name, user_id)
            # when 'user_typing'
            #   No logging of 'user_typing' events
            when 'reaction_added'
              r_type = data['item']['type']
              r_ts = data['item']['ts']
              reaction = data['reaction']
              message = "reaction added to #{r_type} [#{r_ts}] #{reaction}"
            when 'reaction_removed'
              r_type = data['item']['type']
              r_ts = data['item']['ts']
              reaction = data['reaction']
              message = "reaction removed from #{r_type} [#{r_ts}] #{reaction}"
            when 'member_joined_channel'
              inviter_name = user_name_from_id(data['inviter'])
              inviter_message = " Invited by #{inviter_name}." if inviter.respond_to?(:name)
              message = " -> #{user_name} Just joined the channel.#{inviter_message}"
            when 'member_left_channel'
              message = " <- #{user_name} Just left the channel."
            when 'user_change'
              room_id = 'Slack'
              room_name = 'Slack'
              user_id = data['user']['id']
              user_name = user_name_from_id(user_id)
              profile = data['user']['profile']

              message = " -> #{user_name} Modified profile."
              message += " display_name:#{profile['display_name']}"
              message += " status_emoji:#{profile['status_emoji']}"
              message += " status_text:#{profile['status_text']}"
            when 'dnd_updated_user'
              room_id = 'Slack'
              room_name = 'Slack'
              dnd_status = data['dnd_status']
              message = " -> #{user_name} Modified Do Not Disturb."
              message += " Do Not Disturb:#{dnd_status['dnd_enabled']}"
              message += " DnD_start:#{dt(dnd_status['next_dnd_start_ts'])}"
              message += " DnD_end:#{dt(dnd_status['next_dnd_end_ts'])}"
            else
              subtype = "Message SubType: #{data['subtype']} : " if data['subtype']
              message = "Message Type: #{type} : #{subtype}#{message} (unhandled)"
            end

            return if message == ''

            log_to_file(log_file_name(log_location, room_id, room_name), user_name, user_id, ts, message)
          end

          def user_name_from_id(id)
            user = User.find_by_id(id)
            user ? user.name : 'user-name-not-discovered'
          end

          def log_file_name(log_location, room_id, room_name)
            "#{log_location}/#{room_id}-#{room_name}.log"
          end

          def log_to_file(log_file_name, user_name, user_id, ts, message)
            File.open(log_file_name, 'a') do |f|
              f.puts "[#{Time.now}] [#{user_name}/#{user_id}] [#{ts}] #{message}"
            end
          end

          def handle_message(data, user_name, user_id)
            message = data['text'] || 'message-not-discovered'
            log_message = true
            case data['subtype']
            when 'message_changed'
              previous_message = data['previous_message']
              p_message = previous_message['text'] || 'message-not-discovered'
              p_ts = previous_message['ts']

              new_message = data['message']
              user_id = new_message['user']
              user_name = user_name_from_id(user_id)
              n_message = new_message['text'] || 'message-not-discovered'

              message = "Message changed: [#{p_ts}] #{p_message} -> #{n_message}"
              message += handle_message_files(previous_message, 'Previous: ')
              message += handle_message_files(new_message, 'New:      ')
            when 'message_deleted'
              previous_message = data['previous_message']
              p_user_id = previous_message['user']
              p_user_name = user_name_from_id(p_user_id)
              p_message = previous_message['text'] || 'message-not-discovered'
              p_ts = previous_message['ts']
              # message_deleted does NOT show who deleted it!!!! ??????
              user_id = p_user_id
              user_name = p_user_name

              message = "Message deleted: [#{p_user_name}/#{p_user_id}] [#{p_ts}] #{p_message}"
              message += handle_message_files(previous_message, 'Deleted: ')
            when 'message_replied'
              # Slack thread origin message repeated. This is sent together with each reply.
              # Don't log these. repetition of message already logged.
              log_message = false
            when 'channel_join', 'channel_leave'
              # duplicate of member_joined_channel, member_left_channel event
              log_message = false
            when 'bot_message'
              # message from other bot
              user_name = data['username']
              user_id = data['bot_id']

              bot_profile = data['bot_profile']
              bot_name = bot_profile['name'] || ''

              attachments = data['attachments']

              message = "Bot message from '#{bot_name}'"
              attachments.each do |attachment|
                message += "\n\t#{attachment['title']} - #{attachment['title_link']}\n\t#{attachment['text']}"
              end
            else
              subtype = "Message SubType: #{data['subtype']} : " if data['subtype']
              message = "#{subtype}#{message}"
            end

            message = "Thread reply [#{data['thread_ts']}] #{message}" if data['thread_ts']

            message += handle_message_files(data)

            message = '' unless log_message
            [user_name, user_id, message]
          end

          def dt(timestamp)
            Time.at(timestamp.to_f)
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
            private = room['channel']['is_private']
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
