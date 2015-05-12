json.array!(@imports) do |import|
  json.extract! import, :id, :api_key, :resource_type, :mapping, :record_count, :success_count, :error_count
  json.url import_url(import, format: :json)
end
