import React, { useState } from "react";
import moment from "moment";
import ShowForm from "./ShowForm";
import EventShowItemList from "./EventShowItemList";
import ExportModal from "./ExportModal";
import { checkCompanyAccess } from "./util";
import { ACCESS_TECHCREW, ACCESS_STAGEMGR } from "./constants";

/**
 * ShowPanel component
 * @param {Object} props - Component properties
 * @param {Object} props.show - Show details
 * @param {Array} props.show_items - List of show items
 * @param {Function} props.reloadCallback - Callback to reload data
 * @param {Object} props.user - User details
 * @param {Object} props.eventData - Event data
 * @param {Object} props.notemodal - Note modal details
 * @param {string} props.time_zone - Time zone
 * @returns {JSX.Element} ShowPanel component
 */
const ShowPanel = (props) => {
  const [editing, setEditing] = useState(false);

  /**
   * Toggle edit mode
   */
  const toggleEdit = () => {
    setEditing(!editing);
  };

  /**
   * Handle update after form submission
   */
  const afterUpdate = () => {
    toggleEdit();
    props.reloadCallback();
  };

  /**
   * Start adding a note
   * @param {Event} event - Event object
   */
  const startAddNote = (event) => {
    props.notemodal.setState({
      id: null,
      color: "Red",
      color_class: "red_bg",
      notetext: null,
      duration: null,
      duration_secs: 0,
      type: 0,
    });

    props.notemodal.show(event);
    event.preventDefault();
  };

  /**
   * Show export modal
   * @param {Event} event - Event object
   */
  const showExportModal = (event) => {
    $('#exportModal').modal('show');
    event.preventDefault();
  };

  // Set up all of our date formatters
  const sdate = moment(props.show.show_time);
  const ddate = moment(props.show.door_time);

  const hd_show_time_s = sdate.tz(props.time_zone).format('h:mm a z');
  const hd_door_time_s = ddate.tz(props.time_zone).format('h:mm a z');
  const door_date_s = ddate.tz(props.time_zone).format('dddd, MMMM Do YYYY');

  const printlink = `/shows/${props.show._id.$oid}/perfindex`;
  const downloadlink = `/shows/${props.show._id.$oid}/download`;
  const livelink = `/shows/${props.show._id.$oid}/live`;

  const panelid = `showpanel-${props.show._id.$oid}`;
  let detailsarea = "";

  // Calculate show timings
  const show_time = moment(props.show.show_time);
  const door_time = moment(props.show.door_time);
  const end_time = moment(props.show.door_time);

  let duration = 0;
  for (let index = 0; index < props.show_items.length; duration += props.show_items[index].show_item.duration, ++index);

  const duration_s = formatDuration(duration, false);
  end_time.add(duration, 'seconds');
  const hd_end_time_s = end_time.tz(props.time_zone).format('h:mm a z');

  if (editing) {
    detailsarea = (
      <ShowForm
        id={props.show._id.$oid}
        title={props.show.title}
        venue={props.show.venue}
        room={props.show.room}
        show_time={sdate}
        door_time={ddate}
        onCancel={toggleEdit}
        onCreate={afterUpdate}
        user={props.user}
        company={props.eventData.company}
      />
    );
  } else {
    let room;
    if (props.show.room) {
      room = (<span><br />Room: {props.show.room}</span>);
    }

    const maplink = `https://www.google.com/maps?q=${props.show.venue}`;
    let dlwarning;
    if (moment(props.show.last_download_at).add(5, 'seconds').isBefore(moment(props.show.updated_at))) {
      dlwarning = (
        <div className="alert alert-block alert-warning" style={{ marginTop: "10px" }}>
          <strong>Warning!</strong> Changes have been made to this show (or acts in this show) since it was last downloaded.
          Make sure that you've downloaded all files and have the cue order correct when you run your show.
        </div>
      );
    }

    detailsarea = (
      <div>
        <div className="col-md-12">
          <h3 className="media-heading">{props.show.title}</h3>
          <h5>
            <strong>{door_date_s}</strong>
            <br />
            Doors: {hd_door_time_s} / Show: {hd_show_time_s} <br />
            Duration: {duration_s} / Ends: {hd_end_time_s}
          </h5>
          <h5>
            <a href={maplink} target="_map">
              <i className='glyphicon glyphicon-map-marker'></i>
            </a>&nbsp;
            {props.show.venue}
            {room}
            {dlwarning}
          </h5>
        </div>
      </div>
    );
  }

  let livebtn = "";
  let btn_liveview, btn_change, btn_addnote, btn_addact, btn_download, btn_print;

  if (props.show_items.length > 0 && checkCompanyAccess(props.user, props.eventData.company._id.$oid, ACCESS_TECHCREW)) {
    btn_liveview = (
      <a href={livelink}>
        <button className="btn btn-inverse btn-sm btn-block">
          <span className="glyphicon glyphicon-th-list"></span>
          &nbsp;
          Live view
        </button>
      </a>
    );
  }

  if (checkCompanyAccess(props.user, props.eventData.company._id.$oid, ACCESS_STAGEMGR)) {
    btn_change = (
      <button className="btn btn-info btn-sm btn-block" onClick={toggleEdit}>
        <span className="glyphicon glyphicon-pencil"></span>
        &nbsp;
        Change Details
      </button>
    );

    btn_addnote = (
      <button className="btn btn-info btn-sm btn-block" onClick={startAddNote}>
        <span className="glyphicon glyphicon-bullhorn"></span>
        &nbsp;
        Add Note / Break
      </button>
    );

    btn_addact = (
      <button className="btn btn-info btn-sm btn-block" data-toggle="modal" data-target="#actPicker">
        <span className="glyphicon glyphicon-plus"></span>
        &nbsp;
        Add act
      </button>
    );
  }

  if (checkCompanyAccess(props.user, props.eventData.company._id.$oid, ACCESS_TECHCREW) && props.show_items.length > 0) {
    btn_download = (
      <a href={downloadlink}>
        <button className="btn btn-info btn-sm btn-block" id="downloadBtn">
          <span className="glyphicon glyphicon-download"></span>
          &nbsp;
          Download
        </button>
      </a>
    );
  }

  const csvlink = `/shows/${props.show._id.$oid}.csv`;
  const xlslink = `/shows/${props.show._id.$oid}.xls`;
  const pdflink = `/shows/${props.show._id.$oid}.pdf`;

  if (props.show_items.length > 0) {
    btn_print = (
      <div className="dropdown">
        <button className="btn btn-info btn-sm btn-block" id={`dropdown-${props.show._id.$oid}`} data-toggle="dropdown">
          <span className="glyphicon glyphicon-print"></span>
          &nbsp;
          Export / Print&nbsp;<span className="caret"></span>
        </button>
        <ul className="dropdown-menu">
          <li>
            <a href={printlink} target="_printable">
              <i className="glyphicon glyphicon-list"></i> Simple List / MC Notes
            </a>
          </li>
          <li role="presentation">
            <a href={pdflink} target="_pdf" tabIndex="-1">
              <i className="glyphicon glyphicon-export"></i> Export as PDF
            </a>
          </li>
          <li role="presentation">
            <a href={csvlink} target="_csv" tabIndex="-1">
              <i className="glyphicon glyphicon-export"></i> Export as CSV
            </a>
          </li>
          <li role="presentation">
            <a href={xlslink} target="_xls" tabIndex="-1">
              <i className="glyphicon glyphicon-export"></i> Export as XLS
            </a>
          </li>
          <li role="presentation">
            <a href="#" onClick={showExportModal} target="_xls" tabIndex="-1">
              <i className="glyphicon glyphicon-export"></i> Custom PDF...
            </a>
          </li>
        </ul>
      </div>
    );
  }

  return (
    <div role="tabpanel" className="tab-pane fade in" id={panelid}>
      <div className="panel panel-default">
        <div className="panel-body">
          {detailsarea}
          <div className="row">
            <div className="col-xs-6 col-sm-6">
              {btn_change}&nbsp;
            </div>
            <div className="col-xs-6 col-sm-6">
              {btn_addnote}&nbsp;
            </div>
            <div className="col-xs-6 col-sm-6">
              {btn_addact}&nbsp;
            </div>
            <div className="col-xs-6 col-sm-6">
              {btn_print}&nbsp;
            </div>
            <div className="col-xs-6 col-sm-6">
              {btn_download}&nbsp;
            </div>
            <div className="col-xs-6 col-sm-6">
              {btn_liveview}&nbsp;
            </div>
          </div>
          <EventShowItemList
            show={props.show}
            show_items={props.show_items}
            reloadCallback={props.reloadCallback}
            user={props.user}
            event={props.eventData}
            notemodal={props.notemodal}
          />
        </div>
      </div>
      <ExportModal {...props} />
    </div>
  );
};

export default ShowPanel;
