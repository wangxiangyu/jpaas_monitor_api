module Acme
  class API < Grape::API
    format :json
    mount ::Acme::LogMonitor
    mount ::Acme::Org
    mount ::Acme::Space
    mount ::Acme::App
    mount ::Acme::RegisterRouterBns
    mount ::Acme::FlowTransfer
    mount ::Acme::UserDefinedMonitor
    mount ::Acme::MonitorCenter
    mount ::Acme::ProcMonitor
    mount ::Acme::Collector
    mount ::Acme::HttpUserDefinedMonitor
    mount ::Acme::DomainMonitor
    mount ::Acme::MonitorBlock
    mount ::Acme::InstanceNumCheck
    mount ::Acme::MonitorCheck
    mount ::Acme::DoAlarm
    mount ::Acme::Cluster
    mount ::Acme::JsonReader
    mount ::Acme::MonitorMigration
  end
end

