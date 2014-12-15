module RSpec
  module Helpers
    module ActiveRecordMocks
      def mock_active_record_model(name, &block)
        create_temp_table(name, &block)
      end

      def create_temp_table(table, &block)
        before :all do
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Migration.create_table "#{table}_tables" do |t|

              block.call(t)
            end
          end
        end

        after :all do
          ActiveRecord::Migration.suppress_messages do
            ActiveRecord::Migration.drop_table "#{table}_tables"
          end
        end
      end

      private
    end
  end
end
