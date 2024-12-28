class CueListReportPdf < PdfReport
  LEGAL = { x: 612.00, y: 1008.00 }
  LETTER = { x: 612.00, y: 792.00 }

  @active_cols = 0

  # cells with more than this many chars are truncated.
  MAX_CELL_CHARS = 9999

  def initialize(user, show, order, checked)
    @show = show
    @order = order
    @checked = checked
    @current_user = user
    super(page_layout: :landscape,
          page_size: "LETTER",
          margin: [ 10, 10, 10, 10 ])

    header "#{show.event.title} - #{show.title}",
           "Door Time: #{show.door_time.strftime(SHORT_TIME_FMT_TZ)} | " +
           "Show Time: #{show.show_time.strftime(SHORT_TIME_FMT_TZ)} | " +
           "Printed: #{Time.now.in_time_zone(@show.event.time_zone).strftime(SHORT_TIME_FMT_TZ)} ",
           show.venue

    display_cue_table
    footer
  end

  # temporary debugging hook because you can't hit the rails logger from this class.
  #  def logit(msg)
  #    File.open("/tmp/cue.log","w+") { |f|
  #      f.write(msg)
  #    }
  #  end

  private

  def display_cue_table
    lcol = 200  # the large column, used to hold the cue list information
    scol_default = 75   # subsequent columns
    cuecol = 140

    if table_data.empty?
      text "No cues found in the selected show."
    else
      table table_data do |table|
        table.header = true
        table.row(0).font_style = :bold
        table.column(0).align = :right

        # determine how many columns are actually in use.
        @active_cols = 0
        col_widths = { 0 => 25, 1=> cuecol }

        # we have to do this twice unfortunately.
        @checked.each { |c|
          if c.to_i == 1
            @active_cols = @active_cols + 1
          end
        }

        # compute column width based on active columns
        i = 2
        scol = ((scol_default*8) / @active_cols).floor
        @checked.each { |c|
          if c.to_i == 1
            col_widths[i] = scol
            i = i + 1
          end
        }

        table.column_widths = col_widths
        table.row_colors = TABLE_ROW_COLORS
      end
    end
  end

  def table_data
    # determine how many columns are actually in use.
    @active_cols = 0
    @checked.each { |c|
      if c.to_i == 1
        @active_cols = @active_cols + 1
      end
    }

    cuetime = @show.door_time

    td ||= @show.show_items.map { |si|
      owner = ""
      if si.act.present?
        owner = si.act.user.name
      end

      cuetable = (make_table [
                               [ cuetime.strftime("%l:%M %p"), "+" + TimeTools.sec_to_time(si.duration) ],
                               [ { content: si.title, colspan: 2 } ],
                               [ { content: owner, colspan: 2 } ]
                             ], column_widths: { 0 => 70, 1 => 70 }, header: false)

      cuetable.cells.row(0).style(align: :center)
      cuetable.cells.row(1).borders = [ :left, :right ]
      cuetable.cells.row(1).font_style = :bold
      cuetable.cells.row(2).borders = [ :left, :right ]

      if si.kind == ShowItem::KIND_ASSET
        # asset
        if not si.act.nil?
          row = [ si.seq, cuetable ]
          i = 0
          @order.each { |o|
            if @checked[i].to_i == 1
              case o.to_i
              when 0
                row << si.act.mc_intro.truncate(MAX_CELL_CHARS)
              when 1
                row << si.act.sound_cue.truncate(MAX_CELL_CHARS)
              when 2
                row << si.act.lighting_info.truncate(MAX_CELL_CHARS)
              when 3
                row << si.act.prop_placement.truncate(MAX_CELL_CHARS)
              when 4
                row << si.act.clean_up.truncate(MAX_CELL_CHARS)
              when 5
                row << si.act.extra_notes.truncate(MAX_CELL_CHARS)
              when 6
                row << si.get_note(@current_user, ShowItemNote::KIND_COMPANY)
              when 7
                row << si.get_note(@current_user, ShowItemNote::KIND_PRIVATE)
              end
            end
            i = i + 1
          }
        else
          row = [ si.seq,
            { content: " *** Deleted Act *** ", colspan: @active_cols } ]
        end
      else
        # note
        row = [ si.seq,
                cuetable,
                { content: si.title, colspan: @active_cols }
              ]
      end

      if si.duration.present?
        cuetime = cuetime + si.duration
      end

      row
    }

    # construct table headers
    toprow = [ "#", "Cue" ]
    i = 0
    @order.each { |o|
      if @checked[i].to_i == 1
        case o.to_i
        when 0
          toprow << "MC Intro"
        when 1
          toprow << "Sound"
        when 2
          toprow << "Lights"
        when 3
          toprow << "Props/Stage"
        when 4
          toprow << "Cleanup"
        when 5
          toprow << "Performer\nNotes"
        when 6
          toprow << "Company\nNotes"
        when 7
          toprow << "Personal\nNotes"
        end
      end
      i = i + 1
    }

    [ toprow ] + td
  end
end
