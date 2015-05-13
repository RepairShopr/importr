# == Schema Information
#
# Table name: imports
#
#  id            :integer          not null, primary key
#  api_key       :string
#  resource_type :string
#  mapping       :text
#  record_count  :integer
#  success_count :integer
#  error_count   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  uuid          :string
#  subdomain     :string
#  data          :text
#

class Import < ActiveRecord::Base
  before_save :generate_uuid

  serialize :data

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
    mapping.gsub!("YYYY","%Y")
    mapping.gsub!("YY","%y")
    mapping.gsub!("MM","%m")
    mapping.gsub!("DD","%d")
    mapping
  end

  def run_ticket_import
    client = TroysAPIClient.new(subdomain,api_key)
    client.base_url = Rails.env.development? ? "http://#{subdomain}.lvh.me:3000" : "https://#{subdomain}.repairshopr.co"
    records = JSON.parse(data)

    un_mapper = {}
    records.first.each do |r|
      un_mapper[r[1]] = r[0]
    end

    records.each_with_index do |row,index|
      next if index == 0

      created_at = Time.strptime(row[un_mapper['created_at']],i.time_mapping) rescue Time.now
      comment = {}
      comment[:subject] = "Import Comment"
      comment[:body] = row[un_mapper["body"]]
      comment[:tech] = row[un_mapper["tech"]]
      comment[:hidden] = '1'
      comment[:do_not_email] = '1'
      comment[:created_at] = created_at
      comment[:updated_at] = created_at
      ticket = {}
      ticket[:customer_name] = row[un_mapper["customer_name"]]
      ticket[:email] = row[un_mapper["customer_email"]]
      ticket[:phone] = row[un_mapper["customer_phone"]]
      ticket[:subject] = row[un_mapper['subject']].to_s[0..254]
      ticket[:problem_type] = row[un_mapper["problem_type"]]
      ticket[:number] = row[un_mapper['number']]
      ticket[:status] = 'Resolved'
      ticket[:created_at] = created_at
      ticket[:updated_at] = created_at
      ticket[:comments_attributes] = [comment]
      ticket.compact!
      # puts ticket
       client.create_ticket ticket
      sleep 0.45                                  #awesome rate limiter! you might need to re-read this to grok it..
    end
  end
end
