class SignupInvitesController < ApplicationController
  before_action :set_signup_invite, only: [ :show, :edit, :update, :destroy ]
  before_action :authenticate_user!
  before_action :verify_admin

  # GET /signup_invites
  # GET /signup_invites.json
  def index
    @signup_invites = SignupInvite.all
  end

  # GET /signup_invites/1
  # GET /signup_invites/1.json
  def show
  end

  # GET /signup_invites/new
  def new
    @signup_invite = SignupInvite.new
  end

  # GET /signup_invites/1/edit
  def edit
  end

  # POST /signup_invites
  # POST /signup_invites.json
  def create
    @signup_invite = SignupInvite.new(signup_invite_params)

    respond_to do |format|
      if @signup_invite.save
        format.html { redirect_to @signup_invite, notice: "Signup invite was successfully created." }
        format.json { render :show, status: :created, location: @signup_invite }
      else
        format.html { render :new }
        format.json { render json: @signup_invite.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /signup_invites/1
  # PATCH/PUT /signup_invites/1.json
  def update
    respond_to do |format|
      if @signup_invite.update(signup_invite_params)
        format.html { redirect_to @signup_invite, notice: "Signup invite was successfully updated." }
        format.json { render :show, status: :ok, location: @signup_invite }
      else
        format.html { render :edit }
        format.json { render json: @signup_invite.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /signup_invites/1
  # DELETE /signup_invites/1.json
  def destroy
    @signup_invite.destroy
    respond_to do |format|
      format.html { redirect_to signup_invites_url, notice: "Signup invite was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_signup_invite
      @signup_invite = SignupInvite.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def signup_invite_params
      params.require(:signup_invite).permit(:code, :available, :expires, :used_count)
    end

    private

    def verify_admin
      if current_user.try(:admin?) == false
        flash[:alert] = "You must be an administrator to use that function."
        redirect_to "/"
      end
    end
end
