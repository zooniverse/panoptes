# frozen_string_literal: true

shared_examples 'is schedulable' do
  let(:job) { Sidekiq::Cron::Job.new(name: 'cron_job_name', cron: cron_sched, class: class_name) }

  it 'gets queued on enqueued_time' do
    # sidekiq-cron has 10 second delay
    expect(job.should_enque?(enqueued_time + 10)).to be true
  end

  it 'does not get enqueued outside of enqueued_time' do
    outside_time = enqueued_time + 3 * 60

    expect(job.should_enque?(outside_time)).to be false
  end
end
