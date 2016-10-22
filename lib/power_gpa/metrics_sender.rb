require 'librato-rack'

module PowerGPA
  class MetricsSender
    def initialize(app)
      @app = app
    end

    def call(env)
      res = @app.call(env)
      Librato.tracker.flush
      res
    end
  end
end
