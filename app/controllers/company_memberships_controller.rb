class CompanyMembershipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_company_membership, only: [ :update, :destroy ]
  before_action :must_be_producer, only: [ :update, :destroy ]

  protect_from_forgery

  # this controller just returns membership data for a particular user
  # it's mostly read-only. The real work is done by the company controller.

  # We also return the user record - it's here if you need to use
  # user preferences instead of making a second ajax call.

  def index
    @cms = current_user.company_memberships
    # need to fetch owner and trial data here

    respond_to do |format|
      format.html { render action: "index" }
      format.json { render json: @cms.to_json(include: { company: { include: :user } }) }
    end
  end

  # PATCH/PUT /events/1
  def update
    if @company_membership.update(company_membership_params)
      respond_to do |format|
        format.html { redirect_to events_url, notice: "Membership was successfully destroyed." }
        format.json { render json: { errors: "None", status: 200 }, status: 200 }
      end
    else
      respond_to do |format|
        format.html { render :edit, error: "Membership could not be updated." }
        format.json { render json: { errors: @company_membership.errors.full_messages, status: 422 }, status: 422 }
      end
    end
  end

  # DELETE /events/1
  def destroy
    if @company_membership.destroy
      respond_to do |format|
        format.html { redirect_to "/", notice: "Membership was successfully destroyed." }
        format.json { render json: { errors: "None", status: 200 }, status: 200 }
      end
    else
      respond_to do |format|
        format.html { redirect_to "/", error: "Membership could not be deleted." }
        format.json { render json: { errors: @company_membership.errors.full_messages, status: 422 }, status: 422 }
      end
    end
  end

  def search
    # return all company members, of which the user is part of (used during reassignment)
    if not params[:q].present?
      respond_to do |format|
        format.html { render :edit, error: "Not found." }
        format.json { render json: { errors: "Not found.", status: 404 }, status: 404 }
      end
      return
    end

    term = Regexp.escape(params[:q].upcase)
    @user_companies = CompanyMembership.where({ user: current_user })
    @results = CompanyMembership.in({ sort_name: /^#{term}/,
                                      company_id: @user_companies.map(&:company_id)
                                    }).limit(50).uniq { |cm| cm.sort_name }

    respond_to do |format|
       format.json { render json: @results }
    end
  end

  private

  def must_be_producer
    @usermembership = CompanyMembership.where({ company: @company_membership.company, user: current_user })

    if @usermembership.count == 0
      respond_to do |format|
        format.html { render :edit, error: "Not a member." }
        format.json { render json: { errors: "Not a member of that company", status: 403 }, status: 403 }
      end
      nil
    else
      if @usermembership[0].access_level != ::CM_PRODUCER
        respond_to do |format|
          format.html { render :edit, error: "Insufficient access" }
          format.json { render json: { errors: "Insufficient access", status: 403 }, status: 403 }
        end
        nil
      end
    end
  end

  def set_company_membership
    @company_membership = CompanyMembership.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def company_membership_params
    params.require(:company_membership).permit(:access_level)
  end
end
