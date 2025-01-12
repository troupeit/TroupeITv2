import React, { useState } from 'react';
import { ACCESS_PRODUCER } from './constants';
import { checkCompanyAccess } from "./util";
import moment from 'moment-timezone';
import { FormLabel, FormGroup, FormControl  } from 'react-bootstrap';

const EventForm = (props) => {
  const [title, setTitle] = useState(props.title);
  const [company, setCompany] = useState(null);
  const [companies, setCompanies] = useState(props.companies);
  const [timeZone, setTimeZone] = useState(props.time_zone || Intl.DateTimeFormat().resolvedOptions().timeZone);
  const [id, setId] = useState(props.id);
  const [url, setUrl] = useState('/events.json');
  const [startDate, setStartDate] = useState(props.start_date);
  const [endDate, setEndDate] = useState(props.end_date);

  const validateTitle =  () => {
    if (title == null) return null;
    
    var length = title.length;
    if (length > 0) return 'success';
    else return 'error';
  };
  
  useState(() => {
    // Setup
    // Depending on what was selected on the Dashboard, either were going to 
    // find the 1st company to use or we'll use the default company.
    if (props.defaultCompany && props.defaultCompany != 'all') {
      setCompany(props.defaultCompany);
    } else {
      /* find the first company with access. */
      var defaultIndex=0;
      for (var i = 0, len = companies.length; i < len; i++) {
        if (companies[i].access_level >= ACCESS_PRODUCER)
          defaultIndex = i; 
      }
         setCompany(props.companies[defaultIndex].company_id.$oid);
    }
  }, []);

  const handleUpdate = (event) => {
    if (validateTitle() != 'success') {
      setTitle('');
      return;
    }
    
    var data = {
      'event': {
        'title': title.trim(),
        'time_zone': timeZone,
        'startdate': startDate,
        'enddate': endDate,
        'company': company
      }
    };
    
    var ajaxType = "POST";
    var ajaxURL = url;
    
    if (id != undefined) {
      ajaxType = "PUT";
      ajaxURL = "/events/" + id + ".json";
    }
    
    $.ajax({
      type: ajaxType,
      url: ajaxURL,
      dataType: 'json',
      contentType: 'application/json',
      data: JSON.stringify(data),
            success: function (response) {
             props.onCreate();
            },
      error: function (xhr, status, err) {
        console.error(ajaxURL, status, err.toString());
      }
    });
    
    event.preventDefault();
  };
  
  const handleTitleChange = (event) => {
    setTitle(event.target.value);
  };
  
  const handleCompanyChange = (event) => {
    setCompany(event.target.value);
  };

  const handleTZChange = (event) =>{
    setTimeZone(event.target.value);
  };
  
  const handleDateChange = (dtresp) =>  {
    setStartDate(dtresp.from);
    setEndDate(dtresp.to);
  };
  

  // render 
  var companyNodes = companies.map(function (company) {
    if (checkCompanyAccess(props.user, company.company_id.$oid, ACCESS_PRODUCER)) {   
      return (
          <option key={company.company_id.$oid} value={company.company_id.$oid}>{company.company.name}</option>
      );
    }
  });

  var tzNodes = moment.tz.names().map(function(tz) { 
    return (
        <option key={tz} value={tz}>{tz}</option>
      );
  });
    
  return ( <div className="EventForm">
              <div className="panel-body">
                <div className="row">
                  <div className="col-md-8">
                    <FormGroup controlId="titleInput" validationState={validateTitle()}>
                      <FormLabel>Event Title</FormLabel>
                      <FormControl
                         type="text"
                         value={title}
                         onChange={handleTitleChange}
                         wrapperClass="titleinput"
                         placeholder="Title"
                         className="input-lg titleinput"
                      />
                      <FormControl.Feedback />
                        Don't include your company name. We'll add it for you.
                    </FormGroup>
                  </div>
                </div>
                <div className="clearfix visible-xs-block"></div>
                <div className="row">
                <div className="col-md-6">
                    <label className="form-label">Company</label>
                    <select className="form-control" name="form-companysel" id="form-companysel" onChange={handleCompanyChange} value={company}>
                    {companyNodes}
                    </select>
                </div>
                <div className="col-md-6">
                    <label className="form-label">Time Zone</label>
                    <select className="form-control" name="form-timezonesel" id="form-timezonesel" onChange={handleTZChange} value={timeZone}>
                    </select>
                </div>
                 </div>
                 <div className="row">
                 <div className="col-md-12">
                 <p></p>
                    <button className="btn btn-primary"  key="save_btn" onClick={handleUpdate}>Save</button>
                 </div>
                 </div>
            </div>
        </div>
  );
};

export default EventForm;
