import React, { useState } from "react";
import PropTypes from "prop-types";

const ActivityFeed = (props) => {
  const [activities, setActivities] = useState(null);
  const [detailed, setDetailed] = useState(props.detailed || false);

  const reloadData = () => {
    var url = "/notifications.json";

    if (props.maxhistory != undefined) {
      url = url + "?maxhistory=" + props.maxhistory;
    }

    $.ajax({
      url: url,
      dataType: "json",
      success: function (data) {
        setActivities(data);
        console.log("successful activities load");
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
          activity={a}
          detailed={detailed}
        />
      );
    });
  }

  if (detailed == false) {
    var moreDetailLinks = (
      <div className="button">
        <a href="/notifications/history" className="btn">
          <button type="button" className="btn btn-default btn-xs">
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
        <ul className="media-list media-list-with-divider media-list-scroll">
          {activityItems}
        </ul>
        {moreDetailLinks}
      </div>
    </div>
  );
};

export default ActivityFeed;
