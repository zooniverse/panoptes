module CellectHelpers
  def stub_cellect_connection
    @cellect_connection = double
    allow(@cellect_connection).to receive(:add_seen)
    allow(@cellect_connection).to receive(:load_user)
    allow(@cellect_connection).to receive(:get_subjects)
    allow(@cellect_connection).to receive(:remove_subject)
    allow(Cellect::Client).to receive(:choose_host).and_return("example.com")
    allow(Cellect::Client).to receive(:connection).and_return(@cellect_connection)
  end

  def stubbed_cellect_connection
    @cellect_connection
  end
end
