import React, { useState, useEffect } from "react";
import ReactDOM from "react-dom";
import $ from "jquery";
import ActPickerList from "./ActPickerList";

/**
 * EventActPicker component
 * @param {Object} props - Component properties
 * @param {Object} props.data - Event data
 * @param {Function} props.reloadCallback - Callback to reload data
 * @returns {JSX.Element} EventActPicker component
 */
const EventActPicker = ({ data, reloadCallback }) => {
  const [results, setResults] = useState(null);

  useEffect(() => {
    $("#searchinprogress").hide();
    //$("[data-bs-toggle='tooltip']").tooltip({ html: true });
  });

  const reloadResults = () => {
    $("#searchinprogress").show();
    const sortoption = $('select', ReactDOM.findDOMNode(this))[0].value;
    const term = $('input', ReactDOM.findDOMNode(this))[0].value;

    if (term === undefined || (term.length === 0 && sortoption !== "2")) {
      setResults(null);
      return;
    }

    $.ajax({
      url: `/acts/search.json?search=${term}&order=${sortoption}`,
      dataType: 'json',
      success: (data) => {
        $("#searchinprogress").hide();
        setResults(data.length === 0 ? null : data);
        console.log("reloaded");
      },
      error: (xhr, status, err) => {
        $("#searchinprogress").hide();
        console.error(`search failed ${data.event._id.$oid}`, status, err.toString());
      }
    });
  };

  const doSearch = () => {
    console.log('dosearch');
    reloadResults();
  };

  const current_href = $('.nav-tabs .active a').attr('href');
  let showid = "";
  if (current_href !== undefined) {
    const parts = current_href.split("-");
    if (parts.length === 2) {
      showid = parts[1];
    }
  }

  const returnparams = `return_to=${encodeURIComponent(`/events/${data.event._id.$oid}/showpage?active_show=${showid}`)}`;
  const newactlink = `/acts/new?${returnparams}`;

  const searchoptions = ['Stage Name', 'Tag', 'All'].map((m, n) => (
    <option key={n} value={n}>{m}</option>
  ));

  return (
    <div className="modal fade" id="actPicker" tabIndex="-1" aria-labelledby="actPickerLabel" aria-hidden="true">
      <div className="modal-dialog">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" className="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            <h4 className="modal-title" id="actPickerLabel">Select Act to Add</h4>
          </div>
          <div className="modal-body">
            <div className="row">
              <form className="form-horizontal">
                <div className="col-sm-6">
                  <div className="mb-3">
                    <label className="form-label">Find By</label>
                    <select className="form-select" onChange={doSearch}>
                      {searchoptions}
                    </select>
                  </div>
                </div>
                <div className="col-sm-6">
                  <div className="mb-3">
                    <label className="form-label">Search</label>
                    <input
                      type="text"
                      className="form-control"
                      placeholder="Search"
                      onChange={doSearch}
                      data-bs-toggle="tooltip"
                      title="Searches across all companies you are a member of."
                    />
                    <div id="searchinprogress"><i className="fa fa-spinner fa-spin fa-2x"></i></div>
                  </div>
                </div>
              </form>
            </div>
          </div>
          <ActPickerList results={results} reloadCallback={reloadCallback} />
          <div className="modal-footer">
            <a href={newactlink}>
              <button type="button" className="btn btn-info">
                <i className="bi bi-plus"></i> Create New Act
              </button>
            </a>
            <button type="button" className="btn btn-danger" data-bs-dismiss="modal">Cancel</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EventActPicker;
