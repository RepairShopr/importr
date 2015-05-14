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
#

require 'test_helper'

class ImportTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
