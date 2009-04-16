class Admin::CategoryController < ApplicationController
  before_filter :admin_required
  def new
    @category = Category.new
    render :update do |page|
      page.replace_html  "create_category", render(:partial => 'new', :locals=>{:category => @category})
      page.visual_effect :Appear,  'create_category'
    end
  end
  
  def create
    @category = Category.new(params[:category])
    @category.position = Category.count()
    render :update do |page|
      if @category.save
          page.call "Category.insert", render(:partial => 'home/category', :locals=>{:category => @category, :show_category=>false})
          page << "Category.cancelCreate();"
      else
          page.replace_html  "create_category", render(:partial => 'new', :locals=>{:category => @category, :show_category=>false})
          page.visual_effect :Highlight,  'create_category'
      end
    end
  end

  def delete
    @category = Category.find(params[:id])
    render :update do |page| 
         page << (@category.destroy ? "Category.remove('#{@category.id}')" : "alert('%s')") % ["Category can not be deleted"[:category_cannot_be_deleted]]
    end
  end
  
  def load_title
     render :text=>Category.find(params[:id]).title
  end
  
  def update_title
      @category = Category.find(params[:id])
      @category.title = params[:value]
      if @category.save
        render :layout => false, :inline => @category.title
      else
        render_javascript_error_for(@category)
      end
  end
 
end
