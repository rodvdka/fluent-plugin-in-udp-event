# -*- encoding: utf-8 -*-

#
# Fluent Input Plugin UDP Event
#
# Copyright (C) 2013 Alexander Blagoev

module Fluent
  # Fluentd UDP input main class
  class UdpEventInput < Input
    MAX_BLOCKTIME = 2

    Plugin.register_input('udp_event', self)

    def initialize
      super
      require 'fluent/plugin/socket_util'
    end

    config_param :port, :integer, default: 242_24
    config_param :bind, :string, default: '0.0.0.0'
    config_param :max_message_size, :integer, default: 1024

    def configure(conf)
      super
    end

    def start
      callback = method(:receive_data)

      @loop = Coolio::Loop.new

      $log.debug "listening udp socket on #{@bind}:#{@port}"
      @usock = SocketUtil.create_udp_socket(@bind)
      @usock.bind(@bind, @port)

      @handler = UdpHandler.new(@usock, @max_message_size, callback)
      @loop.attach(@handler)

      @thread = Thread.new(&method(:run))
    end

    def shutdown
      # Force event every MAX_BLOCKTIME seconds to prevent 60 second timeout
      # see ext/libev/ev.c MAX_BLOCKTIME
      @watcher = Cool.io::TimerWatcher.new(MAX_BLOCKTIME, true)
      @loop.attach(@watcher)

      $log.debug 'stopping event loop'
      begin
        @loop.stop
      rescue RuntimeError
      end

      $log.debug "closing udp socket on #{@bind}:#{@port}"
      @handler.close

      $log.debug 'closing watchers'
      @loop.watchers.each { |w| w.detach }

      $log.debug 'waiting for thread to finish'
      @thread.join
      $log.debug 'thread finished'
      $log.debug 'terminating'
    end

    def run
      @loop.run
    rescue Exception => e
      $log.error 'unexpected error', error: e.message
      $log.error_backtrace
    end

    protected

    def receive_data(data)
      if data.bytesize == @max_message_size
        $log.warn "message might be too big and truncated to #{@max_message_size}"
      end

      begin
        parsed = JSON.parse(data)
      rescue JSON::ParserError => e
        $log.warn 'invalid json data', error: e.message
        return
      end

      tag = parsed['tag']
      time = parsed['time'].to_i
      record = parsed['record']

      if tag.nil? || time.nil? || record.nil?
        $log.warn "invalid message supplied #{data}"
        return
      end

      time ||= Engine.now

      Engine.emit(tag, time, record)
    rescue Exception => e
      $log.warn data.dump, error: e.message
      $log.debug_backtrace
    end

    private

    # Class to handle the UDP layer
    class UdpHandler < Coolio::IO
      def initialize(io, max_message_size, callback)
        super(io)
        @io = io
        @callback = callback
        @max_message_size = max_message_size
      end

      def on_readable
        msg, _ = @io.recvfrom_nonblock(@max_message_size)
        @callback.call(msg)
      rescue Exception => e
        $log.error e.message, error: e.message
      end
    end
  end
end
