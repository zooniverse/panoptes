# How does it know whether a user can point a foreign key at some resource?

`can_be_linked` on the foreign resource specifies this. Essentially, to make it
so that a user can create a SubjectSet with project_id=1, in Project you must 
define:

```ruby
class Project
  include Linkable
  can_be_linked :subject_set, :scope_for, :update, :user
end
```

This makes it so that any user who can `update` the project `Project.find(1)`, can 
`SubjectSet.create(project_id: 1)`.