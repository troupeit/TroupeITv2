import React, { useState, useEffect } from "react";
import moment from "moment";
import {Tab} from "bootstrap";
import ShowPanel from "./ShowPanel";
import ShowForm from "./ShowForm";
import { checkCompanyAccess } from "./util";
import { ACCESS_PRODUCER } from "./constants";

/**
 * EventShow component
 * @param {Object} props - Component properties
 * @param {Object} props.eventData - Event data
 * @param {Function} props.reloadCallback - Callback to reload data
 * @param {Object} props.user - User details
 * @param {Object} props.notemodal - Note modal details
 * @returns {JSX.Element} EventShow component
 */
const EventShow = ({ eventData, reloadCallback, user, notemodal }) => {
  const [editingTitle, setEditingTitle] = useState(false);

  useEffect(() => {
    if ($.QueryString['active_show']) {
      $('.nav-tabs [href="#showpanel-' + $.QueryString['active_show'] + '"]').trigger("click");
    }
  }, []);

  const enableEditing = () => {
    setEditingTitle(true);
  };

  const showFirstTab = () => {
    // Select first tab and fire bootstrap tab event
    const triggerFirstTabEl = document.querySelector('#showheader-' + eventData.shows[0].show._id)
    Tab.getInstance(triggerFirstTabEl).show() 
  };

  if (eventData == null) {
    return (
      <div className="container">
        <div className="spinner-border text-primary" role="status">
        </div>
      </div>
    );
  }

  // Construct tab headers
  let tabHeaders = "";

  if (eventData.shows.length > 0) {
    tabHeaders = eventData.shows.map((s, index) => {
      const doorTime = moment(s.show.door_time);
      const doorTime_s = doorTime.format("ddd, MMM Do");
      const tabHREF = "#showpane" + s.show._id;
      const active = index === 0 ? "active" : "";

      return (
        <li className="nav-item" role="presentation" key={s.show._id}>
          <a className={ "nav-link" + " " + active}
            id={"showheader-" + s.show._id}
            href={tabHREF} 
            role="tab" 
            data-bs-toggle="tab">
            <span className="d-sm-block d-none">{doorTime_s}</span>
          </a>
        </li>
      );
    });
  }

  const showPanels = eventData.shows.map((s, n) => (
    <ShowPanel
      key={s.show._id}
      show={s.show}
      show_items={s.show_items}
      active={n === 0}
      eventData={eventData}
      reloadCallback={reloadCallback}
      user={user}
      notemodal={notemodal}
      time_zone={eventData.event.time_zone}
    />
  ));

  let newShowPanel = null;
  let newShowTab = null;

  if (checkCompanyAccess(user, eventData.company._id, ACCESS_PRODUCER)) {
    newShowPanel = (
      <div role="tabpanel" className="tab-pane fade show" id="showpanel-newshow">
        <div className="card">
          <div className="card-body">
            <div className="row">
              <div className="col-md-12">
                <ShowForm
                  key="new-show-form"
                  event_id={eventData.event._id}
                  onCreate={reloadCallback}
                  onCancel={showFirstTab}
                  user={user}
                  company={eventData.company}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    );

    newShowTab = (
      <li className="nav-item" role="presentation">
        <a className="nav-link" href="#showpanel-newshow" role="tab" aria-controls="new show" data-bs-toggle="tab">
          <span className="fas fa-plus"></span>&nbsp;New Show
      </a>
      </li>
    );
  }

  return (
    <div className="row">
      <div className="col-md-12">
        <h1 style={{ marginBottom: "20px" }}>
          <small>{eventData.company.name}</small>
          <br />
          {eventData.event.title}
        </h1>
          <ul className="nav nav-tabs nav-fill" role="tablist">
            {tabHeaders}
            {newShowTab}
          </ul>
          <div className="tab-content panel rounded-0 m-0">
            {showPanels}
            {newShowPanel}
          </div>
      </div>
    </div>
  );
};

export default EventShow;
