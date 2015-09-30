class ImportsController < ApplicationController
  before_action :set_import, only: [:show, :edit, :update, :destroy, :status_poll]
  protect_from_forgery :except => :sheetjsw

  # GET /imports
  # GET /imports.json
  def index

  end

  def sheetjsw

  end

  # GET /imports/1
  # GET /imports/1.json
  def show
  end

  def status_poll
    render json: {
               success_count: @import.success_count.to_i,
               record_count: @import.record_count.to_i,
               error_count: @import.error_count.to_i,
               full_errors: @import.full_errors
           }
  end

  # GET /imports/new
  def new
    @import = Import.create
    redirect_to import_path(@import.uuid)
  end

  # GET /imports/1/edit
  def edit
  end

  # POST /imports
  # POST /imports.json
  def create
    @import = Import.new(import_params)

    respond_to do |format|
      if @import.save
        format.html { redirect_to @import, notice: 'Import was successfully created.' }
        format.json { render :show, status: :created, location: @import }
      else
        format.html { render :new }
        format.json { render json: @import.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /imports/1
  # PATCH/PUT /imports/1.json
  def update
    respond_to do |format|
      if @import.mapping.present? && params[:import][:mapping].blank?
        #lets just protect a tiny bit against nil'ing out the mapping on accidental blur submits..
        params[:import][:mapping] = @import.mapping
      end

      if @import.update(import_params)
        ImportWorker.perform_async(@import.id) if params[:commit] == "Process"
        format.html { redirect_to import_path(@import.uuid), notice: 'Import was successfully updated.' }
        format.json { render :show, status: :ok, location: @import }
      else
        format.html { render :edit }
        format.json { render json: @import.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /imports/1
  # DELETE /imports/1.json
  def destroy
    @import.destroy
    respond_to do |format|
      format.html { redirect_to imports_url, notice: 'Import was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_import
    @import = Import.find_by(uuid: params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def import_params
    params.require(:import).permit(:api_key, :subdomain, :resource_type, :mapping, :rows_to_process, :record_count, :success_count, :error_count, :data)
  end
end
