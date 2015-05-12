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
#

class Import < ActiveRecord::Base
  before_save :generate_uuid

  RESOURCE_TYPES = %w"ticket"
  RESOURCE_COLLECTION = RESOURCE_TYPES.map {|i| [i.titleize,i]}

  def fields_for_csv
    case resource_type
      when "ticket"
        {
            required: [],
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

end
