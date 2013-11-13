class PostPublishing < ActiveRecord::Base
  belongs_to :blog_post, :class_name => 'BlogPost', :foreign_key => :blog_post_id
  #has_one :partecipation_role, :class_name => 'PartecipationRole', :foreign_key => :partecipation_role_id
  belongs_to :group, :class_name => 'Group', :foreign_key => :group_id
end
