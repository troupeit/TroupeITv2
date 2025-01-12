import React, { useState } from 'react';
import moment from 'moment';
import 'moment-timezone';

import { checkCompanyAccess } from './util';
import { ACCESS_PRODUCER } from './constants';

import ShowList from './ShowList';

const EventItem  = (props) => {
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
    user,
    separator
  } = props;

  const [ editing, setEditing ] = useState(false);

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
    var eventEditBtns="";
      
    if (checkCompanyAccess(companies, company._id, ACCESS_PRODUCER ) == true) { 
      eventEditBtns = (<div className="eventControls">
                            <button type="button"
                                    onClick={handleEdit}
                                    className="btn btn-sm btn-success fas fa-pencil"
                                    data-toggle="tooltip"
                                    data-placement="left"
                                    title="Edit Event Details">
                            </button> 
                            <button type="button"
                                    onClick={confirmDelete}
                                    className="btn btn-sm btn-danger fas fa-trash"
                                    data-toggle="tooltip"
                                    data-placement="left"
                                    title="Delete this Event">
                            </button> 
                          </div> );
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
      <>
      <div className="row flex-fill">
        <div className="col flex-column">
          <div className="flex-fill">
          <h5>
              {company.name}
            </h5>
            <h3 className="mb-2">
              <a href={editurl}>{title}</a>
            </h3>
            {dateRange} {startdate.tz(time_zone).format('z')}
            {submission_html}

            <ShowList event_id={id} time_zone={time_zone} {...props} />
          </div>
        </div>
  
        <div className="col-auto d-flex flex-column align-items-end">
          <div className="d-flex align-items-center">
          {eventEditBtns}
          </div>
        </div>
      </div>
  
      {separator && (<hr className="bg-gray-500" />)}
    </>
    );
  } else {
    var content = (
      <div className="eventEdit">
        <h4>Edit "{title}"
            <div className="float-end">
              <a href="#" onClick={endEditing} className="btn btn-danger btn-sm"><i className="far fa-times"></i>&nbsp;Cancel</a>
            </div>
        </h4>
        <EventForm 
          start_date={startdate} 
          end_date={enddate} 
          title={title} 
          defaultCompany={company._id} 
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

export default EventItem;
