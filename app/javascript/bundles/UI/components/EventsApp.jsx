import React, { useState, useEffect, useRef } from "react";
import { ACCESS_STAGEMGR, ACCESS_PRODUCER } from "./constants";
import { checkCompanyAccess } from "./util";

import EventShow from "./EventShow";
import EventActPicker from "./EventActPicker";
import NoteModal from "./NoteModal";
import SubmissionDeadlineModal from "./SubmissionDeadlineModal";
import SubmittedActsBox from "./SubmittedActsBox";
import TaskList from "./TaskList";
import EventSubmissionBox from "./EventSubmissionBox";

// TBD: Convert all ajax calls over to react-query here
// import { useQuery } from '@tanstack/react-query';
import { io } from "socket.io-client";
import { SOCKIO_SERVER } from "./constants";

/**
 * EventsApp
 *
 * @param {*} props
 */
const EventsApp = (props) => {
  const { event_id } = props;

  const [eventData, setEventData] = useState(null);
  const [headerEdit, setHeaderEdit] = useState(false);
  const [motd, setMotd] = useState("");
  const [user, setUser] = useState(null);
  const [subscribed, setSubscribed] = useState(false);

  /* modal refs */
  const noteModalRef = useRef(null);
  const submissionDeadlineModalRef = useRef(null);

  /* websocket access and last heartbeat */
  let socket;
  let _lasthb;

  /* reload the user on initial load */
  useEffect(() => {
    // going to trigger this anyway
    reloadEvent();
    reloadUser();

    socket = io.connect(SOCKIO_SERVER);

    // setup socket callbacks
    socket.on("connect", function (data) {
      console.log("connected to greenroom.");
      setSubscribed(false);
    });

    socket.on("reloadnow", function (data) {
      reloadEvent();
      reloadUser();
    });

    socket.on("heartbeat", function (data) {
      // if this is stored in-state, we get false reloads. let's not do that.
      _lasthb = new Date().getTime() / 1000;
    });

    // make the 1st tab active
    showFirstTab();
  }, []);

  const showFirstTab = () => {

  };

  /**
   * Broadcasts an update to the greenroom
   */
  const broadcastUpdate = () => {
    socket.emit("reloadnow", { type: "event", id: eventData.event._id });
    console.log("notify sent to greenroom");
  };

  /**
   * Reloads the user
   */
  const reloadUser = () => {
    $.ajax({
      url: "/company_memberships.json",
      dataType: "json",
      success: function (data) {
        setUser(data);
        console.log("successful cm load.");
      },
      error: function (xhr, status, err) {
        console.log("Company Membership load error");
      },
    });
  };

  /**
   * Reloads the event
   */
  const reloadEvent = () => {
    $.ajax({
      url: "/events/" + event_id + ".json",
      dataType: "json",
      success: function (data) {
        setEventData(data);

        // eventData cannot be used yet as the state hasn't been updated. Use data
        // instead in these calls.

        // can we move this to a hook instead?
        // activateNoteEditor();

        // Set event message
        if (data.event.motd == "") {
          if (
            checkCompanyAccess(
              user,
              data.event.company_id,
              ACCESS_STAGEMGR
            )
          ) {
            setMotd("Add a note.");
          } else {
            setMotd("No Notes.");
          }
        } else {
          setMotd(data.event.motd);
        }

        console.log("successful event load.");

        if (subscribed == false) {
          socket.emit("subscribe", {
            type: "event",
            id: data.event._id,
            user_id: USER_ID,
            auth: X_AUTH_TOKEN,
          });
          socket.emit("subscribe", {
            type: "global",
            user_id: USER_ID,
            auth: X_AUTH_TOKEN,
          });

          setSubscribed(true);
        }
      },
      error: function (xhr, status, err) {
        /* we're dead. can't continue */
        // Bugsnag.notify("EventLoadError", "Eventshow show load error for event_id " + event_id + " error: " + err , {}, "error");
        alert(
          "Event " +
            event_id +
            " could not be loaded. Please try reloading the page or check your network connection."
        );
      },
    });

    // why?
    reloadUser();
  };

  const broadcastAndReload = () => {
    // if the reload request came from a child, a change was made
    // because it's from a success() handler. If it comes from an on
    // handler, we'll just reload.
    reloadEvent();
    broadcastUpdate();
  };

  const activateNoteEditor = () => {
    if (checkCompanyAccess(user, eventData.company._id, ACCESS_STAGEMGR)) {
     //$.fn.editable.defaults.mode = "inline";
      $(ReactDOM.findDOMNode(this))
        .find("[data-name='notes']")
        .editable({
          inline: true,
          rows: 10,
          url: function (params) {
            var d = new $.Deferred();
            postdata = {
              authenticity_token: AUTH_TOKEN,
              event_id: eventData.event._id,
              motd: params.value.trim(),
            };

            /* this code updates the event note */
            $.ajax({
              type: "PUT",
              url: "/events/" + eventData.event._id + ".json",
              dataType: "json",
              contentType: "application/json",
              data: JSON.stringify(postdata),
              success: function (response) {
                reloadEvent();
                broadcastUpdate();
                d.resolve();
                return true;
              },
              error: function (xhr, status, err) {
                console.error("update_note", status, err.toString());
                return d.reject("Update failed.");
              },
            });
            return d.promise();
          },
          display: false /* let react manage this. */,
        });
    }
  };

  // Render
  if (eventData == null) {
    return (
      <div className="container">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  /* pushing this aside temporarily */
  var esb = (<EventSubmissionBox eventData={eventData} event_id={event_id} />);


  if (checkCompanyAccess(user, eventData.company._id, ACCESS_STAGEMGR)) {
    var submittedacts = (
      <SubmittedActsBox
        eventData={eventData}
        event_id={event_id}
        reloadCallback={broadcastAndReload}
      />
    );
  }


  if (checkCompanyAccess(user, eventData.company._id, ACCESS_STAGEMGR)) {
    var taskbox = (
      <TaskList
        tasks={eventData.tasks}
        event_id={event_id}
        reloadCallback={broadcastAndReload}
      />
    );
  }

  if (checkCompanyAccess(user, eventData.company._id, ACCESS_PRODUCER)) {
    var submssionBox = (
      <EventSubmissionBox
        eventData={eventData}
        reloadCallback={broadcastAndReload}
      />
    );
  }

  return (
    <div className="container mt-4">
      <div className="row">
        <div className="col-lg-8">
          <EventShow
            eventData={eventData}
            reloadCallback={broadcastAndReload}
            user={user}
            notemodal={noteModalRef}
            socket={socket}
            broadcastUpdate={broadcastUpdate}
          />
        </div>
        <div className="col-lg-4">
          {submssionBox}
          {/*submittedacts*/}
          {/*taskbox*/}
          <div className="card bg-dark text-white">
            <div className="card-header">
              <h3 className="card-title">Notes</h3>
            </div>
            <div className="card-body">
              <div className="col-sm-12">
                <a href="#" className="card-link" id="notes" data-type="textarea" data-name="notes">
                  {motd}
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>

      <EventActPicker data={eventData} reloadCallback={broadcastAndReload} />
      <NoteModal
        data={eventData}
        reloadCallback={broadcastAndReload}
        ref={noteModalRef}
      />
      <SubmissionDeadlineModal
        data={eventData}
        reloadCallback={broadcastAndReload}
        ref={submissionDeadlineModalRef}
      />
    </div>
  );
};

export default EventsApp;
