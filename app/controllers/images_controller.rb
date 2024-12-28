class ImagesController < ActionController::Base
  before_action :authenticate_user!

  # for development use, serve thumbs via ruby. We'd normally route
  # these via paseenger/sendfile but we can only do one path at a time.
  def servethumb
    fn = "#{THUMBS_DIR}/" + FileTools.sanitize_filename(params[:uuid]) + "-" + FileTools.sanitize_filename(params[:dims]) + ".jpg"

    logger.debug "serve: #{fn}, uuid: #{params[:uuid]}"

    if File.exist?(fn) == false
      @image = Passet.where({ uuid: params["uuid"] })[0]
      if @image == nil
        raise ActionController::RoutingError.new("Image Not Found (srv)")
      end

      width, height = params[:dims].scan(/\d+/).map(&:to_i)
      @image.thumbnail!(width, height)
    end

    send_file "#{fn}", type: "image/jpeg",
                       x_sendfile: true,
                       stream: true,
                       buffer_size: 4096,
                       disposition: "inline"
  end

  def servefull
    p = Passet.where(uuid: params[:uuid])

    if p == nil
      raise ActionController::RoutingError.new("Image Not Found (srv)")
    end

    fn = "#{UPLOADS_DIR}/" + FileTools.sanitize_filename(params[:uuid])
    logger.debug "servefull: #{fn}, uuid: #{params[:uuid]}, file: #{p[0].filename}"

    disposition = params[:download] == "1" ? "attachment" : "inline"

    if File.exist?(fn) == false
      raise ActionController::RoutingError.new("Image Not Found (srv)")
    else
      send_file "#{fn}", type: p[0].kind,
                         x_sendfile: true,
                         stream: true,
                         buffer_size: 8192,
                         disposition: disposition,
                         filename: p[0].filename
    end
  end
end
