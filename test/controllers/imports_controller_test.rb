# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'
require 'minitest/mock'

class ImportsControllerTest < ActionController::TestCase
  setup do
    Sidekiq::Testing.fake!
    @import = imports(:one)
  end

  teardown do
    Sidekiq::Worker.clear_all
  end

  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get new" do
    get :new
    assert_redirected_to import_path(assigns(:import))
  end

  test "should create import" do
    assert_difference('Import.count') { post :create, import: import_params }
    assert_redirected_to import_path(assigns(:import))
  end

  test "should show import" do
    get :show, id: @import
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @import
    assert_response :success
  end

  test "should destroy import" do
    assert_difference('Import.count', -1) { delete :destroy, id: @import }
    assert_redirected_to imports_path
  end

  test "should update import" do
    patch :update, id: @import, import: import_params
    assert_equal 0, ImportWorker.jobs.size
    assert_redirected_to import_path(assigns(:import))
  end

  test "#update should call ImportWorker if commit   parameter is 'Process'" do
    assert_difference('ImportWorker.jobs.size', 1) do
      patch :update, id: @import, commit: 'Process', import: import_params
    end
    assert_redirected_to import_path(assigns(:import))
  end

  test '#cancel' do
    mock = Minitest::Mock.new
    mock.expect(:call, nil, [@import.uuid])

    ImportWorker.stub(:abort, mock) { post :cancel, id: @import }

    mock.verify
    assert_redirected_to @import
  end

  def import_params
    {
      api_key:       @import.api_key,
      error_count:   @import.error_count,
      mapping:       @import.mapping,
      record_count:  @import.record_count,
      resource_type: @import.resource_type,
      success_count: @import.success_count
    }
  end
end
