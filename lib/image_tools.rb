require "rmagick"
require "fileutils"

module ImageTools
  class << self
    include Magick

    def thumbnail(source, target, width, height = nil)
      return nil unless File.file?(source)
      height ||= width

      begin
        img = Image.read(source).first
      rescue Magick::ImageMagickError
        return nil
      rescue ActionController::MissingFile
        return nil
      end

      rows, cols = img.rows, img.columns

      source_aspect = cols.to_f / rows
      target_aspect = width.to_f / height
      thumbnail_wider = target_aspect > source_aspect

      factor = thumbnail_wider ? width.to_f / cols : height.to_f / rows
      img.thumbnail!(factor)
      img.crop!(CenterGravity, width, height)

      img.write(target) { self.quality = 75 }
    end
  end
end
