module Frm
  class Group < FrmTable
    validates :name, :presence => true

    has_many :memberships
    has_many :members, :through => :memberships, :class_name => 'User'

    attr_accessible :name

    def to_s
      name
    end
  end
end