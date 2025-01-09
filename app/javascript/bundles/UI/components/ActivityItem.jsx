import React from "react";
import moment from "moment";
import Avatar from "./Avatar";

import { titleize } from "./util";
import { ACCESS_S } from "./constants";

const ActivityItem = (props) => {
  const { activityRecord, detailed } = props;

  if (detailed == true) {
    var when = moment(activityRecord.activity.created_at).format("LLL");
  } else {
    var when = "";
  }

  var ago = moment(activityRecord.activity.created_at).fromNow();

  if (activityRecord.owner != undefined) {
    var username = titleize(activityRecord.owner.name);
    var userlink =
      "/profiles/" + activityRecord.owner.username.replace(/[\/\& ]/g, "_");
    var person_s = <a href={userlink}>{username}</a>;
    var avatar = (
      <div>
        <Avatar
          name={activityRecord.owner.name}
          facebookId={activityRecord.owner.uid}
          src={activityRecord.owner.avatar_uuid}
          size={45}
          round={true}
          inline={false}
        />
      </div>
    );
  } else {
    var person_s = "Someone";
  }

  var verbed = "";

  var action = activityRecord.activity.key.split(".");

  switch (action[1]) {
    case "create":
      switch (activityRecord.activity.trackable_type.toLowerCase()) {
        case "passet":
          verbed = "uploaded";
          break;
        case "companymembership":
          verbed = "joined";
          break;
        case "eventsubmission":
          verbed = "submitted";
          break;
        default:
          verbed = "created";
          break;
      }
      break;
    case "destroy":
      verbed = "deleted";
      break;

    case "update":
      verbed = "updated";
      break;

    case "item_moved":
      verbed = "moved";
      break;

    case "item_duplicated":
      verbed = "duplicated";
      break;
  }

  switch (activityRecord.activity.trackable_type.toLowerCase()) {
    case "passet":
      var object_s = " the file ";
      break;
    case "task":
      var object_s =
        ' a task, "' +
        activityRecord.activity.parameters.txt +
        '", in the event ';
      var eventlink = "/events/" + activityRecord.event._id + "/showpage";
      var title_s = (
        <span>
          {" "}
          <a href={eventlink}>{activityRecord.event.title}</a>{" "}
        </span>
      );
      break;
    case "eventsubmission":
      var object_s = " an act ";
      if (activityRecord.activity.parameters.event_id != undefined) {
        var object_s = " the act ";
        var eventlink =
          "/events/" +
          activityRecord.activity.parameters.event_id +
          "/showpage";
        var actlink =
          "/acts/" + activityRecord.activity.parameters.act_id + "/edit";
        var title_s = (
          <span>
            {" "}
            <a href={actlink}>
              {activityRecord.activity.parameters.act_stage_name}
            </a>{" "}
            to{" "}
            <a href={eventlink}>
              {activityRecord.activity.parameters.event_title}
            </a>{" "}
          </span>
        );
      }
      break;
    case "companymembership":
      var object_s = " the company ";
      break;
    case "showitem":
      var object_s = " a cue in show ";
      if (activityRecord.event != undefined) {
        var eventlink =
          "/events/" + activityRecord.event._id + "/showpage";
        var showlink =
          "/events/" +
          activityRecord.event._id +
          "/showpage?active_show=" +
          activityRecord.show._id;
        var title_s = (
          <span>
            <a href={eventlink}>{activityRecord.event.title}</a>:{" "}
            <a href={showlink}>{activityRecord.show.title}</a>
          </span>
        );
      } else {
        console.log(
          "No event for activity " +
          activityRecord.activity._id +
            " - skipping"
        );
        return <div></div>;
      }
      break;

    default:
      var object_s =
        " the " + activityRecord.activity.trackable_type.toLowerCase();
  }

  if (activityRecord.activity.parameters.title != undefined) {
    var title_s = activityRecord.activity.parameters.title;

    /* if this is not a delete, we'll link to it. */
    if (action[1] != "destroy") {
      switch (activityRecord.activity.trackable_type.toLowerCase()) {
        case "act":
          var actlink =
            "/acts/" + activityRecord.activity.trackable_id + "/edit";
          var title_s = (
            <a href={actlink}>{activityRecord.activity.parameters.title}</a>
          );
          break;
        case "show":
          if (activityRecord.activity.event != undefined) {
            var showlink =
              "/events/" +
              activityRecord.event._id +
              "/showpage?active_show=" +
              activityRecord.show._id;
          }
          var title_s = (
            <a href={showlink}>{activityRecord.activity.parameters.title}</a>
          );
          break;
        case "event":
          var eventlink =
            "/events/" +
            activity.activity.trackable_id +
            "/showpage";
          var title_s = (
            <a href={eventlink}>{activityRecord.activity.parameters.title}</a>
          );
          break;
        case "companymembership":
          var title_s = (
            <a href={eventlink}>
              {activityRecord.activity.parameters.company_name}
            </a>
          );
          break;
      }
    }
  }

  if (activityRecord.activity.parameters.company_name != undefined) {
    if (action[1] != "destroy") {
      switch (activityRecord.activity.trackable_type.toLowerCase()) {
        case "companymembership":
          if (activityRecord.company_membership) {
            var title_s = (
              <span>
                <a href={eventlink}>
                  {activityRecord.activity.parameters.company_name}
                </a>{" "}
                as a {ACCESS_S[activityRecord.company_membership.access_level]}
              </span>
            );
          } else {
            /* BUG: maybe? sometimes PA doesn't track the company membership object? */
            var title_s = (
              <span>
                <a href={eventlink}>
                  {activityRecord.activity.parameters.company_name}
                </a>
              </span>
            );
          }
          break;
      }
    }
  }
  if (when != "") {
    var whenhtml = (
      <div>
        {when}
        <br />
      </div>
    );
  }

  return (
    <div className="d-flex">
      <div className="flex-shrink-0">
        {avatar}
      </div>
      <div className="flex-grow-1 ms-3">
        {whenhtml}
        <strong>{person_s}</strong> {verbed} {object_s} {title_s}
        <p>
          {ago}
          <br />
        </p>
      </div>
    </div>
  );

};

export default ActivityItem;
