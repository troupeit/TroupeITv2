var Show = React.createClass({
  componentDidMount: function () {
      $("[data-toggle='tooltip']").tooltip({html: true});
  },
  componentDidUpdate: function () {
      $("[data-toggle='tooltip']").tooltip({html: true});
  },
  getInitialState: function() {
    return { editing: false };
  },
  toggleEdit: function(event) {
    this.setState({editing: !this.state.editing});
    event.preventDefault();
  },
  postUpdate: function() {
    this.setState({editing: false});
    this.props.reloadCallback();
  },
  startDelete: function(event) {
    event.preventDefault();
    $('#okBtn').onClick(this.handleDelete);
    $('#confirmModalTitle').html('Delete Show: ' + this.props.title);
    $('#confirmModal').modal('show');
  },
  handleDelete: function(event) {
     $('#confirmModal').modal('hide');
     var $this = this;
     $.ajax({ 
          type: 'DELETE',
          url: "/shows/" + this.props.id + ".json",
          dataType: 'json',
          contentType: 'application/json',
          success: function(response) { 
           $this.props.reloadCallback();
          },
          error: function(xhr, status, err) {
            console.error("Delete failed.", status, err.toString());
          }
     });
     event.preventDefault();
  },
 render: function(event) {
   ddate = moment(this.props.door_time);
   door_date_s = ddate.tz(this.props.time_zone).format('dddd, MMMM Do YYYY, h:mm A z');

   var content;

   if (checkCompanyAccess(this.props.user, this.props.company._id.$oid, ACCESS_STAGEMGR)) { 
     var editdelbtns = ( <div>
                           <button onClick={this.toggleEdit}
                                   className="btn btn-sm btn-warning glyphicon glyphicon-pencil"
                                   data-toggle="tooltip"
                                   data-placement="left"
                                   title="Edit Show Details">
                           </button>
                           &nbsp;
                           <button onClick={this.startDelete}
                                   className="btn btn-sm btn-danger glyphicon glyphicon-trash"
                                   data-toggle="tooltip"
                                   data-placement="left"
                                   title="Delete this Show">
                           </button>
                         </div> )
   }
   
   if (this.state.editing == true) {
     content = (<ShowForm id={this.props.id}
                          title={this.props.title} 
                          venue={this.props.venue}
                          room={this.props.room}
                          goog_place_id={this.props.goog_place_id}
                          show_time={this.props.show_time}
                          door_time={this.props.door_time}
                          onCancel={this.toggleEdit}
                          onCreate={this.postUpdate}
                          user={this.props.user}
                          company={this.props.company}
                 />);
   } else {
     var room;

     if (this.props.room !== null ) {
       if (this.props.room != "") { 
         room = ( <span><br/>Room: {this.props.room}</span> );
       }
     }

     maplink="https://www.google.com/maps?q=" + this.props.venue;        
     content = (
         <div className="show">
           <h4 className="showTitle">{this.props.title}</h4>
           <div className="showControls">
             {editdelbtns}
           </div>
           <strong>Doors:</strong> {door_date_s}<br/>
         <a href={maplink} target="_map">
         <i className='glyphicon glyphicon-map-marker'></i>
         </a>&nbsp;
          {this.props.venue}{room}
         </div>);
   }
      return content;
 }
});

 
