#encoding: utf-8
class StaticPagesController < ApplicationController

  layout 'landing'

  def show
    @static_page = StaticPage.find_by_key(params[:key])
    render "home/#{params[:key]}"
  end

  # GET /blogs/1/edit
  def edit
    @static_page =StaticPage.find_by_key(params[:key])
  end


  def update

    if params[:button] == 'save'
      @static_page =StaticPage.find_by_key(params[:key])

      respond_to do |format|
        if @static_page.update_attributes(params[:static_page])
          flash[:notice] = t('controllers.static_pages.update.ok_message')
          format.html { redirect_to "/#{params[:key]}" }
        else
          format.html { render :action => "edit" }
        end
      end
    else
      @static_page = StaticPage.new(params[:static_page])
      @static_page.key = params[:key]
      render "home/#{params[:key]}"
    end

  end

end
