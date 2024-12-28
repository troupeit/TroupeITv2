class DecidersController < ApplicationController
  before_action :set_decider, only: [ :show, :edit, :update, :destroy ]
  before_action :authenticate_user!
  before_action :verify_admin

  # GET /deciders
  def index
    @deciders = Decider.all.order_by(key: "asc")
  end

  # GET /deciders/1
  def show
  end

  # GET /deciders/new
  def new
    @decider = Decider.new
  end

  # GET /deciders/1/edit
  def edit
  end

  # POST /deciders
  def create
    @decider = Decider.new(decider_params)

    if @decider.save
      redirect_to deciders_path, notice: "Decider was successfully created."
    else
      render :new
    end
  end

  # PATCH/PUT /deciders/1
  def update
    if @decider.update(decider_params)
      redirect_to deciders_path, notice: "Decider was successfully updated."
    else
      render :edit
    end
  end

  # DELETE /deciders/1
  def destroy
    @decider.destroy
    redirect_to deciders_url, notice: "Decider was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_decider
      @decider = Decider.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def decider_params
      params.require(:decider).permit(:key, :description, :value_f, :value_f_staging, :value_f_test)
    end

    def verify_admin
      if current_user.try(:admin?) == false
        flash[:alert] = "You must be an administrator to use that function."
        redirect_to "/"
      end
    end
end
