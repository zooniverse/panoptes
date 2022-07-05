module Flipper
  RSpec.configure do |config|
    config.before(:each) do |example|
      allow(Panoptes).to receive(:flipper).and_return(Flipper.new(Flipper::Adapters::Memory.new))
      Flipper.enable(:cellect)
      Flipper.enable(:designator)
      Flipper.enable(:remove_complete_subjects)
      Flipper.enable(:dump_worker_exports)
      Flipper.enable(:subject_uploading)
      Flipper.enable(:classification_lifecycle_in_background)
      Flipper.enable(:http_caching)
      Flipper.enable(:classification_counters)
      Flipper.enable(:cached_serializer)
    end
  end
end
