Forem::Forum.class_eval do
  # Fix for #339
  default_scope reorder('forem_forums.name ASC')
end