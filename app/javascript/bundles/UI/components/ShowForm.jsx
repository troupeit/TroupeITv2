import React, { useState } from 'react';
import moment from 'moment';
import 'moment-timezone';

const ShowForm = (props) => { 
  const [ id, setId ] = useState(props.id);
  const [ title, setTitle ] = useState(props.title);
  const [ venue, setVenue ] = useState(props.venue);
  const [ room, setRoom ] = useState(props.room);
  const [ goog_place_id, setGoogPlaceId ] = useState(props.goog_place_id);
  const [ door_time, setDoorTime ] = useState(moment(props.door_time));
  const [ show_time, setShowTime ] = useState(moment(props.show_time));
  const [ event_id, setEventId ] = useState(props.event_id);
  const [ onCreate, setOnCreate ] = useState(props.onCreate);
  const [ inError, setInError ] = useState(false);
  const [ errorMsg, setErrorMsg ] = useState("");

  const validateTitle = () => {
    if (title == null && inError == true) return 'error';
    if (title == null) return null;

    if (title.length > 0) return 'success';
    else return 'error';
  };

  const validateVenue = () => {
    if (venue == null && inError == true) return 'error';
    if (venue == null) return null;

    const length = venue.length;
    if (length > 0) return 'success';
    else return 'error';
  };
  
  const validateShowTime = () => {
    if (show_time == null && inError == true) return 'error';
    if (show_time == null) return null;

    if (show_time.isValid())
      return 'success';
    else
      return 'error';
   };

  const validateDoorTime = () => {
    if (door_time == null && inError == true) return 'error';
    if (door_time == null) return null;

    if (door_time.isValid())
      return 'success';
    else
      return 'error';
  }

  const handleUpdate = (e) => {
    if ( (!door_time) || (!show_time) || (!venue) ) {
      setInError(true);
      setErrorMsg("Error! All fields are required.");
      return;
    };

    var title = title.trim();
    var venue = venue.trim();

    if ( (title == "") || (venue == "") ) { 
      setInError(true);
      setErrorMsg("Error! Title and venue can't be blank.");
      e.preventDefault();
      return;
    }
    
    var data = {
      'show' : {
        'title' : title,
        'show_time': show_time,
        'door_time': door_time,
        'event_id': event_id,
        'venue' : venue,
        'room' : room,
        'goog_place_id' : goog_place_id
      }
    };
    
    var ajaxType = "POST";
    var ajaxURL = "/shows.json";
    
    if (id != undefined) { 
      ajaxType = "PUT";
      ajaxURL = "/shows/" + id + ".json";
    };
    
    $.ajax({ 
      type: ajaxType,
      url: ajaxURL,
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify(data),
      success: function(response) { 
        $onCreate();
      },
      error: function(xhr, status, err) {
        console.error(ajaxURL, status, err.toString());
      }
    });

    e.preventDefault();
  };

  const handleTitleChange = (e) =>  function(event) { 
    setTitle(event.target.value);
  };

  const handleVenueChange = (e) => function(event) {
    setVenue(event.target.value);
    setGoogPlaceId('');
  };

  const handleRoomChange = (e) => function(event) {
    setRoom(event.target.value);
  };

  const handleShowTimeChange = (e) => function(event) {
    setShowTime(moment(event.target.value, 'YYYY-MM-DDTHH:mm'));
  };
  
  const handleDoorTimeChange = (e) => function(event) {
    setDoorTime(moment(event.target.value, 'YYYY-MM-DDTHH:mm'));
  };

  // render
  var erroralert = "";
  var formtitle = "Add Show";

  if (id != undefined) {
    formtitle = "Edit Show";
  }

  if (inError == true) {
    erroralert=(<div className="alert alert-danger">{errorMsg}</div>);
  }

  show_time_s = ""
  door_time_s = ""

  if (show_time != undefined) {
    show_time_s = show_time.format('YYYY-MM-DDTHH:mm')
  }

  if (door_time != undefined) { 
    door_time_s = door_time.format('YYYY-MM-DDTHH:mm')
  }

  if (checkCompanyAccess(user, company._id, ACCESS_PRODUCER) && id != undefined) { 
    var delbutton = ( <button className="btn btn-danger" onClick={onCancel}>Delete Show</button> );
  }

  const locationIcon = ( <i className="far fa-map-marker"></i> );

  return ( <div className="ShowForm well"> 
    <div className="panel-body">
      {erroralert}
      <div className="row">
        <h2>{formtitle}</h2>
          <ReactBootstrap.FormGroup controlId="titleInput" validationState={validateTitle()}>
            <ReactBootstrap.ControlLabel>Show Title</ReactBootstrap.ControlLabel>
            <ReactBootstrap.FormControl
                type="text"
                value={title}
                onChange={handleTitleChange}
                wrapperClass="titleinput"
                placeholder="Title"
                className="input-lg titleinput"
                bsStyle={titleError}
                ref="input" />
            <ReactBootstrap.FormControl.Feedback />
            <ReactBootstrap.HelpBlock>Don't include your company name. We'll add it for you.</ReactBootstrap.HelpBlock>
          </ReactBootstrap.FormGroup>
      </div>
      
      <div className="row">

        <div className="col-md-6">
          <div className="form-group">
            <label forHtml="door-time">
              Door Time
            </label>
            <input className="form-control ws-validate"
                  name="door_time"
                  key="door_time"
                  id="door_time"
                  defaultValue={door_time_s}
                  type="datetime-local"
                  ref="doorinput"  required="true"/>
          </div>
        </div>
        
        <div className="col-md-6">
          <div className="form-group">
            <label forHtml="show_time">
              Show Time
            </label>
            <input className="form-control ws-validate"
                  name="show_time"
                  key="show_time"
                  id="show_time"
                  defaultValue={show_time_s}
                  type="datetime-local"
                  ref="showinput" required="true" />
          </div>
        </div>
      </div>

      <div className="row">
        <ReactBootstrap.FormGroup controlId="venueInput" validationState={validateVenue()}>
          <ReactBootstrap.ControlLabel>Venue name / Location</ReactBootstrap.ControlLabel>
          <ReactBootstrap.InputGroup>
            <ReactBootstrap.InputGroup.Addon>{locationIcon}</ReactBootstrap.InputGroup.Addon>
            <ReactBootstrap.FormControl
            type="text"
            value={venue}
            onChange={handleVenueChange}
            wrapperClass="titleinput"
            placeholder="Venue"
            className="input-lg titleinput"
            bsStyle={validateVenue()}
            ref="venueinput" />
          </ReactBootstrap.InputGroup>
          <ReactBootstrap.FormControl.Feedback />
        </ReactBootstrap.FormGroup>
      </div>
      <div className="row">
        <ReactBootstrap.FormGroup controlId="roomInput">
          <ReactBootstrap.ControlLabel>Room (optional)</ReactBootstrap.ControlLabel>
          <ReactBootstrap.FormControl
            type="text"
            value={room}
            onChange={handleRoomChange}
            wrapperClass="titleinput"
            placeholder="Room"
            className="input-lg titleinput"
            ref="roominput" />
        </ReactBootstrap.FormGroup>
      </div>
      
      <div className="row">
        <div className="col-md-2">
          {delbutton}
        </div>
        <div className="col-md-10 float-end">
          <button className="btn btn-danger btn-sm" key="cancel_btn" onClick={onCancel}>Cancel</button>&nbsp;&nbsp;
          <button className="btn btn-primary btn-sm" key="save_btn" onClick={handleUpdate}>Save</button>
        </div>
      </div>
    </div>
  </div>

  );
}

export default ShowForm;