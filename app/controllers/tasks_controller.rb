class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [ :update, :destroy ]

  protect_from_forgery

  def create
    begin
      @event = Event.find(params[:event_id])
    rescue Mongoid::Errors::DocumentNotFound, Mongoid::Errors::InvalidFind
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { errors: "Event for Task not found", status: 422 }, status: 422 }
      end
      return
    end

    # this is a critical section and there is a possibility of
    # concurrently issues here.
    @task = Task.new(task_params)
    @seqmax = Task.where(event: @event).max(:seq)
    if @seqmax.nil?
      @task.seq = 1
    else
      @task.seq = @seqmax + 1
    end

    if @task.save
      @task.create_activity action: "create", owner: current_user, parameters: { event_id: @event.id.to_s, txt: @task.txt }
      StatsD.increment("troupeit.tasks.create")
      respond_to do |format|
        format.html { redirect_to @task, notice: "Task was successfully created." }
        format.json { render json: @task.to_json }
      end

      PublicActivity.enabled = false
      @event.tasks << @task
      @event.save

    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { errors: @task.errors.full_messages, status: 422 }, status: 422 }
      end
    end
  end

  # PATCH/PUT /tasks/1
  def update
    if @task.update(task_params)
      @task.create_activity action: "update", owner: current_user, parameters: { event_id: @task.event.id.to_s, txt: @task.txt }

      StatsD.increment("troupeit.tasks.update")
      respond_to do |format|
        format.html { redirect_to "/", notice: "Task was successfully updated." }
        format.json { render json: { errors: "Task Updated", status: 200 }, status: 200 }
      end
    else
      respond_to do |format|
        format.html { render :edit, error: "Task could not be updated." }
        format.json { render json: { errors: @task.errors.full_messages, status: 422 }, status: 422 }
      end
    end
  end

  # DELETE /tasks/1
  def destroy
    # We have to do this before we destroy so that PA can get a view of the task
    # if the delete fails, our activity stream will be wrong.
    @task.create_activity action: "destroy", owner: current_user, parameters: { event_id: @task.event.id.to_s, txt: @task.txt }

    if @task.destroy
      StatsD.increment("troupeit.tasks.destroy")
      respond_to do |format|
        format.html { redirect_to "/", notice: "Task was successfully destroyed." }
        format.json { render json: { errors: "None", status: 200 }, status: 200 }
      end
    else
      respond_to do |format|
        format.html { redirect_to "/", error: "Task could not be deleted." }
        format.json { render json: { errors: @task.errors.full_messages, status: 422 }, status: 422 }
      end
    end
  end

  def update_seq
    if params[:tasks].blank?
      respond_to do |format|
        format.json { render json: { errors: "missing tasks", status: 422 }, status: 422 }
      end
      return
    end

    begin
      params[:tasks].each { |t, v|
        @task = Task.find(t)
        # SECURITY: do you have the right to change this?
        @task.seq = v
        @task.save
      }
    rescue Mongoid::Errors::DocumentNotFound
      respond_to do |format|
        format.json { render json: { errors: "could not find task #{t}", status: 422 }, status: 422 }
      end
      return
    end

    respond_to do |format|
      format.json { render json: { errors: "OK", status: 200 }, status: 200 }
    end
  end

  private

  def task_params
    params.require(:task).permit(:txt, :completed, :seq)
  end

  def set_task
    begin
      @task = Task.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      @task = nil
    end

    if @task.nil?
      # SECURITY: check if user is owner here?
      respond_to do |format|
        format.html { redirect_to "/", alert: "The selected task does not exist." }
        format.json { render json: { errors: "Not Found", status: 404 }, status: 404 }
      end

      @task
    end
  end
end
