class Import < ActiveRecord::Base
  self.primary_key = 'uuid'

  before_save :generate_uuid

  serialize :data
  serialize :full_errors, Array

  RESOURCE_TYPES = %w"ticket invoice asset"
  RESOURCE_COLLECTION = RESOURCE_TYPES.map {|i| [i.titleize,i]}

  validates :api_key, :subdomain, presence: true, if: ->() { data.present? }
  validate do
    # need valid credentials to include data, but don't spam RSYN for blank credentials.
    if data.present? && changes.slice(:data, :subdomain, :api_key).any?
      unless api_key.present? && subdomain.present? && get_client.authentic?
        self.errors.add(:api_key, 'can not be stored unless platform recognizes api_key')
      end
    end
  end

  def fields_for_csv
    case resource_type
      when "ticket"
        {
            required: [
                {body: 'string'}
            ],
            suggested: [
                {number: 'string'},
                {subject: 'string'},
                {tech: 'string'},
                {problem_type: 'string'},
                {created_at: 'date'},
            ],
            example_file: "https://www.dropbox.com/s/i7xbsg0yhvtfl4r/Importer-Tickets.xlsx?dl=0"
        }
      when "invoice"
        {
            required: [
                {number: 'string'},
                {subtotal: 'string'},
                {date: 'date'}
            ],
            suggested: [
                {optional_line_item_name: 'string'},
            ],
            example_file: "https://www.dropbox.com/s/nc3lwwxtsdhdxlo/Importer-Invoice.xlsx?dl=0"
        }
      when 'asset'
        {
            required: [
                {name: 'string'},
                {asset_type_name: 'string'}
            ],
            suggested: [
                {asset_id: 'string'},
                {asset_serial: 'string'},
                {properties: 'string'},
            ],
            example_file: "https://www.dropbox.com/s/qu1mvfbaaj6vvro/Importer-Assets.xlsx?dl=0"
        }
      else
        {required: [],suggested: []}
    end
  end

  def generate_uuid
    uuid.presence || self.uuid = SecureRandom.uuid
  end

  def run_now
    if data.present?
      case resource_type
        when 'ticket'
          run_ticket_import
        when 'invoice'
          run_invoice_import
        when 'asset'
          run_asset_import
      end
    end
  end

  def time_mapping
    #converting from momentjs -> ruby strptime
    mapping.gsub!("YYYY","%Y")
    mapping.gsub!("YY","%y")
    mapping.gsub!("MM","%m")
    mapping.gsub!("DD","%d")
    mapping
  end

  def run_ticket_import
    process_for('Ticket', 'number') do |row|
      created_at = Time.strptime(row[@un_mapper['created_at']],time_mapping)
      comment = build_comment_hash(row,created_at)
      ticket = build_ticket_hash(row,created_at)
      ticket[:comments_attributes] = [comment]
      result = client.create_ticket ticket
      sleep 0.45                                  #awesome rate limiter! you might need to re-read this to grok it..
      result
    end
  end


  def run_invoice_import
    process_for('Invoice', 'number') do |row|
      created_at = Time.strptime(row[@un_mapper['date']],time_mapping) rescue Time.now
      invoice = build_invoice_hash(row,created_at)
      result = client.create_invoice invoice
    end
  end

  def run_asset_import
    process_for('Asset', 'name') do |row|
      # row['asset_type_name'] = 'Computer' # hack for testing extremely large imports
      asset = build_asset_hash(row)
      result = client.create_or_update('customer_assets', asset)
      result = process_asset_serial_conflict(result, asset)
    end
  end

  # Hack out a matcher to silence 'Asset serial has already been taken' errors for import re-runs
  def process_asset_serial_conflict(result, asset)
    return result unless self.match_on_asset_serial
    return result if result['success']

    maybe_missing_asset_id = result['message'].reject{|m| m == 'Asset serial has already been taken'}.none?
    return result unless maybe_missing_asset_id

    matcher_client = get_client # another instance because of side-effects
    conflict_assets = matcher_client.get('customer_assets', query: asset[:asset_serial])
    return result unless conflict_assets['assets'] && conflict_assets['assets'].count == 1

    conflict = conflict_assets['assets'].first
    # I tried comparing all of `asset`s values to `conflict`s values to confirm, but the keys don't match (eg customer_email)

    # pretend the import data included id to maintain interfaces
    asset[:id] = conflict['id']
    client.create_or_update('customer_assets', asset)
  end

  def client(reload = false)
    if @client.nil? || reload
      @client = get_client
    end

    @client
  end

  def get_client
    host = 'repairshopr.co' if staging_run?
    TroysAPIClient.new(subdomain, api_key, platform: platform, host: host)
  end

  private

  def process_for(resource_name, id_column)
    records = Oj.load(data)

    self.update(record_count: (rows_to_process || records.size-1))
    error_stop = errors_to_allow.to_i > 0 ? errors_to_allow : 100_000
    self.error_count = 0
    self.success_count = 0
    self.full_errors = []

    column_mapping = records.first
    @un_mapper = column_mapping.invert

    records.each_with_index do |row,index|
      next if index == 0 # skip header row
      resource_identifier = row[@un_mapper[id_column]]

      begin
        result = yield row
      rescue => ex
        self.full_errors << "#{resource_name} #{id_column}: #{resource_identifier} Exception from Job: #{ex}"
        self.error_count += 1

        # use update_columns to skip ActiveRecord redundant evaluation of megabytes in import.data
        # could store import.data on a separate table instead and make this a more simple progress.save
        self.update_columns(record_count: record_count, success_count: success_count, error_count: error_count, full_errors: full_errors)
        next
      end

      if client.last_response.status == 200
        self.success_count += 1
      else
        self.full_errors << "#{resource_name} #{id_column}: #{resource_identifier} Import Error: #{result}"
        self.error_count += 1
        self.record_count = self.success_count + self.error_count if self.error_count >= error_stop
      end

      # use update_columns to skip ActiveRecord redundant evaluation of megabytes in import.data
      # could store import.data on a separate table instead and make this a more simple progress.save
      self.update_columns(record_count: record_count, success_count: success_count, error_count: error_count, full_errors: full_errors)

      break if index >= record_count # stop on index match rather than making two copies of the array
    end

    puts "Success: #{success_count}"
    puts "Error: #{error_count}"
    self.save
  end

  def build_ticket_hash(row,created_at)
    ticket = {}
    ticket[:customer_name] = row[@un_mapper["customer_name"]]
    ticket[:email] = row[@un_mapper["customer_email"]]
    ticket[:phone] = row[@un_mapper["customer_phone"]]
    ticket[:subject] = row[@un_mapper['subject']].to_s[0..254]
    ticket[:problem_type] = row[@un_mapper["problem_type"]]
    ticket[:number] = row[@un_mapper['number']]
    ticket[:status] = 'Resolved'
    ticket[:created_at] = created_at
    ticket[:updated_at] = created_at
    ticket.compact!
    ticket
  end

  def build_comment_hash(row,created_at)
    comment = {}
    comment[:subject] = "Import Comment"
    comment[:body] = row[@un_mapper["body"]]
    comment[:tech] = row[@un_mapper["tech"]]
    comment[:hidden] = '1'
    comment[:do_not_email] = '1'
    comment[:created_at] = created_at
    comment[:updated_at] = created_at
    comment
  end

  def build_invoice_hash(row,created_at)
    invoice = {}
    invoice[:customer_name] = row[@un_mapper["customer_name"]]
    invoice[:email] = row[@un_mapper["customer_email"]]
    invoice[:phone] = row[@un_mapper["customer_phone"]]
    invoice[:date] = created_at
    invoice[:paid] = true
    invoice[:date_received] = created_at
    invoice[:number] = row[@un_mapper['number']]
    invoice[:line_items] = [
        {item: 'Legacy', name: (row[@un_mapper['optional_line_item_name']].presence || 'Invoice Line Item'),
         cost: 0.0,
         price: row[@un_mapper['subtotal']].gsub('$','').gsub(' ','').to_f,
         quantity: 1}
    ]
    invoice[:note] = "Processed by Importr session: #{uuid}"
    invoice.compact!
    invoice
  end

  def build_asset_hash(row)
    asset = {}
    asset[:id] = row[@un_mapper["asset_id"]]
    asset[:customer_name] = row[@un_mapper["customer_name"]]
    asset[:customer_id] = row[@un_mapper["customer_id"]]
    asset[:email] = row[@un_mapper["customer_email"]]
    asset[:phone] = row[@un_mapper["customer_phone"]]

    asset[:name] = row[@un_mapper["name"]]
    asset[:asset_serial] = row[@un_mapper["asset_serial"]]
    asset[:asset_type_name] = row[@un_mapper["asset_type_name"]]
    asset[:properties] = properties_unserializer(row)
    asset.compact!
    asset
  end

  def properties_unserializer(row)
    properties = {}
    if row[@un_mapper["properties"]].present?
      fields = row[@un_mapper["properties"]].split(";")
      fields.each do |field|
        k,v = field.split(":")
        properties[k] = v
      end
    end
    properties
  end

end


# == Schema Information
#
# Table name: imports
#
#  id                    :integer          not null
#  api_key               :string
#  resource_type         :string
#  mapping               :text
#  record_count          :integer
#  success_count         :integer
#  error_count           :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  uuid                  :string           primary key
#  subdomain             :string
#  data                  :text
#  full_errors           :text
#  rows_to_process       :integer
#  staging_run           :boolean          default(FALSE)
#  platform              :string
#  errors_to_allow       :integer
#  match_on_asset_serial :boolean          default(FALSE), not null
#
# Indexes
#
#  index_imports_on_uuid  (uuid)
#
