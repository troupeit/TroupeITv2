import React, { useEffect, useState } from "react";
import CompanySelect from "./CompanySelect";
import EventBox from "./EventBox";

const EventsDashboard = (props) => {
  const { companies, user, reloadCallback } = props;

  const [company, setCompany] = useState(props.company);
  const [data, setData] = useState([]);

  const reloadEvents = () => {
    $.ajax({
      url: "/events.json?t=" + props.type + "&company=" + company,
      dataType: "json",
      success: function (data) {
        console.log("Reload of events on eventsdashboard");
        setData(data);
      }.bind(this),
      error: function (xhr, status, err) {
        console.error("eventsload", status, err.toString());
      }.bind(this),
    });
  };

  /* Load events on first load */
  useEffect(() => {
    reloadEvents();
  }, []);

  useEffect(() => {
    setCompany(props.company);
  }, [props.company]);

  const handleCompanyChange = (event) => {
    setCompany(event.target.value);
  };

  /*  if (props.companies.length == 0) { 
      return (<FirstTime user={props.user} reloadCallback={props.reloadCallback}/>);
    };
    */
  if (props.companies == null) {
    return <div></div>;
  }

  return (
    <div>
      <CompanySelect
        companies={props.companies}
        callback={handleCompanyChange}
        value={company}
        showAll={true}
      />
      {
        <div className="panel-group" id="eventacc">
          <EventBox
            type="upcoming"
            company={company}
            companies={props.companies}
            user={props.user}
            data={data}
            reloadCallback={reloadEvents}
          />
          <EventBox
            type="past"
            company={company}
            companies={props.companies}
            user={props.user}
            data={data}
            reloadCallback={reloadEvents}
          />
        </div>
      }
    </div>
  );
};

export default EventsDashboard;
