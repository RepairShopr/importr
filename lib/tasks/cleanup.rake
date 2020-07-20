task :cleanup => :environment do
  Import.where("created_at < ?",Time.now-7.days).update_all api_key: nil, data: nil
end

