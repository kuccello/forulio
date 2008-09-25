
module UserHelper
  include HTMLTextUtils

  def order_path_for (name)
    url = {:action=>'list', :order=>name}
    unless params[name].nil? and params[:desc] == '1'
      url[:desc] = "1"
    end
    url
  end
  
  def get_username_or_me(profile, capitalize_if_me = false)

    return capitalize_if_me ? "my"[:my].capitalize : "my"[:my] if current_user and profile.user_id == current_user.id
    profile.user.login
  end
end
