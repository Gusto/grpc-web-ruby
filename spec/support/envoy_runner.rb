# frozen_string_literal: true

require 'pty'
require 'json'
require 'socket'
require 'uri'

# This class is used only during local development. It is responsible for
# starting the Envoy automatically when running tests that depend
# on it, and will shutdown the Envoy at the completion of the spec run.
class EnvoyRunner
  ENVOY_DOCKER_IMAGE = 'envoyproxy/envoy:latest'
  DOCKER_CONTAINER_NAME = 'rspec-envoy'
  DOCKER_HOST = 'docker.for.mac.localhost'
  ENVOY_PORT = 8080

  class << self
    attr_accessor :envoy_pid

    def start_envoy
      if envoy_is_running?
        log 'Envoy is already running.'
        return
      end

      log 'Envoy is not running. Starting Envoy...'
      cmd = envoy_cmd
      log "Running Envoy with: #{cmd}"

      stop_existing_container_if_running

      if envoy_port_in_use?
        msg = "Envoy port #{ENVOY_PORT} is in use by another process."
        Kernel.warn("\n\n[FATAL] #{msg}\n\n")
        exit(1)
      end

      run_cmd_in_background(cmd)
      register_exit_handler

      30.times do # Wait for container to be running with 3 sec timeout
        return if docker_container_sha_for_envoy

        sleep 0.1
      end
      raise 'Envoy proxy failed to start'
    end

    def docker_container_sha_for_envoy
      result = `docker ps -q -f name=#{DOCKER_CONTAINER_NAME}`&.strip
      result unless result == ''
    end

    def stop_envoy
      return unless docker_container_sha_for_envoy

      log 'Stopping Envoy...'
      `docker stop #{docker_container_sha_for_envoy}`
      log 'Waiting for Envoy to exit...'
      30.times do # Wait for container to stop running with 3 sec timeout
        break if ::EnvoyRunner.docker_container_sha_for_envoy.nil?

        sleep 0.1
      end
      log 'Envoy shutdown complete.'
    end

    private

    attr_accessor :exit_handler_registered

    def log(msg)
      formatted_msg = "[ENVOY] #{msg}"
      # puts formatted_msg
    end

    def envoy_is_running?
      envoy_pid && docker_container_sha_for_envoy
    end

    def envoy_port_in_use?
      begin
        sock = Socket.new(Socket::Constants::AF_INET, Socket::Constants::SOCK_STREAM, 0)
        sock.bind(Socket.pack_sockaddr_in(ENVOY_PORT, '0.0.0.0'))
        sock.close
      rescue Errno::EADDRINUSE
        return true
      end

      false
    end

    def stop_existing_container_if_running
      existing_container_sha = docker_container_sha_for_envoy
      if existing_container_sha
        log "Found old Envoy container #{existing_container_sha} still running..."
        stop_envoy
        log "Stopped old Envoy container #{existing_container_sha}."
      end
    end

    def envoy_cmd
      [
        'docker run --rm',
        "-p #{ENVOY_PORT}:#{ENVOY_PORT}",
        "-v \"#{File.expand_path('envoy.yml', __dir__)}:/etc/envoy/envoy.yaml\"",
        "--name #{DOCKER_CONTAINER_NAME}",
        ENVOY_DOCKER_IMAGE,
      ].join(' ')
    end

    def run_cmd_in_background(cmd)
      Thread.new do
        PTY.spawn(cmd) do |_stdout, _stdin, pty_pid|
          ::EnvoyRunner.envoy_pid = pty_pid
        end
      rescue PTY::ChildExited
        log 'The Envoy child PTY process exited!'
      end
    end

    def register_exit_handler
      return if exit_handler_registered

      at_exit do
        ::EnvoyRunner.stop_envoy
      end

      self.exit_handler_registered = true
    end
  end
end
