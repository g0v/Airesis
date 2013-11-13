class Tutorial < ActiveRecord::Base  
  has_many :steps, :class_name => 'Step', :order => "index asc", :dependent => :destroy
  has_many :assignees, :class_name => 'TutorialAssignee', :dependent => :destroy
  has_many :users, :through => :assignees, :class_name => 'User'
end
