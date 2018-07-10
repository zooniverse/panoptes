# Policies

Our policy objects are the heart of the authorizations in Panoptes. Roughtly
speaking they perform three functions:

1. The `Scope` objects determine which models a user is allowed to access.
2. The `index?` methods authorize each user for a specific controller action.
3. The `linkable_xyz` methods return a list of valid Xyzs for a specific model's association.


## Scopes

A scope object gets initialized with an ApiUser and a initial
ActiveRecord::Relation query object. If you don't have an initial filter, you
can simply initialize with the class of the model, e.g.

    WorkflowPolicy.new(api_user, Workflow)

A general template for a policy is given below. The `Scope < Scope` syntax might
be unfamiliar, but merely means `Scope < ApplicationPolicy::Scope`. Each Scope
must implement the `resolve(action)` method, which must return an AR relation.

The `action` parameter represents the current controller action. This is needed
because a user might be able to get resources, but not update them. You can
either branch on this inside the `resolve` method, or implement multiple
different scope classes and use the `scope :action, :action, with: Scope` DSL to
define which actions use which scopes.

```ruby
class FooPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve(action)
      scope
    end
  end

  scope :index, :show, with: Scope
end
```

## Linkable

In order to specify which things can be put into associations, you must
implement a method called `linkable_xyz`. Substitute xyz for the name of
the association.

Generally speaking, these methods will take the form of:

```ruby
class WorkflowPolicy < ApplicationPolicy
  def linkable_projects
    policy_for(Project).scope_for(:update)
  end
end
```

The `policy_for` and `scope_for` methods are defined in `ApplicationPolicy` and
is merely shorter way of writing:

    ProjectPolicy::WriteScope.new(user, Project).resolve(:update)
