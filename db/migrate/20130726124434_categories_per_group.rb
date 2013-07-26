class CategoriesPerGroup < ActiveRecord::Migration
  def up
    add_column :forem_categories, :group_id, :integer
    Forem::Category.update_all(:group_id => 1)
    change_column :forem_categories, :group_id, :integer, :null => false
  end

  def down
    remove_column :forem_categories, :group_id
  end
end
