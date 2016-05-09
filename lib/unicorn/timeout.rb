module Unicorn
  class Timeout
    @timeout = 15
    @handler = lambda { |backtrace, env|
      STDERR.puts("Unicorn::Timeout is killing worker ##{Process.pid} with backtrace:\n#{backtrace.join("\n")}\n and ENV:\n #{env.inspect}")
    }
    @signal = 'TERM'

    class << self
      attr_accessor :timeout
      attr_accessor :handler
      attr_accessor :signal
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      t = setup_mon_thread(env)

      begin
        @app.call(env)
      ensure
        kill_mon_thread(t)
      end
    end

    private

    def setup_mon_thread(env)
      main_thread = Thread.current

      Thread.new do
        sleep(self.class.timeout)
        kill_main_thread(main_thread, env)
      end
    end

    def kill_main_thread(t, env)
      Thread.exclusive do
        begin
          self.class.handler.call(t.backtrace, env)
        ensure
          Process.kill(self.class.signal, Process.pid)
        end
      end
    end

    def kill_mon_thread(t)
      Thread.exclusive do
        t.kill
        t.join
      end
    end
  end
end
