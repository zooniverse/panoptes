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

  def stub_redis_connection(get_host=nil, set_host=nil)
    @redis_conn = double("redis", get: get_host, setex: set_host)
    allow(Sidekiq).to receive(:redis) { |&block| block.call(@redis_conn) }
  end

  def stubbed_redis_connection
    @redis_conn
  end
end
