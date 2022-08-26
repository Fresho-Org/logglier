require "spec_helper"

module Logglier
  module Client
    describe Syslog do
      it "raises an error when given an invalid URI" do
        expect do
          Syslog.new(input_url: "<invalid>")
        end.to raise_error(InputURLRequired, "Invalid Input URL: <invalid>")
      end

      context "Using a UDP URI" do
        before do
          @udp_socket = double("UDP socket")
          allow(UDPSocket).to receive(:new).and_return(@udp_socket)
          allow(@udp_socket).to receive(:connect)
        end

        it "connects a UDP socket" do
          expect(@udp_socket).to receive(:connect).with("host", 123)

          syslog = Syslog.new(input_url: "udp://host:123")
          expect(syslog.facility).to eq(16)
        end

        describe "formatter" do
          before do
            allow(Process).to receive(:pid).and_return("processid")
            allow(Socket).to receive(:gethostname).and_return("hostname")
            
            @datetime = double("datetime")
            allow(@datetime).to receive(:rfc3339).with(3).and_return("formatted datetime")
          end

          def logger
            Logger.new(
              @syslog,
              formatter: @syslog.formatter,
              progname: "test"
            )
          end

          it "supports fatal, error, warn, info and debug with Logger" do
            syslog = Syslog.new(
              input_url: "udp://host:123",
              loggly_customer_token: "loggly token"
            )
            formatter = syslog.formatter

            expect(
              formatter.call("FATAL", @datetime, "progname", "message")
            ).to eq("<128>1 formatted datetime hostname progname processid [loggly token@41058 tag=\"ruby\"] message")
            
            expect(
              formatter.call("ERROR", @datetime, "progname", "message")
            ).to eq("<131>1 formatted datetime hostname progname processid [loggly token@41058 tag=\"ruby\"] message")

            expect(
              formatter.call("WARN", @datetime, "progname", "message")
            ).to eq("<132>1 formatted datetime hostname progname processid [loggly token@41058 tag=\"ruby\"] message")

            expect(
              formatter.call("INFO", @datetime, "progname", "message")
            ).to eq("<134>1 formatted datetime hostname progname processid [loggly token@41058 tag=\"ruby\"] message")

            expect(
              formatter.call("DEBUG", @datetime, "progname", "message")
            ).to eq("<135>1 formatted datetime hostname progname processid [loggly token@41058 tag=\"ruby\"] message")
          end

          it "blows up when logging an unknown message" do
            @syslog = Syslog.new(input_url: "udp://host:123")

            expect do
              logger.unknown("message")
            end.to raise_error(TypeError, "nil can't be coerced into Integer")
          end

          it "can use a provided hostname" do
            @syslog = Syslog.new(input_url: "udp://host:123", hostname: "provided")

            expect(@udp_socket).to receive(:send).with(
              /<128>\w+ \d+ \d+:\d+:\d+ provided test\[processid\]: message/, 0
            )
            logger.fatal("message")
          end
        end
      end
    end
  end
end
