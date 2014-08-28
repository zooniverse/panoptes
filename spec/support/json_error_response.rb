require 'json'

shared_examples 'a json error response' do
  it 'should return an rack response array' do
    expect(request).to be_an(Array)
    expect(request.length).to eq(3)
  end

  it 'should return the correct status' do
    expect(request.first).to eq(status)
  end

  it 'should return a application/vnd.api+json content-type' do
    expect(request[1]['Content-Type']).to eq('application/vnd.api+json')
  end

  it 'should return the body as stringified JSON' do
    expect{ JSON.parse(request.last) }.to_not raise_error
  end

  it 'should match the msg' do
    expect(request.last).to match(msg)
  end
end
