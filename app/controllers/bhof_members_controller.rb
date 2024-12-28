class BhofMembersController < ApplicationController
  protect_from_forgery
  before_action :authenticate_user!
  before_action :must_be_admin
  before_action :set_bhof_member, only: [ :show, :edit, :update, :destroy ]

  # GET /bhof_members
  # GET /bhof_members.json
  def index
    if params[:page].present?
      page = params[:page]
    else
      page = 1
    end
    if params[:search].present? and params[:search] != ""

      @bhof_members = BhofMember.any_of({ first_name: /#{Regexp.escape(params[:search])}/i },
                                        { last_name: /#{Regexp.escape(params[:search])}/i },
                                        { email: /#{Regexp.escape(params[:search])}/i },
                                        { memberid: params[:search] }
                                       ).order_by(last_name: "asc").page(page)
    else
      @bhof_members = BhofMember.order_by(last_name: "asc").page(page)
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_bhof_member
    @bhof_member = BhofMember.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def bhof_member_params
    params[:bhof_member]
  end

  def must_be_admin
    if current_user.try(:admin?) == false and current_user.has_role?(:bhof_judge) == false
      respond_to do |format|
        format.html { redirect_to "/", alert: "Insufficent Access." }
        format.json { render json:  { errors: "Forbidden" }, status: 403 }
      end
    end
  end
end
