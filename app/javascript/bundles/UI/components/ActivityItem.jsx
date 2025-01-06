import React from "react";
import PropTypes from "prop-types";
import moment from "moment";
import Avatar from "./Avatar";

const ActivityItem = (props) => {
  if (props.detailed == true) {
    var when = moment(props.activity.activity.created_at).format("LLL");
  } else {
    var when = "";
  }

  var ago = moment(props.activity.activity.created_at).fromNow();

  if (props.activity.owner != undefined) {
    var username = titleize(props.activity.owner.name);
    var userlink =
      "/profiles/" + props.activity.owner.username.replace(/[\/\& ]/g, "_");
    var person_s = <a href={userlink}>{username}</a>;
    var avatar = (
      <div>
        <Avatar
          name={props.activity.owner.name}
          facebookId={props.activity.owner.uid}
          src={props.activity.owner.avatar_uuid}
          size={45}
          round={true}
        />
      </div>
    );
  } else {
    var person_s = "Someone";
  }

  var verbed = "";

  var action = props.activity.activity.key.split(".");

  switch (action[1]) {
    case "create":
      switch (props.activity.activity.trackable_type.toLowerCase()) {
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

  switch (props.activity.activity.trackable_type.toLowerCase()) {
    case "passet":
      var object_s = " the file ";
      break;
    case "task":
      var object_s =
        ' a task, "' +
        props.activity.activity.parameters.txt +
        '", in the event ';
      var eventlink = "/events/" + props.activity.event._id + "/showpage";
      var title_s = (
        <span>
          {" "}
          <a href={eventlink}>{props.activity.event.title}</a>{" "}
        </span>
      );
      break;
    case "eventsubmission":
      var object_s = " an act ";
      if (props.activity.activity.parameters.event_id != undefined) {
        var object_s = " the act ";
        var eventlink =
          "/events/" +
          props.activity.activity.parameters.event_id +
          "/showpage";
        var actlink =
          "/acts/" + props.activity.activity.parameters.act_id + "/edit";
        var title_s = (
          <span>
            {" "}
            <a href={actlink}>
              {props.activity.activity.parameters.act_stage_name}
            </a>{" "}
            to{" "}
            <a href={eventlink}>
              {props.activity.activity.parameters.event_title}
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
      if (props.activity.event != undefined) {
        var eventlink =
          "/events/" + props.activity.event._id + "/showpage";
        var showlink =
          "/events/" +
          props.activity.event._id +
          "/showpage?active_show=" +
          props.activity.show._id;
        var title_s = (
          <span>
            <a href={eventlink}>{props.activity.event.title}</a>:{" "}
            <a href={showlink}>{props.activity.show.title}</a>
          </span>
        );
      } else {
        console.log(
          "No event for activity " +
            props.activity.activity._id +
            " - skipping"
        );
        return <div></div>;
      }
      break;

    default:
      var object_s =
        " the " + props.activity.activity.trackable_type.toLowerCase();
  }

  if (props.activity.activity.parameters.title != undefined) {
    var title_s = props.activity.activity.parameters.title;

    /* if this is not a delete, we'll link to it. */
    if (action[1] != "destroy") {
      switch (props.activity.activity.trackable_type.toLowerCase()) {
        case "act":
          var actlink =
            "/acts/" + props.activity.activity.trackable_id + "/edit";
          var title_s = (
            <a href={actlink}>{props.activity.activity.parameters.title}</a>
          );
          break;
        case "show":
          if (props.activity.activity.event != undefined) {
            var showlink =
              "/events/" +
              props.activity.event._id +
              "/showpage?active_show=" +
              props.activity.show._id;
          }
          var title_s = (
            <a href={showlink}>{props.activity.activity.parameters.title}</a>
          );
          break;
        case "event":
          var eventlink =
            "/events/" +
            props.activity.activity.trackable_id +
            "/showpage";
          var title_s = (
            <a href={eventlink}>{props.activity.activity.parameters.title}</a>
          );
          break;
        case "companymembership":
          var title_s = (
            <a href={eventlink}>
              {props.activity.activity.parameters.company_name}
            </a>
          );
          break;
      }
    }
  }

  if (props.activity.activity.parameters.company_name != undefined) {
    if (action[1] != "destroy") {
      switch (props.activity.activity.trackable_type.toLowerCase()) {
        case "companymembership":
          if (props.activity.company_membership) {
            var title_s = (
              <span>
                <a href={eventlink}>
                  {props.activity.activity.parameters.company_name}
                </a>{" "}
                as a {ACCESS_S[props.activity.company_membership.access_level]}
              </span>
            );
          } else {
            /* BUG: maybe? sometimes PA doesn't track the company membership object? */
            var title_s = (
              <span>
                <a href={eventlink}>
                  {props.activity.activity.parameters.company_name}
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
    <li className="media media-item-act">
      <div className="media-left media-middle">{avatar}</div>
      <div className="media-body">
        {whenhtml}
        <strong>{person_s}</strong> {verbed} {object_s} {title_s}
        <p>
          {ago}
          <br />
        </p>
      </div>
    </li>
  );
};

export default ActivityItem;
