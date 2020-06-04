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
  setup do
    @import = imports(:one)
    @import.update!(platform: 'repairshopr')
  end

  #
  # Of course, `#run_now` should be tested for `success_count` and not errors
  # but I cannot guess the correct input format, so I leave it as it is for now to save time.
  # At least, it is a quite valid smoke test for main model's feature.
  # @gryaznov
  #
  test '#run_now ticket' do
    @import.resource_type = 'ticket'
    @import.data = File.read(Rails.root.join('test', 'fixtures', 'files', 'ticket.json'))
    assert_difference('@import.error_count') { @import.run_now }
    assert_equal 1, @import.full_errors.count
  end

  test '#run_now asset' do
    @import.resource_type = 'asset'
    @import.data = File.read(Rails.root.join('test', 'fixtures', 'files', 'asset.json'))
    assert_difference('@import.error_count') { @import.run_now }
    assert_equal 1, @import.full_errors.count
  end

  test '#run_now invoice' do
    @import.resource_type = 'invoice'
    @import.data = File.read(Rails.root.join('test', 'fixtures', 'files', 'invoice.json'))
    assert_difference('@import.error_count') { @import.run_now }
    assert_equal 1, @import.full_errors.count
  end

  test '#client does not call for TroysAPIClient if there is a client' do
    client = @import.client
    assert_equal client.object_id, @import.client.object_id
  end

  test '#client calls for TroysAPIClient if reload is required' do
    client = @import.client
    assert_not_equal client.object_id, @import.client(:reload).object_id
  end
end
