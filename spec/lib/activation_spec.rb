require 'spec_helper'

describe Activation do
  class ActivatedObject
    def initialize(active=true)
      @active = active
    end

    def enable!
      @active = true
    end

    def disable!
      @active = false
    end

    def active?
      @active
    end

    def inactive?
      !@active
    end
  end

  let(:instances) {
    n = Array(10..20).sample
    is = []
    n.times do |i|
      if n % 2 == 0
        is << ActivatedObject.new
      else
        is << ActivatedObject.new(false)
      end
    end
    is
  }

  describe '::enable_instances!' do
    let(:enable_instances) { Activation.enable_instances!(instances) }

    it 'should call enable! on a list of objects' do
      expect(instances).to all( receive(:enable!) )
      enable_instances
    end

    it 'should set all instances to active' do
      enable_instances
      expect(instances.map { |i| i.active? }).to all( be_truthy )
    end
  end

  describe '::disable_instances!' do
    let(:disable_instances) { Activation.disable_instances!(instances) }

    it 'should call disable on a list of objects' do
      expect(instances).to all( receive(:disable!) )
      disable_instances
    end

    it 'should set all instances to inactive' do
      disable_instances
      expect(instances.map { |i| i.inactive? }).to all( be_truthy )
    end
  end
end
