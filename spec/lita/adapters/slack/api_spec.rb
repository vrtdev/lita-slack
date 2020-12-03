require "spec_helper"

describe Lita::Adapters::Slack::API do
  subject { described_class.new(config, stubs) }

  let(:http_status) { 200 }
  let(:token) { 'abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y' }
  let(:config) { Lita::Adapters::Slack.configuration_builder.build }

  before do
    config.token = token
  end

  describe "#conversations_open" do
    let(:channel_id) { 'D024BFF1M' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/conversations.open', token: token, users: user_id) do
          [http_status, {}, http_response]
        end
      end
    end
    let(:user_id) { 'U023BECGF' }

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
            ok: true,
            channel: {
                id: 'D024BFF1M'
            }
        })
      end

      it "returns a response with the IM's ID" do
        response = subject.conversations_open(user_id)

        expect(response.id).to eq(channel_id)
      end
    end

    describe "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.conversations_open(user_id) }.to raise_error(
          "Slack API call to conversations.open returned an error: invalid_auth."
        )
      end
    end

    describe "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.conversations_open(user_id) }.to raise_error(
          "Slack API call to conversations.open failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#channels_info" do
    let(:channel_id) { 'C024BE91L' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/channels.info', token: token, channel: channel_id) do
          [http_status, {}, http_response]
        end
      end
    end

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
            ok: true,
            channel: {
                id: 'C024BE91L'
            }
        })
      end

      it "returns a response with the Channel's ID" do
        response = subject.channels_info(channel_id)

        expect(response['channel']['id']).to eq(channel_id)
      end
    end

    describe "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'channel_not_found'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.channels_info(channel_id) }.to raise_error(
          "Slack API call to channels.info returned an error: channel_not_found."
        )
      end
    end

    describe "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.channels_info(channel_id) }.to raise_error(
          "Slack API call to channels.info failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#channels_list" do
    let(:channel_id) { 'C024BE91L' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/channels.list', token: token) do
          [http_status, {}, http_response]
        end
      end
    end

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
            ok: true,
            channel: [{
                id: 'C024BE91L'
            }]
        })
      end

      it "returns a response with the Channel's ID" do
        response = subject.channels_list

        expect(response['channel'].first['id']).to eq(channel_id)
      end
    end

    describe "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.channels_list }.to raise_error(
          "Slack API call to channels.list returned an error: invalid_auth."
        )
      end
    end

    describe "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.channels_list }.to raise_error(
          "Slack API call to channels.list failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#groups_list" do
    let(:channel_id) { 'G024BE91L' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/groups.list', token: token) do
          [http_status, {}, http_response]
        end
      end
    end

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
            ok: true,
            groups: [{
                id: 'G024BE91L'
            }]
        })
      end

      it "returns a response with groupss Channel ID's" do
        response = subject.groups_list

        expect(response['groups'].first['id']).to eq(channel_id)
      end
    end

    describe "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.groups_list }.to raise_error(
          "Slack API call to groups.list returned an error: invalid_auth."
        )
      end
    end

    describe "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.groups_list }.to raise_error(
          "Slack API call to groups.list failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#mpim_list" do
    let(:channel_id) { 'G024BE91L' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/mpim.list', token: token) do
          [http_status, {}, http_response]
        end
      end
    end

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
            ok: true,
            groups: [{
                id: 'G024BE91L'
            }]
        })
      end

      it "returns a response with MPIMs Channel ID's" do
        response = subject.mpim_list

        expect(response['groups'].first['id']).to eq(channel_id)
      end
    end

    describe "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.mpim_list }.to raise_error(
          "Slack API call to mpim.list returned an error: invalid_auth."
        )
      end
    end

    describe "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.mpim_list }.to raise_error(
          "Slack API call to mpim.list failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

   describe "#im_list" do
    let(:channel_id) { 'D024BFF1M' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/im.list', token: token) do
          [http_status, {}, http_response]
        end
      end
    end

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
            ok: true,
            ims: [{
                id: 'D024BFF1M'
            }]
        })
      end

      it "returns a response with IMs Channel ID's" do
        response = subject.im_list

        expect(response['ims'].first['id']).to eq(channel_id)
      end
    end

    describe "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.im_list }.to raise_error(
          "Slack API call to im.list returned an error: invalid_auth."
        )
      end
    end

    describe "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.im_list }.to raise_error(
          "Slack API call to im.list failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#send_attachments" do
    let(:attachment) do
      Lita::Adapters::Slack::Attachment.new(attachment_text)
    end
    let(:attachment_text) { "attachment text" }
    let(:attachment_hash) do
      {
        fallback: fallback_text,
        text: attachment_text,
      }
    end
    let(:fallback_text) { attachment_text }
    let(:http_response) { MultiJson.dump({ ok: true }) }
    let(:room) { Lita::Room.new("C1234567890") }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post(
          "https://slack.com/api/chat.postMessage",
          token: token,
          as_user: true,
          channel: room.id,
          attachments: MultiJson.dump([attachment_hash]),
        ) do
          [http_status, {}, http_response]
        end
      end
    end

    context "with a simple text attachment" do
      it "sends the attachment" do
        response = subject.send_attachments(room, [attachment])

        expect(response['ok']).to be(true)
      end
    end

    context "with a different fallback message" do
      let(:attachment) do
        Lita::Adapters::Slack::Attachment.new(attachment_text, fallback: fallback_text)
      end
      let(:fallback_text) { "fallback text" }

      it "sends the attachment" do
        response = subject.send_attachments(room, [attachment])

        expect(response['ok']).to be(true)
      end
    end

    context "with all the valid options" do
      let(:attachment) do
        Lita::Adapters::Slack::Attachment.new(attachment_text, common_hash_data)
      end
      let(:attachment_hash) do
        common_hash_data.merge(fallback: attachment_text, text: attachment_text)
      end
      let(:common_hash_data) do
        {
          author_icon: "http://example.com/author.jpg",
          author_link: "http://example.com/author",
          author_name: "author name",
          color: "#36a64f",
          fields: [{
            title: "priority",
            value: "high",
            short: true,
          }, {
            title: "super long field title",
            value: "super long field value",
            short: false,
          }],
          image_url: "http://example.com/image.jpg",
          pretext: "pretext",
          thumb_url: "http://example.com/thumb.jpg",
          title: "title",
          title_link: "http://example.com/title",
        }
      end

      it "sends the attachment" do
        response = subject.send_attachments(room, [attachment])

        expect(response['ok']).to be(true)
      end
    end

    context "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.send_attachments(room, [attachment]) }.to raise_error(
          "Slack API call to chat.postMessage returned an error: invalid_auth."
        )
      end
    end

    context "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.send_attachments(room, [attachment]) }.to raise_error(
          "Slack API call to chat.postMessage failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#send_messages" do
    let(:messages) { ["attachment text"] }
    let(:http_response) { MultiJson.dump({ ok: true }) }
    let(:room) { "C1234567890" }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post(
          "https://slack.com/api/chat.postMessage",
          token: token,
          as_user: true,
          channel: room,
          text: messages.join("\n"),
        ) do
          [http_status, {}, http_response]
        end
      end
    end

    context "with a simple text attachment" do
      it "sends the attachment" do
        response = subject.send_messages(room, messages)

        expect(response['ok']).to be(true)
      end
    end

    context "with configuration" do
      before do
        allow(config).to receive(:link_names).and_return(true)
      end

      def stubs(postMessage_options = {})
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post(
            "https://slack.com/api/chat.postMessage",
            token: token,
            link_names: 1,
            as_user: true,
            channel: room,
            text: messages.join("\n"),
          ) do
            [http_status, {}, http_response]
          end
        end
      end

      it "sends the message with configuration" do
        response = subject.send_messages(room, messages)

        expect(response['ok']).to be(true)
      end
    end

    context "with a different fallback message" do
      let(:attachment) do
        Lita::Adapters::Slack::Attachment.new(attachment_text, fallback: fallback_text)
      end
      let(:fallback_text) { "fallback text" }

      it "sends the attachment" do
        response = subject.send_messages(room, messages)

        expect(response['ok']).to be(true)
      end
    end

    context "with all the valid options" do
      let(:attachment) do
        Lita::Adapters::Slack::Attachment.new(attachment_text, common_hash_data)
      end
      let(:attachment_hash) do
        common_hash_data.merge(fallback: attachment_text, text: attachment_text)
      end
      let(:common_hash_data) do
        {
          author_icon: "http://example.com/author.jpg",
          author_link: "http://example.com/author",
          author_name: "author name",
          color: "#36a64f",
          fields: [{
            title: "priority",
            value: "high",
            short: true,
          }, {
            title: "super long field title",
            value: "super long field value",
            short: false,
          }],
          image_url: "http://example.com/image.jpg",
          pretext: "pretext",
          thumb_url: "http://example.com/thumb.jpg",
          title: "title",
          title_link: "http://example.com/title",
        }
      end

      it "sends the attachment" do
        response = subject.send_messages(room, messages)

        expect(response['ok']).to be(true)
      end
    end

    context "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.send_messages(room, messages) }.to raise_error(
          "Slack API call to chat.postMessage returned an error: invalid_auth."
        )
      end
    end

    context "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.send_messages(room, messages) }.to raise_error(
          "Slack API call to chat.postMessage failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#set_topic" do
    let(:channel) { 'C1234567890' }
    let(:topic) { 'Topic' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post(
          'https://slack.com/api/channels.setTopic',
          token: token,
          channel: channel,
          topic: topic
        ) do
          [http_status, {}, http_response]
        end
      end
    end

    context "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
          ok: true,
          topic: 'Topic'
        })
      end

      it "returns a response with the channel's topic" do
        response = subject.set_topic(channel, topic)

        expect(response['topic']).to eq(topic)
      end
    end

    context "with a Slack error" do
      let(:http_response) do
        MultiJson.dump({
          ok: false,
          error: 'invalid_auth'
        })
      end

      it "raises a RuntimeError" do
        expect { subject.set_topic(channel, topic) }.to raise_error(
          "Slack API call to channels.setTopic returned an error: invalid_auth."
        )
      end
    end

    context "with an HTTP error" do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it "raises a RuntimeError" do
        expect { subject.set_topic(channel, topic) }.to raise_error(
          "Slack API call to channels.setTopic failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe '#send_file' do
    let(:file) { './Gemfile' }
    let(:http_response) { MultiJson.dump({ ok: true }) }
    let(:room) { Lita::Room.new('C1234567890') }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post(
          'https://slack.com/api/files.upload',
          # token: token,
          # channels: room.id,
          # file: Faraday::FilePart.new(file, mime_type)
        ) do
          [http_status, {}, http_response]
        end
      end
    end

    context 'with a simple file' do
      it 'sends the file' do
        response = subject.send_file(room, file)

        expect(response['ok']).to be(true)
      end
    end

    context 'with a Slack error' do
      let(:http_response) do
        MultiJson.dump(
          {
            ok: false,
            error: 'invalid_auth'
          }
        )
      end

      it 'raises a RuntimeError' do
        expect { subject.send_file(room, file) }.to raise_error(
          'Slack API call to files.upload returned an error: invalid_auth.'
        )
      end
    end

    context 'with an HTTP error' do
      let(:http_status) { 422 }
      let(:http_response) { '' }

      it 'raises a RuntimeError' do
        expect { subject.send_file(room, file) }.to raise_error(
          "Slack API call to files.upload failed with status code 422: ''. Headers: {}"
        )
      end
    end
  end

  describe "#rtm_start" do
    let(:http_status) { 200 }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('https://slack.com/api/rtm.start', token: token) do
          [http_status, {}, http_response]
        end
      end
    end

    describe "with a successful response" do
      let(:http_response) do
        MultiJson.dump({
          ok: true,
          url: 'wss://example.com/',
          users: [{ id: 'U023BECGF' }],
          ims: [{ id: 'D024BFF1M' }],
          self: { id: 'U12345678' },
          channels: [{ id: 'C1234567890' }],
          groups: [{ id: 'G0987654321' }],
        })
      end

      it "has data on the bot user" do
        response = subject.rtm_start

        expect(response.self.id).to eq('U12345678')
      end

      it "has an array of IMs" do
        response = subject.rtm_start

        expect(response.ims[0].id).to eq('D024BFF1M')
      end

      it "has an array of users" do
        response = subject.rtm_start

        expect(response.users[0].id).to eq('U023BECGF')
      end

      it "has a WebSocket URL" do
        response = subject.rtm_start

        expect(response.websocket_url).to eq('wss://example.com/')
      end
    end
  end
end
