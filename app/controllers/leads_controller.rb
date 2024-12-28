class LeadsController < ApplicationController
  protect_from_forgery

  def create
    @lead = Lead.new(lead_params)

    # are they trying an invite code?
    if @lead.email !~ /@/
      @invites = SignupInvite.where({ code: /#{@lead.email}/i })

      if @invites.count == 0
        # failed
        respond_to do |format|
          format.html { render nothing: true,  status: 403 }
          format.json { render json: { errors: "Not an email and not a valid invite code. " }, status: 403 }
        end
        return
      else
        @invites[0].inc(used_count: 1)

        respond_to do |format|
          format.html { render nothing: true,  status: 200 }
          format.json { render json: { errors: "Valid invite code." }, status: 200 }
        end
        return
      end
    end

    # nope, save it.
    @lead.save

    respond_to do |format|
      format.html { render nothing: true,  status: 201 }
      format.json { render json: { errors: "Saved." }, status: 201 }
    end
  end

  private

  def lead_params
    params.require(:lead).permit(:email, :name)
  end
end
