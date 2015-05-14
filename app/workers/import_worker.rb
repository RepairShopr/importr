class ImportWorker
  include Sidekiq::Worker

  sidekiq_options queue: "importer_default", retry: false

  def perform(import_id)
    import = Import.find(import_id)
    import.run_now
  end
end