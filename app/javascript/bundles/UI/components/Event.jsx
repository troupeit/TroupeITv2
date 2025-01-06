import React, { useState } from 'react';
import moment from 'moment';
import 'moment-timezone';

import { checkCompanyAccess } from './util';
import { ACCESS_PRODUCER } from './constants';

import ShowList from './ShowList';

const Event = (props) => {
  const {
    id, 
    title, 
    startdate, 
    enddate, 
    company, 
    reloadCallback, 
    companies, 
    submission_deadline, 
    accepting_from, 
    time_zone, 
    user} = props;

  const [ editing, setEditing ] = useState(false);
  /*
  componentDidMount: function () {
      $("[data-toggle='tooltip']").tooltip({html: true});
  },
  componentDidUpdate: function () {
      $("[data-toggle='tooltip']").tooltip({html: true});
  },
  */

  const handleEdit = (event) => {
    setEditing(true);
    event.preventDefault();
  };

  const endEditing = (event) => {
    setEditing(false);
    reloadCallback();

    if (event != undefined) {
      event.preventDefault();
    }
  };

  const handleDelete = (event) => {
    $('#confirmModal').modal('hide');
    
    $.ajax({
      type: 'DELETE',
      url: "/events/" + id + ".json",
      dataType: 'json',
      contentType: 'application/json',
      success: function (response) {
          reloadCallback();
      },
      error: function (xhr, status, err) {
          console.error("Delete failed.", status, err.toString());
      }
    });
    event.preventDefault();
  };

  const confirmDelete = () => {
    $('#okBtn').onClick(handleDelete);
    $('#confirmModalTitle').html('Delete Event: ' + title);
    $('#confirmModal').modal('show');
  };

  // render
  var dateRange;
  var content;
  var options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };

  /* if it's a one day event, show one day */
  if (! startdate.isValid()) { 
    dateRange = "No shows / No start date.";
  } else { 
    if (startdate.format('DD MM YYYY') == enddate.format('DD MM YYYY')) { 
      dateRange = startdate.toDate().toLocaleDateString('en-US', options)
    } else {
      dateRange = startdate.toDate().toLocaleDateString('en-US', options) + " - " + enddate.toDate().toLocaleDateString('en-US', options)
    }
  }
    
  if (!editing) {
    var editurl = "/events/" + id + "/showpage";
    var eventeditbtns="";
      
    if (checkCompanyAccess(user, company._id.$oid, ACCESS_PRODUCER ) == true) { 
      var eventeditbtns = (<div className="eventControls">
                            <button onClick={handleEdit}
                                    className="btn btn-sm btn-success glyphicon glyphicon-pencil"
                                    data-toggle="tooltip"
                                    data-placement="left"
                                    title="Edit Event Details">
                            </button> <button onClick={confirmDelete}
                                              className="btn btn-sm btn-danger glyphicon glyphicon-trash"
                                              data-toggle="tooltip"
                                              data-placement="left"
                                              title="Delete this Event">
                            </button> </div> );
    }
    
    if (accepting_from == 0) {
      var submission_timeago = "Submissions Closed";
      var submission_html  = ( <div className="cueRow"><span className="badge badge-danger">{submission_timeago}</span></div> ) ;
    } else { 
      if (submission_deadline != null) {
        var subdate = moment(submission_deadline);
        if ( subdate.isAfter(moment()) ) {
          submission_deadline_s = subdate.format('MMMM Do YYYY, h:mm a');
          submission_timeago = "Submissions close " + subdate.fromNow()
          var submission_html  = ( <div className="cueRow"><span className="badge badge-danger">{submission_timeago}</span></div> ) ;
        }
      }
    }
    
    var accepting_s = [ 'No one', 'Company', 'Public' ];
      
    var content = (		
      <li className="media">
        <div className="eventTitle">
          {eventeditbtns}
          <h4 className="media-heading">
            <small>{company.name}</small><br/>
            <a href={editurl}>{title}</a>
          </h4>
        </div>
        {dateRange} {startdate.tz(time_zone).format('z')}
        {submission_html}
        <p></p>
          <ShowList event_id={id} time_zone={time_zone} {...props} />
      </li>
    );
  } else {
    var content = (
      <div className="eventEdit">
        <h4>Edit "{title}"
            <div className="pull-right">
              <a href="#" onClick={endEditing} className="btn btn-danger btn-sm"><i className="fa fa-times"></i>&nbsp;Cancel</a>
            </div>
        </h4>
        <EventForm 
          start_date={startdate} 
          end_date={enddate} 
          title={title} 
          defaultCompany={company._id.$oid} 
          onCreate={endEditing} 
          companies={companies} 
          id={id} 
          user={user} 
          time_zone={time_zone}  
        />
      </div>
    );
  }
  return content;
}

export default Event;
