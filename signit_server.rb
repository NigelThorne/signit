require 'sinatra'
require 'rack/ssl'

class Application < Sinatra::Base
    use Rack::SSL
    set :bind, '0.0.0.0' 
   @@signatures = {}

    before do
      request.body.rewind
      @request_payload = request.body.read
    end

    post('/user/:name/signatures') do |name|
        sigs = (@@signatures[name] ||= [])
        sigs << @request_payload
        "ok"
    end

    get('/user/:name/') do |name|
        content_type 'text/text'
        @@signatures[name].join( "\n\n" )
    end
    run! if app_file == $0
end
