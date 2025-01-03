class RolesController < ApplicationController
  before_action :set_role, only: [ :show, :edit, :update, :destroy ]
  before_action :authenticate_user!
  before_action :verify_admin

  # GET /roles
  def index
    @roles = Role.all.sort([ :name, :asc ])
  end

  # GET /roles/1
  def show
  end

  # GET /roles/new
  def new
    @role = Role.new
  end

  # GET /roles/1/edit
  def edit
  end

  # POST /roles
  def create
    @role = Role.new(role_params)

    if @role.save
      redirect_to @role, notice: "Role was successfully created."
    else
      render action: "new"
    end
  end

  # PATCH/PUT /roles/1
  def update
    if @role.update(role_params)
      redirect_to @role, notice: "Role was successfully updated."
    else
      render action: "edit"
    end
  end

  # DELETE /roles/1
  def destroy
    @role.destroy
    redirect_to roles_url, notice: "Role was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_role
      @role = Role.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def role_params
      params.require(:role).permit(:name, :description)
    end

    def verify_admin
      if current_user.try(:admin?) == false
        flash[:alert] = "You must be an administrator to use that function."
        redirect_to "/"
      end
    end
end
