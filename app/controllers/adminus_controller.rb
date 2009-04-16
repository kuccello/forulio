class AdminusController < ApplicationController
  before_filter :admin_required
  
  def update_counters
    AdminHelper.normalize_counters  
    render :nothing=>true
  end
  
  def se_index
    SeIndex.reindex(:all=>true) if current_user.has_role?('admin')
    render :nothing=>true
  end
  

  
end
