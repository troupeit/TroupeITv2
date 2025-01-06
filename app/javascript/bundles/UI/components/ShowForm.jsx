var ShowForm = React.createClass({
  getInitialState: function() {
    return {
      id: null,
      title: this.props.title,
      venue: this.props.venue,
      room: this.props.room,
      goog_place_id: this.props.goog_place_id,
      door_time: moment(this.props.door_time),
      show_time: moment(this.props.show_time),
      event_id: this.props.event_id,
      onCreate: this.props.onCreate,
      inerror: false,
      errormsg: ""
    };
  },
  validateTitle: function() {
    if (this.state.title == null && this.state.inerror == true) return 'error';
    if (this.state.title == null) return null;
    
    var length = this.state.title.length;
    if (length > 0) return 'success';
    else return 'error';
  },
  validateVenue: function() {
    if (this.state.venue == null && this.state.inerror == true) return 'error';
    if (this.state.venue == null) return null;
    
    var length = this.state.venue.length;
    if (length > 0) return 'success';
    else return 'error';
  },
  validateShowTime: function() {
    if (this.state.show_time == null && this.state.inerror == true) return 'error';
    if (this.state.show_time == null) return null;

    if (this.state.show_time.isValid())
      return 'success';
    else
      return 'error';
   },
   validateDoorTime: function() {
     if (this.state.door_time == null && this.state.inerror == true) return 'error';
     if (this.state.door_time == null) return null;
     
     if (this.state.door_time.isValid())
       return 'success';
     else
       return 'error';
   },
  componentDidMount: function() {
    var $this = this;
    this.setState({
      id: this.props.id,
      title: this.props.title,
      event_id: this.props.event_id,
      onCreate: this.props.onCreate,
    });

    /* do we have support for datetime-local? */
    if ($("#door_time")[0].type == "text") {
      console.log("no datetime-local. dealing with it.");;
      var $fp_door_time = $( "#door_time" );

      $fp_door_time.filthypillow( {
        initialDateTime: function( m ) {
          if ($this.state.door_time) {
            $($this.refs.doorinput).val($this.state.door_time.format("LLL"));
            return $this.state.door_time;
          }
        }
      });
    
      /* build in date support */
      $fp_door_time.on( "focus", function( ) {
        $fp_door_time.filthypillow( "show" );
      } );
      
      $fp_door_time.on( "fp:save", function( e, dateObj ) {
        $fp_door_time.val( dateObj.format( "LLL" ) );
        $this.setState({door_time: dateObj});
        $fp_door_time.filthypillow( "hide" );
      } );
      
      
      var $fp_show_time = $( "#show_time" );
      $fp_show_time.filthypillow( {
        initialDateTime: function( m ) {
          if ($this.state.show_time) {
            $($this.refs.showinput).val($this.state.door_time.format("LLL"));
            return $this.state.show_time;
          }
        }
      });

      $fp_show_time.on( "focus", function( ) {
        $fp_show_time.filthypillow( "show" );
    } );
      
      $fp_show_time.on( "fp:save", function( e, dateObj ) {
        $fp_show_time.val( dateObj.format( "LLL" ) );
        $this.setState({show_time: dateObj});
        $fp_show_time.filthypillow( "hide" );
      } );
    }
    
    // we have to trap these here, because simple events do not bubble in webshim
    if (navigator.userAgent.match(/(iPad|iPhone|iPod)/g)) { 
      $(ReactDOM.findDOMNode(this.refs.doorinput)).on('blur', this.handleDoorTimeChange);
      $(ReactDOM.findDOMNode(this.refs.showinput)).on('blur', this.handleShowTimeChange);
    } else { 
      $(ReactDOM.findDOMNode(this.refs.doorinput)).on('change', this.handleDoorTimeChange);
      $(ReactDOM.findDOMNode(this.refs.showinput)).on('change', this.handleShowTimeChange);
    }

    /* setup maps */
    var input = ReactDOM.findDOMNode(this.refs.venueinput);
    var autocomplete = new google.maps.places.Autocomplete(input);
    var infowindow = new google.maps.InfoWindow();
    var $this = this;
    
    autocomplete.addListener('place_changed', function() {
      infowindow.close();
      var place = autocomplete.getPlace();
      if (!place.geometry) {
        return;
      }

      $this.setState({venue: place.name + ", " + place.formatted_address});
      $this.setState({goog_place_id: place.id});
    });

    
  },
  handleUpdate: function(event) { 
    var $this = this;

    if ( (!this.state.door_time) || (!this.state.show_time) || (!this.state.venue) ) {
      this.setState({inerror: true});
      this.setState({errormsg: "Error! All fields are required."});
      event.preventDefault();
      return;
    };

    var title = this.state.title.trim();
    var venue = this.state.venue.trim();

    if ( (title == "") || (venue == "") ) { 
      this.setState({inerror: true});
      this.setState({errormsg: "Error! Title and venue can't be blank."});
      event.preventDefault();
      return;
    }

    var room = "";
    
    if (typeof this.state.room !== "undefined") {
      room = this.state.room;
    }
    
    var data = {
      'show' : {
        'title' : title,
        'show_time': this.state.show_time,
        'door_time': this.state.door_time,
        'event_id': this.props.event_id,
        'venue' : venue,
        'room' : room,
        'goog_place_id' : this.state.goog_place_id
      }
    };
    
    var ajaxType = "POST";
    var ajaxURL = "/shows.json";
    
    if (this.state.id != undefined) { 
      ajaxType = "PUT";
      ajaxURL = "/shows/" + this.state.id + ".json";
    };
    
    $.ajax({ 
      type: ajaxType,
      url: ajaxURL,
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify(data),
      success: function(response) { 
        $this.state.onCreate();
      },
      error: function(xhr, status, err) {
        console.error(ajaxURL, status, err.toString());
      }
    });

    event.preventDefault();
  },
  handleTitleChange: function(event) { 
    this.setState({
      title: event.target.value      
    });
  },
  handleVenueChange: function(event) {
    // if the venue changes the placeID is no good.
    this.setState({
      venue: event.target.value,
      goog_place_id: ''
    });
  },
  handleRoomChange: function(event) { 
    this.setState({
      room: event.target.value
    });
  },
  handleShowTimeChange: function(event) {
    this.setState({
      show_time: moment(event.target.value, 'YYYY-MM-DDTHH:mm')
    });
  },
  handleDoorTimeChange: function(event) {
    this.setState({
      door_time: moment(event.target.value, 'YYYY-MM-DDTHH:mm')
    });

  },
  render: function() {

    var erroralert = "";
    var formtitle = "Add Show";
    
    if (this.state.id != undefined) {
      formtitle = "Edit Show";
    }
    
    if (this.state.inerror == true) {
      erroralert=(<div className="alert alert-danger">{this.state.errormsg}</div>);
    }

    show_time_s = ""
    door_time_s = ""

    if (this.state.show_time != undefined) {
      show_time_s = this.state.show_time.format('YYYY-MM-DDTHH:mm')
    }

    if (this.state.door_time != undefined) { 
      door_time_s = this.state.door_time.format('YYYY-MM-DDTHH:mm')
    }

    if (checkCompanyAccess(this.props.user, this.props.company._id.$oid, ACCESS_PRODUCER) && this.state.id != undefined) { 
      var delbutton = ( <button className="btn btn-danger" onClick={this.props.onCancel}>Delete Show</button> );
    }

    const locationIcon = ( <i className="fa fa-map-marker"></i> );
    
return ( <div className="ShowForm well"> 
  <div className="panel-body">
    {erroralert}
    <div className="row">
      <h2>{formtitle}</h2>
         <ReactBootstrap.FormGroup controlId="titleInput" validationState={this.validateTitle()}>
           <ReactBootstrap.ControlLabel>Show Title</ReactBootstrap.ControlLabel>
           <ReactBootstrap.FormControl
              type="text"
              ref="input"
              value={this.state.title}
              onChange={this.handleTitleChange}
              wrapperClass="titleinput"
              placeholder="Title"
              className="input-lg titleinput"
              bsStyle={this.state.titleError}
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
      <ReactBootstrap.FormGroup controlId="venueInput" validationState={this.validateVenue()}>
        <ReactBootstrap.ControlLabel>Venue name / Location</ReactBootstrap.ControlLabel>
        <ReactBootstrap.InputGroup>
          <ReactBootstrap.InputGroup.Addon>{locationIcon}</ReactBootstrap.InputGroup.Addon>
          <ReactBootstrap.FormControl
           type="text"
           ref="input"
           value={this.state.venue}
           onChange={this.handleVenueChange}
           wrapperClass="titleinput"
           placeholder="Venue"
           className="input-lg titleinput"
           bsStyle={this.validateVenue()}
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
           ref="roominput"
           value={this.state.room}
           onChange={this.handleRoomChange}
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
      <div className="col-md-10 pull-right">
        <button className="btn btn-danger btn-sm" key="cancel_btn" onClick={this.props.onCancel}>Cancel</button>&nbsp;&nbsp;
        <button className="btn btn-primary btn-sm" key="save_btn" onClick={this.handleUpdate}>Save</button>
      </div>
    </div>
  </div>
</div>

  );
}
});
