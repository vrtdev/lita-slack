# frozen_string_literal: true

require 'mock_redis'

module Lita
  class <<self
    undef redis
    def redis
      @mocked_redis ||= MockRedis.new
    end
  end
end

