#encoding: utf-8
class BlogsController < ApplicationController
  # GET /blogs
  # GET /blogs.xml
  layout :choose_layout
  
  before_filter :authenticate_user!, :only => [ :edit, :update, :destroy, :new, :create ]
  before_filter :check_author, :only => [:edit, :update, :destroy]
  
  
   def check_author
    @blog = Blog.find(params[:id])
    if !(current_user.is_my_blog? @blog.id) && !is_admin?
      flash[:notice] = t('error.blog.cannot_edit')
      redirect_to :back
    end
   end
  
  def index
    @page_title = t('pages.gs.show.title')
    @blogs = Blog.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @blogs }
    end
  end
  
  # GET /blogs/1
  # GET /blogs/1.xml
  def show
    @blog = Blog.find(params[:id])
    @user = @blog.user
    @page_title = @blog.title
    @blog_posts = @blog.posts.published.includes(:user,:blog,:tags).paginate(:page => params[:page], :per_page => COMMENTS_PER_PAGE, :order => 'published_at DESC')

    respond_to do |format|
      format.js
      format.html # show.html.erb
      #format.xml  { render :xml => @blog }
    end
  end

  # GET /blogs/new
  # GET /blogs/new.xml
  def new
    if current_user.blog
      flash[:error] = t('error.blog.already_have')
      redirect_to root_path
    else
      @user = current_user
      @blog = Blog.new

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @blog }
      end
    end
  end

  # GET /blogs/1/edit
  def edit
    @blog = Blog.find(params[:id])
    @user = @blog.user
  end

  # POST /blogs
  # POST /blogs.xml
  def create
    
    params[:blog][:user_id] = current_user.id
    @blog = Blog.new(params[:blog])

    respond_to do |format|
      if @blog.save
        flash[:notice] = t('info.blog.blog_created')
        format.html {
          if session[:blog_return_to]
            redirect_to session[:blog_return_to]
          else
            redirect_to(@blog) 
          end
        }
        #format.xml  { render :xml => @blog, :status => :created, :location => @blog }
      else
        format.html { render :action => "new" }
        #format.xml  { render :xml => @blog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /blogs/1
  # PUT /blogs/1.xml
  def update
    @blog = Blog.find(params[:id])

    respond_to do |format|
      if @blog.update_attributes(params[:blog])
        flash[:notice] = t('info.blog.title_updated')
        format.html { redirect_to(@blog) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @blog.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /blogs/1
  # DELETE /blogs/1.xml
  def destroy
    @blog = Blog.find(params[:id])
    @blog.destroy

    respond_to do |format|
      format.html { redirect_to(blogs_url) }
      format.xml  { head :ok }
    end
  end
  
  protected
  
  def choose_layout
    params[:action] == 'index' ? 'settings' : 'users'
  end
  
  
end
