# Policies

Our policy objects are the heart of the authorizations in Panoptes. This guide
will give examples centered around the Collection model, but substitute for
your needs. Roughly speaking policy objects perform three functions:

1. The `Scope` objects determine which records a user is allowed to access.
2. The `update?` method authorizes a user for a specific controller action.
3. The `linkable_users` method returns a list of valid workflows for a
   specific model's association.

## Scopes

A scope object gets initialized with an ApiUser and a initial
ActiveRecord::Relation query object. If you don't have an initial filter, you
can simply initialize with the class of the model, e.g.

    CollectionPolicy::ReadScope.new(api_user, Collection)

A general template for a policy is given below.

```ruby
class CollectionPolicy < ApplicationPolicy
  class ReadScope < Scope
    def resolve(action)
      scope
    end
  end

  scope :index, :show, with: ReadScope
end
```

First of all, the `Scope < Scope` syntax is likely to be unfamiliar, but merely
means `Scope < ApplicationPolicy::Scope`. Each Scope must implement the
`resolve(action)` method, which must return an AR relation.

The `scope` DSL method is an extension to Pundit that we've made, and
determines which controller actions use which scope object. This makes it
possible to define multiple Scope objects, so that e.g. the `update` action
only finds projects that the user is a collaborator of, while the `show` action
can find any publicly visible project.

The `action` parameter to the `resolve` method represents the current
controller action. This is needed because a user might be able to get
resources, but not update them. You can either branch on this inside the
`resolve` method, or implement multiple different scope classes and use the
`scope :action, :action, with: Scope` DSL to define which actions use which
scopes.

## `action?` methods

This is a [standard Pundit feature](https://github.com/varvet/pundit#policies).
These methods can be called anything, but typically are named after the
controller actions suffixed with a question mark. The controller can then call
`authorize(project)` to check this.

*Note*: We don't currently use this. Nearly all actions will not be able to find
any resource that the user isn't allowed to act upon. A good example of something
that could use this would be `ProjectsController#create_classifications_export`
which has this as a `before_filter`:

https://github.com/zooniverse/Panoptes/blob/fddc6e38dd4d1d61f3b767b2b3904d5496286a8a/app/controllers/api/v1/projects_controller.rb#L187

## Linkable resources

In order to specify which things can be put into associations, you must
implement a method called `linkable_xyz`. Substitute xyz for the name of
the association.

Generally speaking, these methods will take the form of:

```ruby
class CollectionPolicy < ApplicationPolicy
  def linkable_subjects
    policy_for(Subject).scope_for(:show)
  end
end
```

The `policy_for` and `scope_for` methods are defined in `ApplicationPolicy` and
is merely shorter way of writing:

    SubjectPolicy::Scope.new(user, Subject).resolve(:show)
