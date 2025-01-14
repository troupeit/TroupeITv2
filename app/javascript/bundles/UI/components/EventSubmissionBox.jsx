import React from "react";
import moment from "moment";

/**
 * EventSubmissionBox component
 * @param {Object} props - Component properties
 * @param {Object} props.eventData - Event data
 * @returns {JSX.Element} EventSubmissionBox component
 */
const EventSubmissionBox = ({ eventData }) => {
  if (eventData == null) {
    return (
      <div className="container">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  let submissionDeadline = "";
  let submissionTimeAgo = "";

  if (eventData.event.submission_deadline != null) {
    const subDate = moment(eventData.event.submission_deadline);
    submissionDeadline = subDate.tz(eventData.event.time_zone).format('L LT z');
    submissionTimeAgo = subDate.fromNow();
  } else {
    submissionDeadline = "When first show begins.";
    submissionTimeAgo = "";
  }

  const acceptingOptions = ['No one', 'Company', 'Public'];

  let btnClass = "btn btn-success btn-lg w-100";
  let btnText = "Enable Submissions";
  let acceptDetails = null;

  if (eventData.event.accepting_from > 0) {
    btnClass = "btn btn-danger btn-lg w-100";
    btnText = "Manage Submissions";
    acceptDetails = (
      <div>
        <p>
          <strong>Accepting from:</strong>&nbsp;
          {acceptingOptions[eventData.event.accepting_from]}
        </p>
        <p>
          <strong>Deadline:</strong> {submissionDeadline}&nbsp;<span className="badge bg-secondary">{submissionTimeAgo}</span>
        </p>
      </div>
    );
  }

  return (
    <div className="card">
      <div className="card-body">
        <p>
          <button type="button" className={btnClass} data-bs-toggle="modal" data-bs-target="#submissioner">{btnText}</button>
        </p>
        {acceptDetails}
      </div>
    </div>
  );
};

export default EventSubmissionBox;
