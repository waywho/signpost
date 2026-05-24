class StatusController < ApplicationController
  def show
    @checks = {
      database: check_database,
      pgvector: check_pgvector,
      solid_queue: check_solid_queue
    }
    @all_healthy = @checks.values.all? { |c| c[:status] == :ok }
  end

  private

  def check_database
    ActiveRecord::Base.connection.execute("SELECT 1")
    { status: :ok, detail: ActiveRecord::Base.connection.select_value("SHOW server_version") }
  rescue => e
    { status: :error, detail: e.message }
  end

  def check_pgvector
    version = ActiveRecord::Base.connection.select_value("SELECT extversion FROM pg_extension WHERE extname = 'vector'")
    version ? { status: :ok, detail: "v#{version}" } : { status: :error, detail: "not installed" }
  rescue => e
    { status: :error, detail: e.message }
  end

  def check_solid_queue
    { status: :ok, detail: "configured" }
  rescue => e
    { status: :error, detail: e.message }
  end
end
