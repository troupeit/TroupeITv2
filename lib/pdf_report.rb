class PdfReport < Prawn::Document
  # Often-Used Constants
  TABLE_ROW_COLORS = [ "FFFFFF", "DDDDDD" ]
  TABLE_FONT_SIZE = 10
  TABLE_BORDER_STYLE = :grid

  def initialize(default_prawn_options = {})
    super(default_prawn_options)
    font_size TABLE_FONT_SIZE
    font_families.update("Arial" => {
                           normal: Rails.root.join("app", "assets", "fonts", "Arial.ttf").to_s,
                           italic: Rails.root.join("app", "assets", "fonts", "Arial Italic.ttf").to_s,
                           bold: Rails.root.join("app", "assets", "fonts", "Arial Bold.ttf").to_s,
                           bold_italic: Rails.root.join("app", "assets", "fonts", "Arial Bold Italic.ttf").to_s
                         })
  end

  def header(title = nil, subtitle = nil, subsubtitle = nil)
    font "Arial"
    text title, size: 18, style: :bold, align: :center

    if not subtitle.nil?
      text subtitle, size: 10, align: :center
    end

    if not subsubtitle.nil?
      text subsubtitle, size: 10, style: :italic, align: :center
    end
  end

  def footer
    font "Arial"
    move_down 20
    text "Powered by troupe IT - www.troupeit.com", size: 8
  end
end
