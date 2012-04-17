class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :role, :name, :email, :password, :password_confirmation, :remember_me
  
  def role?(role)  	
  	#raise role.to_s.camelize.inspect  	
  	return !!User.find_by_role(role.to_s.camelize)  	
    #return !!self.roles.find_by_name(role.to_s.camelize)
	end
	

end
