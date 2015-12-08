module MatchForAction
  def match_for_action(actual, roles, action)
    actual.class.instance_variable_get(:@roles_for)[action]
      .instance_variable_get(:@roles) == roles
  end
end

RSpec::Matchers.define :permit_roles do |*roles|
  include MatchForAction

  chain :for_action do |action|
    @action = action
  end

  description do
    "permit roles #{ roles.join(", ") } for #{ @action }"
  end

  match do |actual|
    match_for_action(actual, roles, @action)
  end
end

RSpec::Matchers.define :permit_field do |field|
  include MatchForAction

  chain :for_action do |action|
    @action = action
  end

  description do
    "permits using field #{ field } for #{ @action }"
  end

  match do |actual|
    match_for_action(actual, field, @action)
  end
end
