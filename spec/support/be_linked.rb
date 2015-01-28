RSpec::Matchers.define :link_to do |rel|
  chain :with_scope do |scope_method, *args|
    @scope, @scope_args = scope_method, args
  end

  chain :given_args do |*args|
    @args = args
  end

  description do
    "allow links for #{ rel.name } "
  end

  failure_message do
    "expected #{ @link_scope.to_sql } to eq #{ @scope_scope.to_sql }"
  end

  match do |actual|
    link_to_args = @args || [double]
    link_model = rel.is_a?(Class) ? rel.new : rel
    @link_scope = actual.link_to_resource(link_model, *link_to_args)
    @scope_scope = actual.send(@scope, *@scope_args)

    @link_scope.to_sql == @scope_scope.to_sql
  end
end
