require 'sinatra/base'
require 'net-ldap'
require 'digest/sha1'
require 'base64'

#require 'rack/ssl'
#require 'openssl'

module Ldap

#  LDAP_HOST = "vslmel-dc01.vsl.com.au"
#  ADMIN_DN = 'cn=admin,dc=company,dc=com'
#  PEOPLE_DN = 'ou=people,dc=company,dc=com'
#  PEOPLE_FILTER = Net::LDAP::Filter.eq('objectClass', 'inetOrgPerson')
#  PREFIX = '/ldap'

#  dn = "uid=#{uid}," + PEOPLE_DN
#  @people = ldap.search(
#    :base => PEOPLE_DN, 
#    :filter => PEOPLE_FILTER)

#  ldap.bind(:method => :simple, :username => dn, :password => password)


  ldap = Net::LDAP.new(:host => "vslmel-dc01.vsl.com.au", :port => 389)
  treebase = "dc=hsit, dc=ac, dc=in"
  ldap.auth "uid=#{@username},ou=people,#{treebase}", "#{@password}"

  ldap = Net::LDAP.new(
    :host => "vslmel-dc01.vsl.com.au",
    :port => 389,
    :base => "ou=Exchange,dc=vsl,dc=com,dc=au",
    :auth => {
      :method => :simple,
      :username => "addressbook@vsl.com.au", 
      :password => "addressbook"
    }
  )
  if ldap.bind
    search_filter = 
      Net::LDAP::Filter.eq('objectClass', 'Person') &
      Net::LDAP::Filter.eq('objectClass', 'User') &
      Net::LDAP::Filter.eq('sAMAccountName',username) 

    results = ldap.search(:filter => search_filter) 

    if(results.count > 0 )
      return {name: results.first.sAMAccountName.first, display_name: results.first.displayname, email: results.first.proxyaddresses[0].split(":")[1]}
    end

  end

end


class Application < Sinatra::Base
  #use Rack::SSL -- not working on windows
  configure :production, :development do
    enable :logging
    enable :sessions
    set :bind, '0.0.0.0' 
    set :port, 51830
  end
  helpers do
    def unauthorized!
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      return false unless @auth.provided? and @auth.basic? and @auth.credentials
      @user = DirectoryUser.authenticate(*@auth.credentials)
      if @user
        session[:user_id] = @user.id
        session[:username] = @auth.credentials[0]
      else
    end

  @@signatures_by_user = {}
  @@signatures_by_docsha = {}
  @@keypairs_by_user = {}

  before do
    request.body.rewind
    @request_payload = request.body.read
  end

  
=begin comment
  A signature includes: 
  * Signatory : LDAP identity from Basic Auth
  * Reason : text in post
  * TimeStamp : DateTime.now
  * Document fingerprint : URLEncoded (BASE64Encoded( SHA1 ( doc_content )) 
  A verified signature should also contain
  * notarization fingerprint : calculated and stored to prove the above data is correct, (ie the signatory agreed to the above data)
=end
  post('/documents/:doc_fingerprint/signatures') do |doc_fingerprint|
    unauthorized! unless authorized? # sets username and user_id in session

    make_signature(@user, doc_fingerprint, params[:reason] )

    sigs = (@@signatures_by_user[name] ||= [])
    sigs << @request_payload

    sha = params["sha"] 
    sigs = (@@signatures_by_docsha[sha] ||= [])
    sigs << @request_payload

    "ok"
  end


  post('/user/:name/signatures') do |name|


    sigs = (@@signatures_by_user[name] ||= [])
    sigs << @request_payload

    sha = params["sha"] 
    sigs = (@@signatures_by_docsha[sha] ||= [])
    sigs << @request_payload

    "ok"
  end

  get('/user/:name/signatures') do |name|
    content_type 'text/text'
    (@@signatures_by_user[name]||[]).join( "\n\n" )
  end

  get('/signatures/:docsha') do |docsha|
    content_type 'text/text'
    "Keys: \n\n" + 
    (@@signatures_by_docsha[docsha]||[]).join( "\n\n" )
  end

  get('/user/:name/public_keys') do |name|
    content_type 'text/text'
    (keypairs_by_user[session[:user_id]] || []).map{|k|k[:public_key]}.join("\n\n")   
  end

  get('/user/:name/private_keys') do |name|
    unauthorized! unless authorized? && session[:username] == name
    content_type 'text/text'
    (keypairs_by_user[session[:user_id]] || []).map{|k|k[:private_key]}.join("\n\n")   
  end

  def get_key(username)
    keypairs_by_user[username] ||= begin
      @@keypair_repository ||= KeyPairRepository.new
      @@keypair_repository.
    end
  end

  def encode(text, username)
    OpenSSL::PKey::RSA.new()
  end

  def decode(text, username)
  end

  run! if app_file == $0
end



class NotaryService
  def encrypt(document, username_id)
    Base64.encode64(public_key(user_id).public_encrypt(string))
  end

  def public_keys(user_id)
  end

  def private_keys(user_id)
  end

end
__END__
#!/usr/bin/env ruby

# ENCRYPT

public_key_file = 'public.pem';
string = 'Hello World!';

public_key = OpenSSL::PKey::RSA.new(File.read(public_key_file))
encrypted_string = Base64.encode64(public_key.public_encrypt(string))
And decrypt:

#!/usr/bin/env ruby

# DECRYPT

require 'openssl'
require 'base64'

private_key_file = 'private.pem';
password = 'boost facile'

encrypted_string = %Q{
  ...
}
