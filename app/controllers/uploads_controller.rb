class UploadsController < ApplicationController
  protect_from_forgery

  before_action :authenticate_user!

  def download
      @p = Passet.where(uuid: params[:fn])[0]
      if @p == nil
         raise ActionController::RoutingError.new("Asset not found")
      end

      if @p.created_by == current_user.id or current_user.try(:admin?)
        send_file "#{UPLOADS_DIR}/#{@p.uuid}", type: @p.kind
      end
  end
end
