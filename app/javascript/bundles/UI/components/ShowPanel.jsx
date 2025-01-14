import React, { useState } from "react";
import moment from "moment";
import ShowForm from "./ShowForm";
import EventShowItemList from "./EventShowItemList";
import ExportModal from "./ExportModal";
import { checkCompanyAccess, formatDuration } from "./util";
import { ACCESS_TECHCREW, ACCESS_STAGEMGR } from "./constants";

/**
 * ShowPanel component
 * @param {Object} props - Component properties
 * @param {Object} show - Show details
 * @param {Array} show_items - List of show items
 * @param {Function} reloadCallback - Callback to reload data
 * @param {Object} user - User details
 * @param {Object} eventData - Event data
 * @param {Object} notemodal - Note modal details
 * @param {string} time_zone - Time zone
 * @returns {JSX.Element} ShowPanel component
 */
const ShowPanel = (props) => {
  const { show, show_items, active, eventData, reloadCallback, user, notemodal, time_zone } = props;
  
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
    reloadCallback();
  };

  /**
   * Start adding a note
   * @param {Event} event - Event object
   */
  const startAddNote = (event) => {
    notemodal.setState({
      id: null,
      color: "Red",
      color_class: "red_bg",
      notetext: null,
      duration: null,
      duration_secs: 0,
      type: 0,
    });

    notemodal.show(event);
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
  const sdate = moment(show.show_time);
  const ddate = moment(show.door_time);

  const hd_show_time_s = sdate.tz(time_zone).format('h:mm a z');
  const hd_door_time_s = ddate.tz(time_zone).format('h:mm a z');
  const door_date_s = ddate.tz(time_zone).format('dddd, MMMM Do YYYY');

  const printlink = `/shows/${show._id}/perfindex`;
  const downloadlink = `/shows/${show._id}/download`;
  const livelink = `/shows/${show._id}/live`;

  const paneID = `showpane${show._id}`;
  let detailsarea = "";

  // Calculate show timings
  const show_time = moment(show.show_time);
  const door_time = moment(show.door_time);
  const end_time = moment(show.door_time);

  let duration = 0;
  for (let index = 0; index < show_items.length; duration += show_items[index].show_item.duration, ++index);

  const duration_s = formatDuration(duration, false);
  end_time.add(duration, 'seconds');
  const hd_end_time_s = end_time.tz(time_zone).format('h:mm a z');

  if (editing) {
    detailsarea = (
      <ShowForm
        id={show._id}
        title={show.title}
        venue={show.venue}
        room={show.room}
        show_time={sdate}
        door_time={ddate}
        onCancel={toggleEdit}
        onCreate={afterUpdate}
        user={user}
        company={eventData.company}
      />
    );
  } else {
    let room;
    if (show.room) {
      room = (<span><br />Room: {show.room}</span>);
    }

    const maplink = `https://www.google.com/maps?q=${show.venue}`;
    let dlwarning;
    if (moment(show.last_download_at).add(5, 'seconds').isBefore(moment(show.updated_at))) {
      dlwarning = (
        <div className="alert alert-warning mt-2">
          <strong>Warning!</strong> Changes have been made to this show (or acts in this show) since it was last downloaded.
          Make sure that you've downloaded all files and have the cue order correct when you run your show.
        </div>
      );
    }

    detailsarea = (
      <div>
        <div className="col-12">
          <h3 className="media-heading">{show.title}</h3>
          <h5>
            <strong>{door_date_s}</strong>
            <br />
            Doors: {hd_door_time_s} / Show: {hd_show_time_s} <br />
            Duration: {duration_s} / Ends: {hd_end_time_s}
          </h5>
          <h5>
            <a href={maplink} target="_map">
              <i className='fas fa-location-dot'></i>
            </a>&nbsp;
            {show.venue}
            {room}
            {dlwarning}
          </h5>
        </div>
      </div>
    );
  }

  let livebtn = "";
  let btn_liveview, btn_change, btn_addnote, btn_addact, btn_download, btn_print;

  if (show_items.length > 0 && checkCompanyAccess(user, eventData.company._id, ACCESS_TECHCREW)) {
    btn_liveview = (
      <a href={livelink}>
        <button className="btn btn-dark btn-sm w-100">
          <span className="fas fa-list"></span>
          &nbsp;
          Live view
        </button>
      </a>
    );
  }

  if (checkCompanyAccess(user, eventData.company._id, ACCESS_STAGEMGR)) {
    btn_change = (
      <button className="btn btn-info btn-sm w-100" onClick={toggleEdit}>
        <span className="fas fa-pencil"></span>
        &nbsp;
        Change Details
      </button>
    );

    btn_addnote = (
      <button className="btn btn-info btn-sm w-100" onClick={startAddNote}>
        <span className="fas fa-bullhorn"></span>
        &nbsp;
        Add Note / Break
      </button>
    );

    btn_addact = (
      <button className="btn btn-info btn-sm w-100" data-bs-toggle="modal" data-bs-target="#actPicker">
        <span className="fas fa-plus"></span>
        &nbsp;
        Add act
      </button>
    );
  }

  if (checkCompanyAccess(user, eventData.company._id, ACCESS_TECHCREW) && show_items.length > 0) {
    btn_download = (
      <a href={downloadlink}>
        <button className="btn btn-info btn-sm w-100" id="downloadBtn">
          <span className="fas fa-download"></span>
          &nbsp;
          Download
        </button>
      </a>
    );
  }

  const csvlink = `/shows/${show._id}.csv`;
  const xlslink = `/shows/${show._id}.xls`;
  const pdflink = `/shows/${show._id}.pdf`;

  if (show_items.length > 0) {
    btn_print = (
      <div className="dropdown">
        <button className="btn btn-info btn-sm w-100 dropdown-toggle" id={`dropdown-${show._id}`} data-bs-toggle="dropdown">
          <span className="bi bi-printer"></span>
          &nbsp;
          Export / Print&nbsp;<span className="caret"></span>
        </button>
        <ul className="dropdown-menu">
          <li>
            <a href={printlink} target="_printable">
              <i className="bi bi-list"></i> Simple List / MC Notes
            </a>
          </li>
          <li role="presentation">
            <a href={pdflink} target="_pdf" tabIndex="-1">
              <i className="bi bi-file-earmark-pdf"></i> Export as PDF
            </a>
          </li>
          <li role="presentation">
            <a href={csvlink} target="_csv" tabIndex="-1">
              <i className="bi bi-file-earmark-spreadsheet"></i> Export as CSV
            </a>
          </li>
          <li role="presentation">
            <a href={xlslink} target="_xls" tabIndex="-1">
              <i className="bi bi-file-earmark-spreadsheet"></i> Export as XLS
            </a>
          </li>
          <li role="presentation">
            <a href="#" onClick={showExportModal} target="_xls" tabIndex="-1">
              <i className="bi bi-file-earmark-pdf"></i> Custom PDF...
            </a>
          </li>
        </ul>
      </div>
    );
  }

  return (
    <div className={"p-4 tab-pane fade show" + (active ? " " + "active" : "")} id={paneID} role="tabpanel">							
      {detailsarea}
      <div className="row">
        <div className="col-6">
          {btn_change}&nbsp;
        </div>
        <div className="col-6">
          {btn_addnote}&nbsp;
        </div>
        <div className="col-6">
          {btn_addact}&nbsp;
        </div>
        <div className="col-6">
          {btn_print}&nbsp;
        </div>
        <div className="col-6">
          {btn_download}&nbsp;
        </div>
        <div className="col-6">
          {btn_liveview}&nbsp;
        </div>
      </div>
      <EventShowItemList
          show={show}
          show_items={show_items}
          reloadCallback={reloadCallback}
          user={user}
          event={eventData}
          notemodal={notemodal}
        />
      <ExportModal {...props} />
    </div>
  );
};

export default ShowPanel;
