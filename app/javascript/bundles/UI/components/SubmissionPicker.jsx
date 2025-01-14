import React, { useState, useEffect, useRef } from "react";
import $ from "jquery";
import SubmissionPickerList from "./SubmissionPickerList";

/**
 * SubmissionPicker component
 * @param {Object} props - Component properties
 * @param {Function} props.reloadCallback - Callback to reload data
 * @returns {JSX.Element} SubmissionPicker component
 */
const SubmissionPicker = ({ reloadCallback }) => {
  const [results, setResults] = useState(null);
  const alertRef = useRef(null);

  useEffect(() => {
    $(alertRef.current).hide();
    reloadResults();
  }, []);

  const reloadResults = () => {
    $.ajax({
      url: '/events/accepting_submissions.json',
      dataType: 'json',
      success: (data) => {
        if (data.length === 0) {
          data = null;
        }
        setResults(data);
        console.log("accepting_submissions reloaded");
      },
      error: (xhr, status, err) => {
        console.error("accepting_submissions ajax failed", status, err.toString());
      }
    });
  };

  return (
    <div className="modal fade" id="submissionPicker" tabIndex="-1" aria-labelledby="submissionPickerLabel" aria-hidden="true">
      <div className="modal-dialog">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" className="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            <h4 className="modal-title" id="submissionPickerLabel">Submit to which Event?</h4>
            <p id="submissionPickerDetail"></p>
          </div>
          <input type="hidden" name="forAct" id="forAct" />
          <div className="modal-body">
            <div ref={alertRef} className="alert alert-success" id='statusText'>Added to Event. You can safely close this window.</div>
            <SubmissionPickerList results={results} reloadCallback={reloadCallback} />
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" data-bs-dismiss="modal">Close</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SubmissionPicker;
