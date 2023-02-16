require "app_revision"

Datadog.configure do |c|
  c.service = "rubygems.org"
  c.version = AppRevision.version
  c.env = Rails.env

  c.runtime_metrics.enabled = Rails.env.production? || Rails.env.staging?

  c.logger.instance = Rails.logger

  c.tracing.report_hostname = true
  c.tracing.distributed_tracing.propagation_inject_style << 'tracecontext'
  c.tracing.distributed_tracing.propagation_extract_style << 'tracecontext'

  if Rails.env.test? || Rails.env.development?
    c.tracing.transport_options = proc { |t|
      # Set transport to no-op mode. Does not retain traces.
      t.adapter :test
    }
    c.diagnostics.startup_logs.enabled = false
  end

  c.tracing.instrument :aws
  c.tracing.instrument :dalli
  c.tracing.instrument :delayed_job
  c.tracing.instrument :faraday, split_by_domain: true, service_name: c.service
  c.tracing.instrument :http, service_name: c.service
  c.tracing.instrument :pg
  c.tracing.instrument :rails
  c.tracing.instrument :rest_client, split_by_domain: true, service_name: c.service
  c.tracing.instrument :shoryuken
end

Datadog::Tracing.before_flush(
  # Remove spans for the /internal/ping endpoint
  Datadog::Tracing::Pipeline::SpanFilter.new { |span| span.resource == "Internal::PingController#index" }
)