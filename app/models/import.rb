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
#

class Import < ActiveRecord::Base
  before_save :generate_uuid

  def generate_uuid
    uuid.presence || self.uuid = SecureRandom.uuid
  end
end
