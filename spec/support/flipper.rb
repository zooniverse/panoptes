module Flipper
  RSpec.configure do |config|
    config.before(:each) do |example|
      allow(Panoptes).to receive(:flipper).and_return(Flipper.new(Flipper::Adapters::Memory.new))
      Panoptes.flipper["cellect"].enable
      Panoptes.flipper["designator"].enable
      Panoptes.flipper[:remove_complete_subjects].enable
      Panoptes.flipper[:dump_worker_exports].enable
      Panoptes.flipper[:subject_uploading].enable
    end
  end
end
