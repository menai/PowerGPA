class App
    def call(env)
        [200, {}, ["Hello World."]]
    end
end

run App.new