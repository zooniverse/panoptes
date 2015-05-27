module Export
  module JSON
    class Project
      attr_reader :project

      def self.project_attributes
        %w( name display_name primary_language configuration urls slug )
      end

      def self.project_content_attributes
        %w( language title description introduction science_case guide faq
            url_labels )
      end

      def self.workflow_attributes
        %w( display_name tasks pairwise grouped prioritized primary_language
            first_task tutorial_subject_id )
      end

      def self.workflow_content_attributes
        %w( language strings )
      end

      def initialize(project_id)
        @project = ::Project.where(id: project_id)
         .includes(:project_contents, workflows: [ :workflow_contents ])
         .first
      end

      def to_json
        {}.tap do |export|
          export[:project] = project_attrs
          export[:project_content] = project_content_attrs
          export[:workflows] = workflows_attrs
          export[:workflow_contents] = workflow_contents_attrs
        end.to_json
      end

      private

      def project_workflows
        project.workflows
      end

      def project_attrs
        project_hash = project.as_json.slice(*self.class.project_attributes)
        project_hash.merge!(private: true)
      end

      def project_content_attrs
        primary_content = project.primary_content
        primary_content.as_json.slice(*self.class.project_content_attributes)
      end

      def workflows_attrs
        [].tap do |workflows|
          project_workflows.each do |workflow|
             workflows << workflow.as_json.slice(*self.class.workflow_attributes)
          end
        end
      end

      def workflow_contents_attrs
        [].tap do |workflow_contents|
          project_workflows.each do |workflow|
            workflow.workflow_contents.each do |content|
              workflow_contents << content.as_json.slice(*self.class.workflow_content_attributes)
            end
          end
        end
      end
    end
  end
end
