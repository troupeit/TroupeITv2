class BhofreviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :must_be_judgey
  before_action :get_current_round

  before_action :set_app, only: [ :create, :update ]
  before_action :set_bhofreview, only: [ :edit, :update, :destroy ]

  before_action :get_next_submitted_app, only: [ :create, :update ]

  before_action :verify_scoring_allowed, only: [ :create, :update ]

  def new
    @bhofreview = Bhofreview.new
  end

  def create
    created = false

    if params[:bhofreview][:recused] == "1"
      params[:bhofreview][:score] = 0.0
    end

    @bhofreview = Bhofreview.new(bhofreview_params)

    if @bhofreview.recused == true
      @bhofreview.score = 0
    end

    @bhofreview.app_id = @app.id
    @bhofreview.round = @round
    @bhofreview.judge_id = current_user.id

    if @bhofreview.save
      @app.bhofreviews << @bhofreview
      @app.save!
      created = true

      # flush the avg sorted and all-all version of the list, complete and incomplete views
      Rails.cache.delete("avgsorted-#{@app.entry.category}-0")
      Rails.cache.delete("avgsorted-0-0")
      Rails.cache.delete("avgsorted-#{@app.entry.category}-1")
      Rails.cache.delete("avgsorted-0-1")
      Rails.cache.delete("appscores-#{@app.entry.category}-0")
    end

    respond_to do |format|
      format.html {
        if created
          flash[:notice] = "Your review was saved."

          if params[:savetype] == "savenext" and @nextapp.present?
             @app = @nextapp
             redirect_to review_app_path(@app)
          else
            redirect_to adminindex_apps_path(sort: params[:sort], dir: params[:dir], catfilter: params[:catfilter])
          end

        else
          flash[:alert] = "Your review could not be saved."
          redirect_to adminindex_apps_path
        end
      }

      format.json {
        if created
          render json: @bhofreview
        else
          render json: {
            error: "Invalid score or app id",
            status: :not_acceptable
          }, status: :not_acceptable
        end
      }
    end
  end

  def update
    updateok = false

    if params[:bhofreview][:recused] == "1"
      params[:bhofreview][:score] = 0.0
    end

    if @bhofreview.update(bhofreview_params)
      updateok = true
      catkey = @app.entry.category.present? ?  @app.entry.category : "4"
      Rails.cache.delete("avgsorted-#{catkey}-0")
      Rails.cache.delete("avgsorted-0-0")
      Rails.cache.delete("avgsorted-#{catkey}-1")
      Rails.cache.delete("avgsorted-0-1")
      Rails.cache.delete("appscores-#{catkey}-0")
    end

    if params[:savetype] == "savenext" and @nextapp.present?
      @app = @nextapp

      bhr = Bhofreview.where({ judge_id: current_user.id, app_id: @app.id, round: @round })
      if bhr.length > 0
         @bhofreview = bhr[0]
      else
         @bhofreview = Bhofreview.new
      end
    end

    respond_to do |format|
       format.html {
         @entry = @app.entry
         @entry_techinfo = @app.entry_techinfo

         if updateok
           flash[:notice] = "Your review was updated."
         else
           flash[:alert] = "Your review could not be updated."
           redirect_to review_app_path(@app)
           return
         end

         if params[:savetype] == "savenext" and @nextapp.present?
            @app = @nextapp
            redirect_to review_app_path(@app)
         else
            redirect_to adminindex_apps_path(sort: params[:sort], dir: params[:dir], catfilter: params[:catfilter])
         end
       }

       format.json {
          if updateok
            render json: @bhofreview
          else
            render json: {
                 error: "Invalid score or app id",
                 status: :not_acceptable
             }, status: :not_acceptable
          end
       }
    end
  end

  def destroy
    destroyok = false

    if @bhofreview.judge_id == current_user.id
      if @bhofreview.delete
        destroyok = true
      end
    end

    respond_to do |format|
       if destroyok
         format.html {
            render { head :ok }
         }
         format.json {
            render json: {
                 error: "Success",
                 status: :ok
             }, status: :ok
         }
       else
         format.html {
            render { head :forbidden }
         }
         format.json {
            render json: {
                 error: "You do not own this review",
                 status: :forbidden
             }, status: :forbidden
         }
       end
    end
  end

  def show
    render nothing: true, status: 403
  end

  def index
    render nothing: true, status: 403
  end

  private

  def verify_scoring_allowed
    if DECIDER("bhof_scores_close") > 0
      flash[:alert] = "Scoring for this event is not currently allowed."
      redirect_to adminindex_apps_path
    end
  end

  def set_bhofreview
    @bhofreview = Bhofreview.find(params[:id])
  end

  def must_be_judgey
    if current_user.has_role?(:bhof_judge) or current_user.has_role?(:bhof_scorer)
      true
    else
      redirect_to root_path
    end
  end

  def set_app
    begin
      @app = App.find(params[:bhofreview][:app_id])
    rescue Mongoid::Errors::DocumentNotFound
      redirect_to "/apps/adminindex", alert: "Invalid App ID"
    rescue Mongoid::Errors::InvalidFind
      redirect_to "/apps/adminindex", alert: "No App specified"
    end
  end

  def bhofreview_params
    params.require(:bhofreview).permit(:score, :round, :comments, :next_round, :app_id, :recused)
  end

  def get_current_round
    @round = Decider.where({ key: "bhof_round" })[0].value_f.to_i
  end

  def get_next_submitted_app
    # the next app to us is the next one in a submitted state
    napp = App.where({ :id.gt => @app.id, :locked => 1 }).limit(1)
    if napp.length > 0
      @nextapp = napp[0]
    else
      @nextapp = nil
    end
  end
end
