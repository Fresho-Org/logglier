require "spec_helper"

describe Logglier do
  before do
    @logger = double("logger")
    allow(Logger).to receive(:new).and_return(@logger)

    @client = double("client")
    allow(Logglier::Client).to receive(:new).and_return(@client)
  end

  it "creates a logger using the logglier client as the log device" do
    url = double("log destination url")
    opts = double("logglier client options")
    client = double("the logglier client which gets used as the logdev for the ruby logger")
    logger = double("the ruby logger")

    expect(Logglier::Client).to receive(:new).with(url, opts).and_return(client)
    expect(Logger).to receive(:new).with(client).and_return(logger)

    expect(
      Logglier.new(url, opts)
    ).to eq(logger)
  end

  it "configures the logger formatter if the client responds to formatter" do
    formatter = double("formatter")
    allow(@client).to receive(:formatter).and_return(formatter)

    expect(@logger).to receive(:formatter=).with(formatter)

    Logglier.new("some url")
  end

  it "configures the logger datetime_format if the client responds to datetime_format" do
    datetime_format = double("datetime_format")
    allow(@client).to receive(:datetime_format).and_return(datetime_format)

    expect(@logger).to receive(:datetime_format=).with(datetime_format)

    Logglier.new("some url")
  end
end
