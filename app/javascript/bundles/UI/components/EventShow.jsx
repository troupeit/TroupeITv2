import React, { useState, useEffect } from "react";
import moment from "moment";
import ShowPanel from "./ShowPanel";
import ShowForm from "./ShowForm";
import { checkCompanyAccess } from "./util";
import { ACCESS_PRODUCER } from "./constants";

const EventShow = (props) => {
  const [editingTitle, setEditingTitle] = useState(false);

  useEffect(() => {
    if ($.QueryString['active_show']) {
      $('.nav-tabs [href="#showpanel-' + $.QueryString['active_show'] + '"]').tab('show');
    }
  }, []);

  const enableEditing = () => {
    setEditingTitle(true);
  };

  const showFirstTab = () => {
    $('.nav-tabs a:first').tab('show');
  };

  if (props.eventData == null) {
    return (
      <div className="container">
        <i className="fa fa-spinner fa-spin"></i>
      </div>
    );
  }

  let tabheaderlines = "";
  let newactive = "";

  if (props.eventData.shows.length > 0) {
    tabheaderlines = props.eventData.shows.map((s) => {
      const ddate = moment(s.show.door_time);
      const ddate_s = ddate.format("ddd, MMM Do");
      const tabhref = "#showpanel-" + s.show._id.$oid;

      return (
        <li key={s.show._id.$oid}>
          <a href={tabhref} role="tab" data-toggle="tab">
            {ddate_s}
          </a>
        </li>
      );
    });
  }

  const showpanels = props.eventData.shows.map((s, n) => (
    <ShowPanel
      key={s.show._id.$oid}
      show={s.show}
      show_items={s.show_items}
      count={n}
      eventData={props.eventData}
      reloadCallback={props.reloadCallback}
      user={props.user}
      notemodal={props.notemodal}
      time_zone={props.eventData.event.time_zone}
    />
  ));

  let newshowpanel = null;
  let newshowtab = null;

  if (checkCompanyAccess(props.user, props.eventData.company._id.$oid, ACCESS_PRODUCER)) {
    newshowpanel = (
      <div role="tabpanel" className="tab-pane" id="newshow">
        <div className="panel panel-default">
          <div className="panel-body">
            <div className="row">
              <div className="col-md-12">
                <ShowForm
                  key="new-show-form"
                  event_id={props.eventData.event._id.$oid}
                  onCreate={props.reloadCallback}
                  onCancel={showFirstTab}
                  user={props.user}
                  company={props.eventData.company}
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    );

    newshowtab = (
      <li role="presentation" className={newactive}>
        <a href="#newshow" role="tab" aria-controls="new show" data-toggle="tab">
          <span className="glyphicon glyphicon-plus"></span>&nbsp;New Show
        </a>
      </li>
    );
  }

  return (
    <div className="row">
      <div className="col-md-12">
        <h1 style={{ marginBottom: "20px" }}>
          <small>{props.eventData.company.name}</small>
          <br />
          {props.eventData.event.title}
        </h1>
        <div role="tabpanel">
          <ul className="nav nav-tabs nav-tabs-inverse nav-justified nav-justified-mobile" role="tablist">
            {tabheaderlines}
            {newshowtab}
          </ul>
          <div className="tab-content">
            {showpanels}
            {newshowpanel}
          </div>
        </div>
      </div>
    </div>
  );
};

export default EventShow;