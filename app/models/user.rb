class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  has_many :stakeholders
  has_many :apps, :through => :stakeholders, :class_name => 'App'

  has_many :cmd_sets, :foreign_key => "owner_id"

  def is_admin
    stakeholders.select do |record|
      record.role_id == Role::Admin
    end.length > 0
  end
end



