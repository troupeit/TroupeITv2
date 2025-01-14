import React, { useState } from "react";
import ReactDOM from "react-dom";
import { Form, FormGroup, FormLabel, FormControl, Col } from "react-bootstrap";

import {durationRegexp} from "./util";

/**
 * NoteModal component
 * @param {Object} props - Component properties
 * @param {Function} props.reloadCallback - Callback to reload data
 * @returns {JSX.Element} NoteModal component
 */
const NoteModal = ({ reloadCallback }) => {
  const [state, setState] = useState({
    id: null,
    notetext: "",
    duration: 0,
    duration_secs: 0,
    type: 0,
    color: "White",
    color_class: ""
  });

  /**
   * Show the modal
   * @param {Event} event - Event object
   */
  const show = (event) => {
    $(ReactDOM.findDOMNode(this)).modal('show');
    event.preventDefault();
  };

  /**
   * Hide the modal
   * @param {Event} event - Event object
   */
  const hide = (event) => {
    $(ReactDOM.findDOMNode(this)).modal('hide');
    event.preventDefault();
  };

  /**
   * Validate note text
   * @returns {string|null} Validation state
   */
  const validateNoteText = () => {
    if (state.notetext == null) return null;
    return state.notetext.length > 0 ? 'success' : 'error';
  };

  /**
   * Validate duration
   * @returns {string|null} Validation state
   */
  const validateDuration = () => {
    if (state.duration == null) return null;
    return durationRegexp.test(state.duration) ? 'success' : 'error';
  };

  /**
   * Handle note text change
   * @param {Event} event - Event object
   */
  const handleNoteTextChange = (event) => {
    setState({ ...state, notetext: event.target.value });
  };

  /**
   * Handle duration change
   * @param {Event} event - Event object
   */
  const handleDurationChange = (event) => {
    const value = event.target.value;
    if (durationRegexp.test(value)) {
      setState({ ...state, duration_secs: durationToSec(value), duration: value });
    } else {
      setState({ ...state, duration: value });
    }
  };

  /**
   * Handle update
   * @param {Event} event - Event object
   */
  const handleUpdate = (event) => {
    event.preventDefault();

    if (state.duration == null) {
      setState({ ...state, duration_secs: 0, duration: '00:00' });
    }

    if (!state.notetext) {
      setState({ ...state, notetext: '' });
      return;
    }

    const current_href = $('.nav-tabs .active a').attr('href');
    const parts = current_href.split("-");

    const data = {
      "authenticity_token": AUTH_TOKEN,
      'show_id': parts[1],
      'kind': 0,
      'act_id': 0,
      'note': state.notetext,
      'duration': state.duration_secs,
      'color': state.color_class
    };

    const ajaxType = state.id != undefined ? "PUT" : "POST";
    const ajaxURL = state.id != undefined ? `/show_items/${state.id}.json` : "/show_items.json";

    $.ajax({
      type: ajaxType,
      url: ajaxURL,
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify(data),
      success: function (response) {
        reloadCallback();
        $('.modal#noteModal', document).modal('hide');
        setState({
          id: null,
          notetext: null,
          duration: null,
          duration_secs: 0,
          type: 0,
          color: "White",
          color_class: ""
        });
      },
      error: function (xhr, status, err) {
        console.error(ajaxURL, status, err.toString());
      }
    });
  };

  /**
   * Select color
   * @param {Event} event - Event object
   */
  const selectColor = (event) => {
    setState({ ...state, color_class: event.target.classList[0], color: event.target.text });
  };

  const selectedColor = `btn btn-default dropdown-toggle ${state.color_class}`;
  const formtitle = state.id == null ? "Add Note" : "Update Note";
  const btntitle = state.id == null ? "Add" : "Update";

  return (
    <div className="modal fade" id="noteModal" tabIndex="-1" role="dialog" aria-labelledby="noteLabel" aria-hidden="true">
      <div className="modal-dialog">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" className="close" data-dismiss="modal" aria-label="Close">
              <span aria-hidden="true">&times;</span>
            </button>
            <h4 className="modal-title" id="noteLabel">{formtitle}</h4>
          </div>
          <div className="modal-body">
            <Form>
              <FormGroup controlId="notetext">
                <FormLabel sm={2}>
                  Note Text
                </FormLabel>
                <Col sm={10}>
                  <FormControl
                    type="text"
                    value={state.notetext}
                    onChange={handleNoteTextChange}
                    placeholder="Say Something Here"
                    className="input-lg noteinput"
                  />
                  <FormControl.Feedback />
                </Col>
              </FormGroup>
              <FormGroup controlId="durationInput">
                <FormLabel sm={2}>
                  Duration (mm:ss)
                </FormLabel>
                <Col sm={10}>
                  <FormControl
                    type="text"
                    value={state.duration}
                    onChange={handleDurationChange}
                    placeholder="MM:SS"
                    className="input-lg durationinput"
                  />
                  <FormControl.Feedback />
                </Col>
              </FormGroup>
              <FormGroup controlId="colorInput">
                <Col sm={2}>
                  Color
                </Col>
                <Col sm={10}>
                  <div className="dropdown">
                    <button className={selectedColor} type="button" id="dropdownMenu1" data-toggle="dropdown" aria-expanded="true">
                      {state.color}&nbsp;
                      <span className="caret"></span>
                    </button>
                    <ul className="dropdown-menu" role="menu" aria-labelledby="dropdownMenu1">
                      <li role="presentation">
                        <a role="menuitem" tabIndex="-1" href="#" onClick={selectColor}>White</a>
                      </li>
                      <li role="presentation">
                        <a role="menuitem" tabIndex="-1" href="#" className="red_bg" onClick={selectColor}>Red</a>
                      </li>
                      <li role="presentation">
                        <a role="menuitem" tabIndex="-1" href="#" className="brown_bg" onClick={selectColor}>Brown</a>
                      </li>
                      <li role="presentation">
                        <a role="menuitem" tabIndex="-1" href="#" className="orange_bg" onClick={selectColor}>Orange</a>
                      </li>
                      <li role="presentation">
                        <a role="menuitem" tabIndex="-1" href="#" className="yellow_bg" onClick={selectColor}>Yellow</a>
                      </li>
                      <li role="presentation">
                        <a role="menuitem" tabIndex="-1" href="#" className="green_bg" onClick={selectColor}>Green</a>
                      </li>
                      <li role="presentation">
                        <a role="menuitem" tabIndex="-1" href="#" className="cyan_bg" onClick={selectColor}>Cyan</a>
                      </li>
                      <li role="presentation">
                        <a role="menuitem" tabIndex="-1" href="#" className="purple_bg" onClick={selectColor}>Purple</a>
                      </li>
                    </ul>
                  </div>
                </Col>
              </FormGroup>
            </Form>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-danger btn-sm" data-dismiss="modal"> Cancel </button>
            <button type="button" className="btn btn-primary btn-sm" onClick={handleUpdate}> {btntitle} </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default NoteModal;