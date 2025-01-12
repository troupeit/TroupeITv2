import React from 'react';
import moment from 'moment';
import EventItem from './EventItem';

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
    
    if ( (company == event.company._id) || (company == 'all') ) { 
      if ((( (event.shows.length == 0) || now.isBefore(edate)) && (type == 'upcoming' )) ||
          (now.isAfter(edate) && (type == 'past'))) {
        valid = valid + 1;
        return (
            <EventItem 
              key={event._id} 
              id={event._id} 
              title={event.title} 
              startdate={sdate} 
              enddate={edate} 
              company={event.company} 
              reloadCallback={reloadCallback} 
              companies={companies}
              submission_deadline={event.submission_deadline} 
              accepting_from={event.accepting_from} 
              time_zone={event.time_zone} 
              user={user} 
              separator={mydata.length -1 !== index}/>
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
    <div className="d-flex flex-column" >
    {eventNodes}
    </div>
  );
};

export default EventList;