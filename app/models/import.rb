# == Schema Information
#
# Table name: imports
#
#  id              :integer          not null, primary key
#  api_key         :string
#  resource_type   :string
#  mapping         :text
#  record_count    :integer
#  success_count   :integer
#  error_count     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  uuid            :string
#  subdomain       :string
#  data            :text
#  full_errors     :text
#  rows_to_process :integer
#  staging_run     :boolean          default(FALSE)
#

class Import < ActiveRecord::Base
  before_save :generate_uuid

  serialize :data
  serialize :full_errors, Array

  RESOURCE_TYPES = %w"ticket"
  RESOURCE_COLLECTION = RESOURCE_TYPES.map {|i| [i.titleize,i]}

  def fields_for_csv
    case resource_type
      when "ticket"
        {
            required: [
                {customer_phone: "string"}
            ],
            suggested: [
                {number: 'string'},
                {subject: 'string'},
                {body: 'string'},
                {tech: 'string'},
                {problem_type: 'string'},
                {created_at: 'date'},
            ]
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
    client = TroysAPIClient.new(subdomain,api_key)
    client.base_url = Rails.env.development? ? "http://#{subdomain}.lvh.me:3000" : "https://#{subdomain}.repairshopr.com"
    if staging_run?
      puts "STAGING_RUN going to gsub"
      client.base_url.gsub!(".com",".co")
    end
    records = JSON.parse(data)

    self.update(record_count: (rows_to_process || records.size-1))
    self.error_count = 0
    self.success_count = 0
    self.full_errors = []

    @un_mapper = {}
    records.first.each do |r|
      @un_mapper[r[1]] = r[0]
    end

    records[0..(rows_to_process || -0)].each_with_index do |row,index|
      next if index == 0

      begin

        created_at = Time.strptime(row[@un_mapper['created_at']],time_mapping) rescue Time.now
        comment = build_comment_hash(row,created_at)
        ticket = build_ticket_hash(row,created_at)
        ticket[:comments_attributes] = [comment]
        result = client.create_ticket ticket
        sleep 0.45                                  #awesome rate limiter! you might need to re-read this to grok it..
      rescue => ex
        self.full_errors << "Ticket number: #{row[@un_mapper['number']]} Exception from Job: #{ex}"
        self.error_count += 1
        self.save
        next
      end

      if result.status == 200
        self.success_count += 1
      else
        self.full_errors << "Ticket number: #{row[@un_mapper['number']]} Import Error: #{result.body}"
        self.error_count += 1
      end
      self.save

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
end
