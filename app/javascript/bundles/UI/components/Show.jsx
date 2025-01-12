import React, { useState } from "react";
import moment from "moment";
import "moment-timezone";

import { checkCompanyAccess } from "./util";
import { ACCESS_STAGEMGR } from "./constants";

const Show = (props) => {
  /*  componentDidMount: function () {
      $("[data-toggle='tooltip']").tooltip({html: true});
  },
  componentDidUpdate: function () {
      $("[data-toggle='tooltip']").tooltip({html: true});
  },
*/
  const {
    id,
    title,
    venue,
    room,
    goog_place_id,
    show_time,
    door_time,
    user,
    company,
    reloadCallback,
    time_zone,
  } = props;

  const [editing, setEditing] = useState(false);

  const toggleEdit = (event) => {
    setEditing(!editing);
    event.preventDefault();
  };

  const postUpdate = () => {
    setEditing(false);
    reloadCallback();
  };

  const startDelete = (event) => {
    event.preventDefault();
    $("#okBtn").onClick(handleDelete);
    $("#confirmModalTitle").html("Delete Show: " + title);
    $("#confirmModal").modal("show");
  };

  const handleDelete = (event) => {
    $("#confirmModal").modal("hide");

    $.ajax({
      type: "DELETE",
      url: "/shows/" + id + ".json",
      dataType: "json",
      contentType: "application/json",
      success: function (response) {
        reloadCallback();
      },
      error: function (xhr, status, err) {
        console.error("Delete failed.", status, err.toString());
      },
    });
    event.preventDefault();
  };

  // render
  var ddate = moment(door_time);
  var door_date_s = ddate.tz(time_zone).format("dddd, MMMM Do YYYY, h:mm A z");
  var content;

  if (checkCompanyAccess(user, company._id, ACCESS_STAGEMGR)) {
    var editdelbtns = (
      <div>
        <button
          onClick={toggleEdit}
          className="btn btn-sm btn-warning fas fa-pencil"
          data-toggle="tooltip"
          data-placement="left"
          title="Edit Show Details"
        ></button>
        &nbsp;
        <button
          onClick={startDelete}
          className="btn btn-sm btn-danger fas fa-trash"
          data-toggle="tooltip"
          data-placement="left"
          title="Delete this Show"
        ></button>
      </div>
    );
  }

  if (editing == true) {
    content = (
      <ShowForm
        id={id}
        title={title}
        venue={venue}
        room={room}
        goog_place_id={goog_place_id}
        show_time={show_time}
        door_time={door_time}
        onCancel={toggleEdit}
        onCreate={postUpdate}
        user={user}
        company={company}
      />
    );
  } else {
    let roomSpan = null;
    if (room !== null) {
      if (room != "") {
        roomSpan = (
          <span>
            <br />
            Room: {room}
          </span>
        );
      }
    }

    let maplink = "https://www.google.com/maps?q=" + venue;

    content = (
      <div className="show">
        <h4 className="showTitle">{title}</h4>
        <div className="showControls">{editdelbtns}</div>
        <strong>Doors:</strong> {door_date_s}
        <br />
        <a href={maplink} target="_map">
          <i className="fas fa-map-marker"></i>
        </a>
        &nbsp;
        {venue}
        {roomSpan}
      </div>
    );
  }

  return content;
};

export default Show;
