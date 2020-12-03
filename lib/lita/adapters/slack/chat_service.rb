require "lita/adapters/slack/attachment"

module Lita
  module Adapters
    class Slack < Adapter
      # Slack-specific features made available to +Lita::Robot+.
      # @api public
      # @since 1.6.0
      class ChatService
        attr_accessor :api

        # @param config [Lita::Configuration] The adapter's configuration data.
        def initialize(config)
          self.api = API.new(config)
        end

        # @param target [Lita::Room, Lita::User] A room or user object indicating where the
        #   attachment should be sent.
        # @param attachments [Attachment, Array<Attachment>] An {Attachment} or array of
        #   {Attachment}s to send.
        # @return [void]
        def send_attachments(target, attachments)
          api.send_attachments(target, Array(attachments))
        end
        alias_method :send_attachment, :send_attachments

        def send_file(target, file, mime_type = 'text/plain')
          api.send_file(target, file, mime_type)
        end

        def channel_info(target)
          api.channels_info target.id
        end

        def group_info(target)
          api.groups_info target.id
        end

        def conversation_info(target)
          api.conversations_info target.id
        end
      end
    end
  end
end
