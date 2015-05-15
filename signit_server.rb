require 'sinatra/base'
require 'rack/ssl'

class Application < Sinatra::Base
    #use Rack::SSL -- not working on windows
    set :bind, '0.0.0.0' 
    set :port, 51830
   @@signatures_by_user = {}
   @@signatures_by_docsha = {}

    before do
      request.body.rewind
      @request_payload = request.body.read
    end

    post('/user/:name/signatures') do |name|
        sigs = (@@signatures_by_user[name] ||= [])
        sigs << @request_payload

        sha = params["sha"] 
        sigs = (@@signatures_by_docsha[sha] ||= [])
        sigs << @request_payload

        "ok"
    end

    get('/user/:name/') do |name|
        content_type 'text/text'
        (@@signatures_by_user[name]||[]).join( "\n\n" )
    end

    get('/signatures/:docsha') do |docsha|
        content_type 'text/text'
        "Keys: \n\n" + 
        (@@signatures_by_docsha[docsha]||[]).join( "\n\n" )
    end

   run! if app_file == $0
end
