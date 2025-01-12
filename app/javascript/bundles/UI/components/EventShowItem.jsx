import React, { useEffect } from "react";
import ReactDOM from "react-dom";
import $ from "jquery";
import { checkCompanyAccess, formatDuration, durationToSec } from "./util";
import { ACCESS_STAGEMGR } from "./constants";

/**
 * EventShowItem component
 * @param {Object} props - Component properties
 * @param {Object} props.show_item - Show item details
 * @param {Object} props.user - User details
 * @param {Object} props.event - Event details
 * @param {Object} props.act - Act details
 * @param {Object} props.notemodal - Note modal details
 * @param {Function} props.reloadCallback - Callback to reload data
 * @param {string} props.color - Color class
 * @param {number} props.duration - Duration of the show item
 * @param {string} props.start_time - Start time of the show item
 * @param {Object} props.owner - Owner details
 * @param {Array} props.assets - Assets details
 * @param {number} props.total_items - Total number of items
 * @returns {JSX.Element} EventShowItem component
 */
const EventShowItem = ({
  show_item,
  user,
  event,
  act,
  notemodal,
  reloadCallback,
  color,
  duration,
  start_time,
  owner,
  assets,
  total_items
}) => {
  useEffect(() => {
    $.fn.editable.defaults.mode = 'popup';

    if (checkCompanyAccess(user, event.company._id.$oid, ACCESS_STAGEMGR)) {
      $(ReactDOM.findDOMNode(this)).find('a:first').editable({
        value: '',
        title: "Move this item to which location?",
        url: function (params) {
          const d = new $.Deferred();
          const position_i = parseInt(params.value);
          if (isNaN(position_i) || position_i < 1 || position_i > total_items) {
            return d.reject('Value must be a number');
          } else {
            const postdata = {
              "authenticity_token": AUTH_TOKEN,
              'show_id': show_item.show_id.$oid,
              'new_location': position_i
            };

            $.ajax({
              type: 'POST',
              url: `/show_items/${show_item._id.$oid}/moveexact.json`,
              dataType: 'json',
              contentType: 'application/json',
              data: JSON.stringify(postdata),
              success: function (response) {
                reloadCallback();
                d.resolve();
                return true;
              },
              error: function (xhr, status, err) {
                console.error('moveexact', status, err.toString());
                return d.reject('Update failed.');
              }
            });
            return d.promise();
          }
        },
        display: false
      });

      $(ReactDOM.findDOMNode(this)).find('a').eq(1).editable({
        value: '',
        title: "Change Duration (MM:SS)",
        url: function (params) {
          const d = new $.Deferred();

          if (!duration_re.test(params.value)) {
            return d.reject('Duration must be in the form HH:MM:SS or MM:SS.');
          } else {
            const postdata = {
              "authenticity_token": AUTH_TOKEN,
              'show_id': show_item.show_id.$oid,
              'duration': durationToSec(params.value)
            };

            $.ajax({
              type: 'PUT',
              url: `/show_items/${show_item._id.$oid}.json`,
              dataType: 'json',
              contentType: 'application/json',
              data: JSON.stringify(postdata),
              success: function (response) {
                reloadCallback();
                d.resolve();
                return true;
              },
              error: function (xhr, status, err) {
                console.error('durchange', status, err.toString());
                return d.reject('Update failed.');
              }
            });
            return d.promise();
          }
        },
        display: false
      });
    }

    $("[data-bs-toggle='tooltip']").tooltip({ html: true });
  }, [user, event, show_item, reloadCallback, total_items]);

  useEffect(() => {
    $("[data-bs-toggle='tooltip']").tooltip({ html: true });
  });

  const startNoteEdit = (event) => {
    notemodal.setState({
      id: show_item._id.$oid,
      color: color,
      color_class: color,
      notetext: show_item.note,
      duration: formatDuration(show_item.duration, false),
      duration_secs: show_item.duration,
      type: show_item.type
    });

    notemodal.show(event);
    event.preventDefault();
  };

  const changeColor = (event) => {
    const postdata = {
      'id': show_item._id.$oid,
      'color': color
    };

    $.ajax({
      type: 'POST',
      url: `/show_items/${show_item._id.$oid}/move.json`,
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify(postdata),
      success: function (response) {
        reloadCallback();
      },
      error: function (xhr, status, err) {
        console.error('changecolor', status, err.toString());
      }
    });

    event.preventDefault();
  };

  const duplicateShowItem = (event) => {
    const postdata = {
      'show_id': show_item.show_id.$oid,
      'row_id': show_item.seq,
      'direction': 'duplicate'
    };

    $.ajax({
      type: 'POST',
      url: `/show_items/${show_item._id.$oid}/move.json`,
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify(postdata),
      success: function (response) {
        reloadCallback();
      },
      error: function (xhr, status, err) {
        console.error('duplicate', status, err.toString());
      }
    });

    event.preventDefault();
  };

  const moveShowItemUp = (event) => {
    const postdata = {
      'show_id': show_item.show_id.$oid,
      'row_id': show_item.seq,
      'direction': 'up'
    };

    $.ajax({
      type: 'POST',
      url: `/show_items/${show_item._id.$oid}/move.json`,
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify(postdata),
      success: function (response) {
        reloadCallback();
      },
      error: function (xhr, status, err) {
        console.error('moveup', status, err.toString());
      }
    });

    event.preventDefault();
  };

  const moveShowItemDown = (event) => {
    const postdata = {
      'show_id': show_item.show_id.$oid,
      'row_id': show_item.seq,
      'direction': 'down'
    };

    $.ajax({
      type: 'POST',
      url: `/show_items/${show_item._id.$oid}/move.json`,
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify(postdata),
      success: function (response) {
        reloadCallback();
      },
      error: function (xhr, status, err) {
        console.error('moveup', status, err.toString());
      }
    });

    event.preventDefault();
  };

  const removeShowItem = (event) => {
    const postdata = {
      'show_id': show_item.show_id.$oid,
      'row_id': show_item.seq,
    };

    $.ajax({
      type: 'DELETE',
      url: `/show_items/${show_item._id.$oid}`,
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify(postdata),
      success: function (response) {
        reloadCallback();
      },
      error: function (xhr, status, err) {
        console.error('remove', status, err.toString());
      }
    });

    event.preventDefault();
  };

  const editAct = (event) => {
    event.preventDefault();

    if (act._id !== undefined) {
      const current_href = $('.nav-tabs .active a').attr('href');
      let showid;
      if (current_href !== undefined) {
        const parts = current_href.split("-");
        if (parts.length === 2) {
          showid = parts[1];
        }
      }
      const returnparams = `return_to=${encodeURIComponent(`/events/${event.event._id.$oid}/showpage?active_show=${showid}`)}`;
      location.href = `/acts/${act._id.$oid}/edit?${returnparams}`;
    }
  };

  let title;
  if (act) {
    title = act.title ? `${act.stage_name}: ${act.title}` : act.stage_name;
  } else {
    title = show_item.note;
  }

  let rowclass = "row cueRow";
  if (show_item.kind !== 32 && show_item.color !== undefined) {
    rowclass += ` ${show_item.color}`;
  }

  if (title === undefined) {
    title = "*** DELETED ACT ***";
    rowclass = "row cueRow bg-danger";
  }

  const start_time_s = start_time.replace(/ /g, "");

  let controls = "";
  let titlehtml = <strong>{title}</strong>;

  if (checkCompanyAccess(user, event.company._id.$oid, ACCESS_STAGEMGR)) {
    controls = (
      <div>
        <button type="button" className="btn btn-secondary btn-sm" onClick={duplicateShowItem}>
          <span className="bi bi-files" aria-hidden="true"></span>
        </button>
        <button type="button" className="btn btn-secondary btn-sm" onClick={moveShowItemUp}>
          <span className="bi bi-arrow-up" aria-hidden="true"></span>
        </button>
        <button type="button" className="btn btn-secondary btn-sm" onClick={moveShowItemDown}>
          <span className="bi bi-arrow-down" aria-hidden="true"></span>
        </button>
        <button type="button" className="btn btn-secondary btn-sm" onClick={removeShowItem}>
          <span className="bi bi-x" aria-hidden="true"></span>
        </button>
      </div>
    );

    if (show_item.kind === 32) {
      titlehtml = <strong><a href="#" onClick={editAct}>{title}</a></strong>;
    } else {
      titlehtml = <strong><a href="#" onClick={startNoteEdit}>{title}</a></strong>;
    }
  }

  const durstring = formatDuration(duration);
  let modifiedtime = "";
  let warningicons = "";

  if (show_item.kind === 32 && act) {
    if (act.length !== show_item.duration) {
      modifiedtime = (
        <i className="bi bi-clock" data-bs-toggle="tooltip" data-bs-placement="top" title="This cue duration has been changed to something other than what was submitted by the performer. This change affects this show only."></i>
      );
    }

    if (!assets || assets.length === 0) {
      warningicons = (
        <i className="bi bi-mic-mute" style={{ color: "red" }} data-bs-toggle="tooltip" data-bs-placement="top" title="This cue has no music assigned."></i>
      );
    }
  }

  const ownerlink = owner ? <a href={`/profiles/${owner.username.replace(/ /g, "_")}`}>{owner.name}</a> : "";

  return (
    <div className="schedRow">
      <div className={rowclass}>
        <div className="col-md-1 text-end">
          <a href="#" id={`seq-${show_item._id.$oid}`} data-type="text" data-name="seq" data-title="Move this item to which location?" data-value={show_item.seq}>
            {show_item.seq}
          </a>
        </div>
        <div className="col-5 col-md-2 text-end">
          {start_time_s}
        </div>
        <div className="col-6 col-md-2 text-end">
          <a href="#" id={`dur-${show_item._id.$oid}`} data-type="text" data-name="duration" data-title="Change Duration (HH:MM:SS)" data-value={formatDuration(duration, false)}>
            {warningicons} {modifiedtime} {durstring}
          </a>
        </div>
        <div className="clearfix visible-xs"></div>
        <div className="col-md-4">
          {titlehtml}<br />
          {ownerlink}
        </div>
        <div className="col-lg-3 col-md-12 text-end">
          {controls}
        </div>
      </div>
    </div>
  );
};

export default EventShowItem;
