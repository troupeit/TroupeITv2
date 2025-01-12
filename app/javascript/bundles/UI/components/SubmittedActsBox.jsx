import React, { useState, useEffect } from "react";
import ReactDOM from "react-dom";
import SubmittedActItem from "./SubmittedActItem";
import $ from "jquery";

/**
 * SubmittedActsBox component
 * @param {Object} props - Component properties
 * @param {string} props.event_id - Event ID
 * @param {Object} props.eventData - Event data
 * @param {Function} props.reloadCallback - Callback to reload data
 * @returns {JSX.Element} SubmittedActsBox component
 */
const SubmittedActsBox = ({ event_id, eventData, reloadCallback }) => {
  const [data, setData] = useState(null);
  const [showAllActs, setShowAllActs] = useState(false);

  useEffect(() => {
    reloadSubmittedActs();
  }, [event_id]);

  /**
   * Reload submitted acts
   */
  const reloadSubmittedActs = () => {
    if (!event_id) return;

    $.ajax({
      url: `/events/${event_id}/submissions.json`,
      dataType: "json",
      success: (data) => {
        setData(data);
        console.debug("successful load of eventsubmissions");
      },
      error: (xhr, status, err) => {
        console.error(`eventsubmissions-${event_id}`, status, err.toString());
      },
    });
  };

  /**
   * Reject selected submissions
   * @param {Event} event - Event object
   */
  const rejectSubmissions = (event) => {
    event.preventDefault();
    Object.keys(refs).forEach((ref) => {
      if (refs[ref].state.selected) {
        $.ajax({
          type: "DELETE",
          url: `/event_submissions/${refs[ref].props.id}.json`,
          dataType: "json",
          contentType: "application/json",
          success: () => {
            console.log(`delete ok of ${refs[ref].props.id}`);
            reloadCallback();
            reloadSubmittedActs();
          },
          error: (xhr, status, err) => {
            console.error(`delete failed ${refs[ref].props.id}`, status, err.toString());
          },
        });
      }
    });
  };

  /**
   * Toggle alternate status for selected submissions
   * @param {Event} event - Event object
   */
  const toggleAlternate = (event) => {
    event.preventDefault();
    Object.keys(refs).forEach((ref) => {
      if (refs[ref].state.selected) {
        const postdata = {
          is_alternate: !refs[ref].props.is_alternate,
        };
        $.ajax({
          type: "PUT",
          url: `/event_submissions/${refs[ref].props.id}.json`,
          dataType: "json",
          data: JSON.stringify(postdata),
          contentType: "application/json",
          success: () => {
            console.log(`togglealt ok ${refs[ref].props.id}`);
            reloadSubmittedActs();
          },
          error: (xhr, status, err) => {
            console.error(`togglealt failed ${refs[ref].props.id}`, status, err.toString());
          },
        });
      }
    });
  };

  /**
   * Add selected acts to show
   * @param {Event} event - Event object
   */
  const addToShow = (event) => {
    event.preventDefault();
    const currentHref = $(".nav-tabs .active a").attr("href");
    const parts = currentHref.split("-");
    if (parts.length === 2) {
      const showid = parts[1];
      Object.keys(refs).forEach((ref) => {
        if (refs[ref].state.selected) {
          const postdata = {
            show_id: showid,
            kind: 32,
            act_id: refs[ref].props.act.act._id.$oid,
          };
          $(ReactDOM.findDOMNode(refs[ref])).find(".sacheckbox")[0].checked = false;
          refs[ref].setState({ selected: false });
          $.ajax({
            type: "POST",
            url: "/show_items.json",
            dataType: "json",
            contentType: "application/json",
            data: JSON.stringify(postdata),
            success: () => {
              console.log("add ok.");
              reloadCallback();
            },
            error: (xhr, status, err) => {
              console.error("addtoShow", status, err.toString());
            },
          });
        }
      });
    } else {
      console.log("cannot determine show id for addToShow");
    }
  };

  /**
   * Handle search toggle
   * @param {Event} event - Event object
   */
  const handleSearchToggle = (event) => {
    event.preventDefault();
    setShowAllActs(!showAllActs);
    reloadSubmittedActs();
  };

  /**
   * Check if act is in event
   * @param {string} act_id - Act ID
   * @returns {boolean} True if act is in event, otherwise false
   */
  const inEvent = (act_id) => {
    if (act_id === "0") return false;
    if (showAllActs) return false;
    for (const show of eventData.shows) {
      for (const item of show.show_items) {
        if (item.act && act_id === item.act._id.$oid) {
          return true;
        }
      }
    }
    return false;
  };

  /**
   * Select none of the acts
   * @param {Event} event - Event object
   */
  const selectNone = (event) => {
    event.preventDefault();
    Object.keys(refs).forEach((ref) => {
      refs[ref].setState({ selected: false });
      $(ReactDOM.findDOMNode(refs[ref])).find(".sacheckbox")[0].checked = false;
    });
  };

  /**
   * Select all of the acts
   * @param {Event} event - Event object
   */
  const selectAll = (event) => {
    event.preventDefault();
    Object.keys(refs).forEach((ref) => {
      refs[ref].setState({ selected: true });
      $(ReactDOM.findDOMNode(refs[ref])).find(".sacheckbox")[0].checked = true;
    });
  };

  let listitems;
  const searchbtn = showAllActs ? "Unscheduled Acts" : "All Acts";

  if (!data || data.length === 0) {
    listitems = (
      <li className="media media-item-act">
        No submissions for this event.
      </li>
    );
  } else {
    const currentHref = $(".nav-tabs .active a").attr("href");
    let showid;
    if (currentHref) {
      const parts = currentHref.split("-");
      if (parts.length === 2) {
        showid = parts[1];
      }
    }
    const returnparams = `return_to=${encodeURIComponent(`/events/${event_id}/showpage?active_show=${showid}`)}`;
    listitems = data.map((a) => {
      if (!inEvent(a.act._id.$oid)) {
        return (
          <SubmittedActItem
            key={a._id.$oid}
            act={a}
            ref={a._id.$oid}
            id={a._id.$oid}
            is_alternate={a.is_alternate}
            return_to={returnparams}
          />
        );
      }
      return null;
    });
  }

  const footer = data && data.length > 0 && (
    <div className="card-footer">
      <a className="btn btn-danger btn-sm" href="#" role="button" onClick={rejectSubmissions}>
        Reject Selected
      </a>
      &nbsp;
      <a className="btn btn-warning btn-sm" href="#" role="button" onClick={toggleAlternate}>
        Toggle Alternate
      </a>
      &nbsp;
      <a className="btn btn-success btn-sm float-end" href="#" role="button" onClick={addToShow}>
        Add to show
      </a>
    </div>
  );

  return (
    <div key={event_id} className="submittedActs">
      <div className="card bg-dark text-white">
        <div className="card-header">
          <div className="btn-group float-end">
            <a href="#" onClick={selectAll}>
              <button type="button" className="btn btn-info btn-sm">
                <i className="fa fa-check"></i>&nbsp;All
              </button>
            </a>
            &nbsp;
            <a href="#" onClick={selectNone}>
              <button type="button" className="btn btn-info btn-sm">
                <i className="fa fa-check"></i>&nbsp;None
              </button>
            </a>
            &nbsp;
            <a href="#" onClick={handleSearchToggle}>
              <button type="button" className="btn btn-info btn-sm">
                {searchbtn}
              </button>
            </a>
          </div>
          <h3 className="card-title">Submitted Acts</h3>
        </div>
        <div className="card-body overflow-auto" style={{ maxHeight: "400px" }}>
          <ul className="list-group list-group-flush">
            {listitems}
          </ul>
        </div>
        {footer}
      </div>
    </div>
  );
};

export default SubmittedActsBox;
