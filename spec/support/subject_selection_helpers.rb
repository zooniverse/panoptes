module SubjectSelectionHelpers
  def stub_designator_client
    @designator_client = instance_double("DesignatorClient",
                                         add_seen: true,
                                         load_user: true,
                                         reload_workflow: true,
                                         remove_subject: true,
                                         get_subjects: [])
    allow(Subjects::DesignatorSelector).to receive(:client).and_return(@designator_client)
    @designator_client
 end
end
