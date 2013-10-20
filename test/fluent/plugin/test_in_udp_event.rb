# -*- encoding: utf-8 -*-

require 'helper'

class UdpEventInputTest < Test::Unit::TestCase
	def setup
		Fluent::Test.setup
		require 'fluent/plugin/socket_util'
	end

	PORT = unused_port
	CONFIG = %[
		port #{PORT}
		bind 127.0.0.1
	]

	IPv6_CONFIG = %[
		port #{PORT}
		bind ::1
	]

	def create_driver(conf=CONFIG)
		Fluent::Test::InputTestDriver.new(Fluent::UdpEventInput).configure(conf)
	end

	def test_configure
		configs = {'127.0.0.1' => CONFIG}
		configs.merge!('::1' => IPv6_CONFIG) if ipv6_enabled?

		configs.each_pair {|k, v|
			d = create_driver(v)
			assert_equal PORT, d.instance.port
			assert_equal k, d.instance.bind
		}
	end

	def test_receive_data
		d = create_driver

		tests = [
			["test.route", Time.now.to_i, {"data" => "test1"}],
			["test.route", Time.now.to_i, {"data" => "test2"}],
			["test.route", Time.now.to_i, {"data" => "test3"}]
		]

		d.run do
			@loop = d.instance.instance_variable_get(:@loop)

      		#Force event every 0.1 to prevent 60 second timeout, see ext/libev/ev.c MAX_BLOCKTIME
  			@watcher = Cool.io::TimerWatcher.new(0.1, true)
  			@loop.attach(@watcher)

			u = UDPSocket.new
			u.connect('127.0.0.1', PORT)
			tests.each { |message|
				u.send(JSON.generate(message), 0)
			}

			sleep 0.2
		end

		assert_equal d.emits, tests
	end

	def test_invalid_message
		d = create_driver

		d.run do
			@loop = d.instance.instance_variable_get(:@loop)

      		#Force event every 0.1 to prevent 60 second timeout, see ext/libev/ev.c MAX_BLOCKTIME
  			@watcher = Cool.io::TimerWatcher.new(0.1, true)
  			@loop.attach(@watcher)

			u = UDPSocket.new
			u.connect('127.0.0.1', PORT)
			u.send("invalid_json", 0)

			sleep 0.2
		end

		assert_equal d.emits.length, 0
	end

	def test_invalid_structure
		d = create_driver

		d.run do
			@loop = d.instance.instance_variable_get(:@loop)

      		#Force event every 0.1 to prevent 60 second timeout, see ext/libev/ev.c MAX_BLOCKTIME
  			@watcher = Cool.io::TimerWatcher.new(0.1, true)
  			@loop.attach(@watcher)

			u = UDPSocket.new
			u.connect('127.0.0.1', PORT)
			u.send(JSON.generate([]), 0)

			sleep 0.2
		end

		assert_equal d.emits.length, 0
	end

	def test_enormous_message
		d = create_driver

		d.run do
			@loop = d.instance.instance_variable_get(:@loop)

      		#Force event every 0.1s to prevent 60 second timeout, see ext/libev/ev.c MAX_BLOCKTIME
  			@watcher = Cool.io::TimerWatcher.new(0.1, true)
  			@loop.attach(@watcher)

			u = UDPSocket.new
			u.connect('127.0.0.1', PORT)
			u.send(JSON.generate(["test", Time.now.to_i, 'x' * 1500]), 0)

			sleep 0.2
		end

		assert_equal d.emits.length, 0
	end
end