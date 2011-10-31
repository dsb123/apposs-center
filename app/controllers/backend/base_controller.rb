class Backend::BaseController < InheritedResources::Base

  before_filter :authenticate_user!
  before_filter :authenticate_admin!

  layout 'backend'
    
  def authenticate_admin!
    if !current_user.is_admin?
      redirect_to root_path
    end
  end

end
