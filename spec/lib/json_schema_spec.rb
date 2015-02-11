require 'spec_helper'

RSpec.describe JsonSchema do
  let(:formated_error_messages) do
    { "name" => "did not match the following type: string",
      "metadata" => "did not contain a required property of 'start'" }.to_s
  end
  shared_examples "validates json" do
    context "valid json" do
      let(:valid_json) do
        {
          "id" => 1,
          "name" => "basdf"
        }
      end

      it 'should not raise an error' do
        expect do
          subject.validate!(valid_json)
        end.to_not raise_error
      end
    end

    context "invalid json" do
      let(:invalid_json) do
        {
          "id" => 1,
          "name" => 4,
          "metadata" => {
            "end" => 10,
            "finish" => "at nine"
          }
        }
      end

      it 'should raise an error' do
        expect do
          subject.validate!(invalid_json)
        end.to raise_error(JsonSchema::ValidationError)
      end

      it 'should format the error message for use in the API response' do
        expect do
          subject.validate!(invalid_json)
        end.to raise_error(formated_error_messages)
      end
    end
  end

  describe "::schema" do
    subject do
      Class.new(JsonSchema) do
        schema do
          type "object"
          required "id", "name"
          property "id" do
            type "integer"
          end

          property "name" do
            type "string"
          end

          property "metadata" do
            type "object"
            required "start", "end"
            property "start" do
              type "integer"
            end

            property "end" do
              type "float"
            end
          end
        end
      end.new
    end

    it_behaves_like "validates json"
  end

  describe "::build" do
    subject do
      JsonSchema.build do
        type "object"
        required "id", "name"
        property "id" do
          type "integer"
        end

        property "name" do
          type "string"
        end

        property "metadata" do
          type "object"
          required "start", "end"

          property "start" do
            type "integer"
          end

          property "end" do
            type "float"
          end
        end
      end
    end

    it_behaves_like "validates json"
  end
end
