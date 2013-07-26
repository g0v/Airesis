Forem::ForumsController.class_eval do
  before_filter :load_group

  layout 'groups'

  def index
    @categories = @group.forum_categories
  end

  def show
    register_view

    raise Exception unless @group.forums.include? @forum

    @topics = if forem_admin_or_moderator?(@forum)
                @forum.topics
              else
                @forum.topics.visible.approved_or_pending_review_for(forem_user)
              end

    @topics = @topics.by_pinned_or_most_recent_post.page(params[:page]).per(Forem.per_page)

    respond_to do |format|
      format.html
      format.atom { render :layout => false }
    end
  end

  protected

  def load_group
    @group = Group.find(params[:group_id])
  end
end