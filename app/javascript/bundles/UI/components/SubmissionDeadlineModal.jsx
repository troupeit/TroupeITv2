import React, { useState, useEffect, useRef } from "react";
import ReactDOM from "react-dom";
import moment from "moment";

/**
 * SubmissionDropdown component
 * @param {Object} props - Component properties
 * @param {number} props.accepting_from - Accepting from value
 * @param {Function} props.changeAccepting - Function to change accepting from value
 * @returns {JSX.Element} SubmissionDropdown component
 */
const SubmissionDropdown = ({ accepting_from, changeAccepting }) => {
  const options = ["No One", "Company", "Public"];
  const current_s = options[accepting_from];

  return (
    <div>
      <button type="button" className="btn btn-secondary dropdown-toggle" id="from_who_dropdown" data-bs-toggle="dropdown" aria-expanded="true">
        {current_s}&nbsp;
        <span className="caret"></span>
      </button>
      <ul className="dropdown-menu" role="menu">
        {options.map((opt, index) => (
          <li role="presentation" key={index}>
            <a role="menuitem" href="#" onClick={changeAccepting} value={index}>{opt}</a>
          </li>
        ))}
      </ul>
    </div>
  );
};

/**
 * SubmissionDeadlineModal component
 * @param {Object} props - Component properties
 * @param {Object} props.data - Event data
 * @param {Function} props.reloadCallback - Callback to reload data
 * @returns {JSX.Element} SubmissionDeadlineModal component
 */
const SubmissionDeadlineModal = (props) => {
  const { data, reloadCallback } = props;

  const [state, setState] = useState({
    id: null,
    accepting_from: 1,
    deadline: data.event.submission_deadline ? moment.tz(data.event.submission_deadline, data.event.time_zone) : moment.tz(data.event.startdate, data.event.time_zone),
    alert: ""
  });

  const changeAccepting = (event) => {
    setState({ ...state, accepting_from: $(event.target).attr('value') });
    event.preventDefault();
  };

  const handleDeadlineChange = (event) => {
    setState({
      ...state,
      deadline: moment.tz(event.target.value, data.event.time_zone)
    });
    $('div#sdStatusText').fadeOut("slow");
  };

  const handleUpdate = (event) => {
    event.preventDefault();
    const end_t = moment(data.event.startdate);

    if (parseInt(state.accepting_from) !== 0 && (state.deadline.isAfter(end_t) || state.deadline.isSame(end_t))) {
      $('div#sdStatusText').show();
      setState({ ...state, alert: `The deadline ${state.deadline.format('L LT')} is after the event begins, ${end_t.format('L LT')}` });
      return;
    }

    const postData = {
      "authenticity_token": AUTH_TOKEN,
      'event': {
        accepting_from: state.accepting_from,
        submission_deadline: state.deadline.format()
      }
    };

    $.ajax({
      type: "PUT",
      url: `/events/${state.id}.json`,
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify(postData),
      success: () => {
        reloadCallback();
        hide();
      },
      error: (xhr, status, err) => {
        console.error(`/events/${state.id}.json`, status, err.toString());
      }
    });
  };

  const show = (event) => {
    $(ReactDOM.findDOMNode(this)).modal('show');
    if (event) event.preventDefault();
  };

  const hide = (event) => {
    $(ReactDOM.findDOMNode(this)).modal('hide');
    if (event) event.preventDefault();
  };

  const deadlineinputRef = useRef();

  const alert = state.alert ? (
    <div className="alert alert-danger">
      {state.alert}
    </div>
  ) : null;

  const date_visible = parseInt(state.accepting_from) === 0 ? { display: "none" } : { display: "block" };
  const deadline_s = state.deadline ? state.deadline.format('YYYY-MM-DDTHH:mm') : "";

  return (
    <div className="modal fade" id="submissioner" tabIndex="-1" role="dialog" aria-labelledby="submissionerLabel" aria-hidden="true">
      <div className="modal-dialog">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" className="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            <h4 className="modal-title" id="submissionerLabel">Manage Submissions</h4>
          </div>
          <div className="modal-body">
            <form className="form-horizontal">
              <div id="sdStatusText">
                {alert}
              </div>
              <div className="row">
                <div className="form-group">
                  <label htmlFor="subGroup" className="col-sm-4 control-label">Allow submissions from</label>
                  <div className="col-sm-8">
                    <div className="dropdown">
                      <SubmissionDropdown accepting_from={state.accepting_from} changeAccepting={changeAccepting} />
                    </div>
                  </div>
                </div>
              </div>
              <div className="row" style={date_visible}>
                <div className="form-group">
                  <label htmlFor="deadline" className="col-sm-4 control-label">Submission Deadline</label>
                  <div className="col-sm-8">
                    <input
                      className="form-control"
                      name="deadline"
                      id="deadline"
                      defaultValue={deadline_s}
                      onChange={handleDeadlineChange}
                      type="datetime-local"
                      ref={deadlineinputRef}
                    />
                  </div>
                </div>
              </div>
            </form>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-primary" onClick={handleUpdate}>Update</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SubmissionDeadlineModal;
