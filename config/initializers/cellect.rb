cellect_timeout = ENV["CELLECT_HTTP_TIMEOUT"].to_f
if cellect_timeout != 0.0
  Cellect::Client::Connection.timeout = cellect_timeout
end
