# frozen_string_literal: true

require 'faraday'

require 'lita/adapters/slack/team_data'
require 'lita/adapters/slack/slack_im'
require 'lita/adapters/slack/slack_user'
require 'lita/adapters/slack/slack_channel'

module Lita
  module Adapters
    class Slack < Adapter
      # @api private
      class API
        def initialize(config, stubs = nil)
          @config = config
          @stubs = stubs
          @post_message_config = {}
          @post_message_config[:parse] = config.parse unless config.parse.nil?
          @post_message_config[:link_names] = config.link_names ? 1 : 0 unless config.link_names.nil?
          @post_message_config[:unfurl_links] = config.unfurl_links unless config.unfurl_links.nil?
          @post_message_config[:unfurl_media] = config.unfurl_media unless config.unfurl_media.nil?
        end

        def conversations_open(user_id)
          response_data = call_api('conversations.open', users: user_id)

          SlackIM.new(response_data['channel']['id'], user_id)
        end

        def conversations_info(channel_id)
          call_api('conversations.info', channel: channel_id)
        end

        def channels_list
          call_api('conversations.list', types: 'public_channel')
        end

        def groups_list
          call_api('conversations.list', types: 'private_channel')
        end

        def mpim_list
          call_api('conversations.list', types: 'mpim')
        end

        def im_list
          call_api('conversations.list', types: 'im')
        end

        def send_attachments(room_or_user, attachments)
          call_api(
            'chat.postMessage',
            as_user: true,
            channel: room_or_user.id,
            attachments: MultiJson.dump(attachments.map(&:to_hash))
          )
        end

        def send_messages(channel_id, messages)
          call_api(
            'chat.postMessage',
            **post_message_config,
            as_user: true,
            channel: channel_id,
            text: messages.join("\n")
          )
        end

        def set_topic(channel, topic)
          call_api('conversations.setTopic', channel: channel, topic: topic)
        end

        def send_file(room_or_user, file, mime_type = 'text/plain')
          call_api(
            'files.upload',
            channels: room_or_user.id,
            file: Faraday::FilePart.new(file, mime_type)
          )
        end

        # TODO: RTM is also deprecated but has no end-date announced yet
        # https://api.slack.com/rtm
        def rtm_start
          response_data = call_api('rtm.start')

          TeamData.new(
            SlackIM.from_data_array(response_data['ims']),
            SlackUser.from_data(response_data['self']),
            SlackUser.from_data_array(response_data['users']),
            SlackChannel.from_data_array(response_data['channels']) +
              SlackChannel.from_data_array(response_data['groups']),
            response_data['url']
          )
        end

        private

        attr_reader :stubs, :config, :post_message_config

        def call_api(method, post_data = {})
          response = connection.post(
            "https://slack.com/api/#{method}",
            { token: config.token }.merge(post_data)
          )

          data = parse_response(response, method)

          raise "Slack API call to #{method} returned an error: #{data['error']}." if data['error']

          data
        end

        def connection
          if stubs
            Faraday.new { |faraday| faraday.adapter(:test, stubs) }
          else
            options = {}
            unless config.proxy.nil?
              options = { proxy: config.proxy }
            end
            Faraday.new(options) do |conn|
              # POST/PUT params encoders:
              conn.request :multipart
              conn.request :url_encoded
              conn.adapter :net_http
            end
          end
        end

        def parse_response(response, method)
          unless response.success?
            raise "Slack API call to #{method} failed with status code #{response.status}: '#{response.body}'. Headers: #{response.headers}"
          end

          MultiJson.load(response.body)
        end
      end
    end
  end
end
