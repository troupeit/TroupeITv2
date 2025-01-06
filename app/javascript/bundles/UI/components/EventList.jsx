import React from 'react';
import moment from 'moment';
import Event from './Event';

import { revArr } from './util';

const EventList = (props) => {
  const { data, company, type, reloadCallback, companies, user } = props;

  if (data == undefined || data.length == 0) {
    return (
      <ul className="media-list media-list-with-divider">
       <li>
        <strong>No Events.</strong>
        </li>
      </ul>
    );
  }
     
  if (type == 'past') {
    var mydata = revArr(data);
  } else {
    var mydata = data;
  }

  var valid = 0;    
    
  var eventNodes = mydata.map(function (event,index,array) {
    let sdate = moment(event.startdate);
    let edate = moment(event.enddate);
    let now = moment();
    console.log(event);
    
    if ( (company == event.company._id.$oid) || (company == 'all') ) { 
      if ((( (event.shows.length == 0) || now.isBefore(edate)) && (type == 'upcoming' )) ||
          (now.isAfter(edate) && (type == 'past'))) {
        valid = valid + 1;
        return (
            <Event 
              key={event._id.$oid} 
              id={event._id.$oid} 
              title={event.title} 
              startdate={sdate} 
              enddate={edate} 
              company={event.company} 
              reloadCallback={reloadCallback} 
              companies={companies}
              submission_deadline={event.submission_deadline} 
              accepting_from={event.accepting_from} 
              time_zone={event.time_zone} 
              user={user} />
        );
      }
    }
  });

  if (valid == 0) {
    var eventNodes = (
        <li>
          <strong>No Events.</strong>
        </li> );
  }

  return (
    <ul className="media-list media-list-with-divider">
      {eventNodes}
    </ul>
  );
};

export default EventList;