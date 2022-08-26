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

  it "sends message to the logger logdev" do
    before do
      @logglier = Logglier.new
    end

    context "with a string" do
      it "should send a message via the logdev" do
        if subject.logdev.dev.is_a?(Logglier::Client::Syslog)
          subject.logdev.dev.should_receive(:write).with(/foo/)
        else
          subject.logdev.dev.should_receive(:write).with(/severity=WARN, foo/)
        end

        subject.add(Logger::WARN) { 'foo' }
      end
    end

    context "with a hash" do
      it "should send a message via the logdev" do
        # expect count is the number of times we need to
        # repeat the log message to test all of the possibilities
        if subject.logdev.dev.is_a?(Logglier::Client::Syslog)
          expect_count = 2
        else
          expect_count = 3
          subject.logdev.dev.should_receive(:write).with(/severity=WARN/)
        end

        expect(subject.logdev.dev).to receive(:write).with(/foo=bar/)
        expect(subject.logdev.dev).to receive(:write).with(/man=pants/)

        # The following is equiv to:
        # subject.warn :foo => :bar, :man => :pants
        expect_count.times do
          subject.add(Logger::WARN) { {:foo => :bar, :man => :pants} }
        end
      end
    end
  end

  context "HTTPS" do
    context "w/o any options" do
      subject { Logglier.new("https://localhost") }

      it { should be_an_instance_of Logger }
      its("logdev.dev") { should be_an_instance_of Logglier::Client::HTTP }

      it_should_behave_like "a logglier enhanced Logger instance"
    end

    context "w/threaded option" do
      subject { new_logglier("https://localhost", threaded: true) }

      it { should be_an_instance_of Logger }
      its("logdev.dev") { should be_an_instance_of Logglier::Client::HTTP }

      it_should_behave_like "a logglier enhanced Logger instance"
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

    it_should_behave_like "a logglier enhanced Logger instance"
  end

  context "Syslog UDP" do
    subject { new_logglier("udp://localhost:12345") }

    it { should be_an_instance_of Logger }
    its("logdev.dev") { should be_an_instance_of Logglier::Client::Syslog }

    it_should_behave_like "a logglier enhanced Logger instance"
  end
end
