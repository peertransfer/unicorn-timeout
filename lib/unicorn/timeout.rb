module Unicorn
  class Timeout
    @timeout = 25

    class << self
      attr_accessor :timeout
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      t = setup_mon_thread

      begin
        @app.call(env)
      ensure
        kill_mon_thread(t)
      end
    end

    private

    def setup_mon_thread
      main_thread = Thread.current

      Thread.new do
        sleep(self.class.timeout)
        main_thread.raise 'Unicorn::Timeout'
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
