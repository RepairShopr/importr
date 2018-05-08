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

require 'test_helper'

class ImportTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
