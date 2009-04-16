module HomeHelper
  
  def has_new_posts(categories)
    return false unless categories and current_user
    categories.each do |category|
      category.forums_with_unread_id(current_user).each do |forum|
        return true unless current_user.profile.last_read_post_id
        return true if forum.last_post_id && current_user.profile.last_read_post_id < forum.last_post_id
      end
    end
    return false
  end
  
end
