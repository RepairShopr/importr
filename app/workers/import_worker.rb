class ImportWorker
  include Sidekiq::Worker

  sidekiq_options queue: "importer_default", retry: false

  def perform(import_id)
    import = Import.find(import_id)

    # it would be nice if worker abort could be handled here instead of deep in the model =\

    import.abort_key = ImportWorker.abort_key(jid)
    import.run_now
  end

  # manage abort signals, takes same signature as `perform`
  def self.abort(import_id)
    queue_name = get_sidekiq_options['queue'] # eg 'importer_default'

    # Remove all pending ImportWorker jobs for @import.uuid
    queue = Sidekiq::Queue.new(queue_name)
    queue.each do |q|
      q.delete if q.item['args'] == [import_id]
    end

    # job doesn't listen for `.quiet!` nor `.stop!' so it would get pushed back on queue (and worker would be dead)
    #   instead, push a short-lived key into Redis for the worker to periodically check
    # ps = Sidekiq::ProcessSet.new
    workers = Sidekiq::Workers.new
    workers.each do |process_id, thread_id, work|
      if work['queue'] == queue_name && work['payload']['args'] == [import_id]
        # ps.detect{|p| p['pid'] == process_id}.try(:stop!)

        abort_key = abort_key(work['payload']['jid'])
        Sidekiq.redis do |c|
          c.setex abort_key, 2.minutes, 'abort'
        end
      end
    end
  end

  def self.abort_key(jid)
    "ImportWorker:#{jid}"
  end
end
