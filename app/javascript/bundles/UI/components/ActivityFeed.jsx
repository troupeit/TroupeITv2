import React, { useState, useEffect } from "react";
import ActivityItem from "./ActivityItem";

const ActivityFeed = (props) => {
  
  const { detailed, maxHistory } = props;

  const [activities, setActivities] = useState(null);

  const reloadData = () => {
    var url = "/notifications.json";

    if (maxHistory) {
      url = url + "?maxhistory=" + maxHistory;
    }

    $.ajax({
      url: url,
      dataType: "json",
      success: function (data) {
        setActivities(data);
        console.log("successful activities load");
      },
      error: function (xhr, status, err) {
        console.error("error loading activity feed", status, err.toString());
      },
    });
  };

  useEffect(() => {
    reloadData();
  }, []);

  // render
  var activityItems = [];

  if (activities != null) {
    var activityItems = activities.activities.map(function (a) {
      return (
        <ActivityItem
          key={a.activity._id}
          activityRecord={a}
          detailed={detailed}
        />
      );
    });
  }

  if (!detailed) {
    var moreDetailLinks = (
      <div className="button float-end">
        <a href="/notifications/history" className="btn">
          <button type="button" className="btn btn-default btn-sm">
            View Activity Detail
          </button>
        </a>
      </div>
    );
  }

  return (
    <div className="panel panel-inverse">
      <div className="panel-heading">
        <h3 className="panel-title">Activity in your Companies</h3>
      </div>
      <div className="panel-body">
        <ul className="list-unstyled">
          {activityItems}
        </ul>
        {moreDetailLinks}
      </div>
      </div>
  );
};

export default ActivityFeed;
