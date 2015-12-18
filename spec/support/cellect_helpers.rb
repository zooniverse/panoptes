module CellectHelpers
  def stub_cellect_connection
    @cellect_conn = double
    allow(@cellect_conn).to receive(:add_seen)
    allow(@cellect_conn).to receive(:load_user)
    allow(@cellect_conn).to receive(:get_subjects)
    allow(@cellect_conn).to receive(:remove_subject)
    allow(Cellect::Client).to receive(:host_exists?).and_return(true)
    allow(Cellect::Client).to receive(:choose_host).and_return("example.com")
    allow(Cellect::Client).to receive(:connection).and_return(@cellect_conn)
  end

  def stubbed_cellect_connection
    @cellect_conn
  end
end
