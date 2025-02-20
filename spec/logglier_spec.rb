require "spec_helper"

describe Logglier do
  before do
    @net_http_proxy = double(
      "net http proxy",
      initialize: "nil",
      deliver: "nil"
    )

    allow(Logglier::Client::HTTP::NetHTTPProxy).to receive(:new).and_return(@net_http_proxy)
  end

  context "HTTPS" do
    context "w/o any options" do
      subject { new_logglier("https://localhost") }

      it { should be_an_instance_of Logger }
      its("logdev.dev") { should be_an_instance_of Logglier::Client::HTTP }
    end

    context "w/threaded option" do
      subject { new_logglier("https://localhost", threaded: true) }

      it { should be_an_instance_of Logger }
      its("logdev.dev") { should be_an_instance_of Logglier::Client::HTTP }
    end

    context "formatting" do
      subject { new_logglier("https://localhost", format: :json) }

      it { should be_an_instance_of Logger }

      context "with a string" do
        it "should send a message via the logdev" do
          subject.logdev.dev.should_receive(:write).with(/severity=WARN, foo/)
          subject.add(Logger::WARN) { "foo" }
        end
      end

      context "with a hash" do
        it "should send a message via the logdev" do
          subject.logdev.dev.should_receive(:write).with(/"severity":"WARN"/)
          subject.logdev.dev.should_receive(:write).with(/"foo":"bar"/)
          subject.logdev.dev.should_receive(:write).with(/"man":"pants"/)
          # The following is equiv to:
          # subject.warn :foo => :bar, :man => :pants
          subject.add(Logger::WARN) { { foo: :bar, man: :pants } }
          subject.add(Logger::WARN) { { foo: :bar, man: :pants } }
          subject.add(Logger::WARN) { { foo: :bar, man: :pants } }
        end
      end
    end
  end

  context "Syslog TCP" do
    before { TCPSocket.stub(:new) { MockTCPSocket.new } }

    subject { new_logglier("tcp://localhost:12345") }

    it { should be_an_instance_of Logger }
    its("logdev.dev") { should be_an_instance_of Logglier::Client::Syslog }
  end

  context "Syslog UDP" do
    subject { new_logglier("udp://localhost:12345") }

    it { should be_an_instance_of Logger }
    its("logdev.dev") { should be_an_instance_of Logglier::Client::Syslog }
  end
end
