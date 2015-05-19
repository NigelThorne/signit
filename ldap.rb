require 'active_directory'

module Ldap

  ActiveDirectory::Base.setup(
    :host => "vslmel-dc01.vsl.com.au",
    :port => 389,
    :base => "ou=Exchange,dc=vsl,dc=com,dc=au",
    :auth => {
	:method => :simple,
		:username => "addressbook@vsl.com.au", 
		:password => "addressbook"
    }
  )

  public 
  def self.is_user?(username)
      user = ActiveDirectory::User.find(:first, :filter => {"ObjectClass"=>"Person","ObjectClass"=>"User", "sAMAccountName"=>username})
      user != nil
  end
  
  def self.authenticate(username, password)
      user = ActiveDirectory::User.find(:first, :filter => 
        {"ObjectClass"=>"Person",
         "ObjectClass"=>"User", 
         "sAMAccountName"=>username})
      return false if user.nil?
      user.authenticate(password)!= false
  end


end

