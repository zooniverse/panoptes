module Subjects
  class PostgresqlSelection
    attr_reader :workflow, :user, :opts

    def initialize(workflow, user=nil, options={})
      @workflow, @user, @opts = workflow, user, options
    end

    def select
      selection_strategy.new(available, limit).select
    end

    private

    def selection_strategy
      if workflow.prioritized
        PostgresqlInOrderSelection
      else
        PostgresqlRandomSelection
      end
    end

    def available
      query = Subjects::SetMemberSubjectSelector.new(workflow, user).set_member_subjects
      subject_set_ids = if workflow.grouped
                          # respect the user if they want to select from a training set
                          Array.wrap(opts[:subject_set_id])
                        else
                          # default mode: do not select from training sets
                          workflow.non_training_subject_sets.pluck(:id)
                        end
      if Gem::Version.new(Rails.version) > Gem::Version.new('5.0') && Gem::Version.new(Rails.version) < Gem::Version.new('5.2')
        # Handle a bug when the rails 5.0 AR scope bind params merge in rails 5.0 (works fine in 4.2)
        #
        # failed fix 1 - ensure the subject_set_id param clause is before the id clause
        #
        # SetMemberSubject.where(subject_set_id: subject_set_ids, id: query).select(:id)
        #
        # as that fixes the incorrect subject_set_id bind param - fails to bind limit correctly later on :(
        #
        # failed fix 2 - leave as is but wrap subject set ids in array
        #
        # query.where(subject_set_id: subject_set_ids)
        #
        # duplicate query clauses which make no sense and can be cleaned up
        # but it still fails on the limit bind param fails later on :(
        #
        # failed fix 3 - tried to merge the AR queries manually
        #
        # query.merge(SetMemberSubject.where(subject_set_id: subject_set_ids))
        #
        # fixes the duplicate query clause but still fails on the limit bind param later on :(
        #
        # failed fix 4 - use an explicit sub query
        #
        # SetMemberSubject.where(subject_set_id: subject_set_ids, id: SetMemberSubject.select('id').from(query)).select(:id)
        #
        # fixes the subject set id bind param but still fails on the limit bind param later on :(

        # Working solution
        #
        # run two queries
        # one with with a pluck on the query select to pull the avaialble SMS IDs
        # and then apply the subject set id filter to create a new simple scope
        # that we pass onto to the selector strategy class which then applies the limit bind params etc
        SetMemberSubject.where(id: query.pluck(:id), subject_set_id: subject_set_ids).select(:id)
      else
        query.merge(SetMemberSubject.where(subject_set_id: subject_set_ids))
      end
    end

    def limit
      opts.fetch(:limit, 20).to_i
    end
  end
end
