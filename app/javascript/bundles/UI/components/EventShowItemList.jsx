import React, { useEffect } from "react";
import moment from "moment";
import EventShowItem from "./EventShowItem";
import $ from "jquery";

/**
 * EventShowItemList component
 * @param {Object} props - Component properties
 * @param {Object} props.show - Show details
 * @param {Array} props.show_items - List of show items
 * @param {Function} props.reloadCallback - Callback to reload data
 * @param {Object} props.user - User details
 * @param {Object} props.event - Event details
 * @param {Object} props.notemodal - Note modal details
 * @returns {JSX.Element} EventShowItemList component
 */
const EventShowItemList = ({ show, show_items, reloadCallback, user, event, notemodal }) => {
  useEffect(() => {
    $('.nav-tabs a:first').tab('show');
  }, []);

  if (show == null) {
    return (
      <div className="container">
        <i className="fa fa-spinner fa-spin"></i>
      </div>
    );
  }

  let starttime = moment(show.door_time);

  const showItemNodes = show_items.length === 0 ? (
    <div className="row">There are no acts in this show.</div>
  ) : (
    show_items.map((s) => {
      const data = (
        <EventShowItem
          key={s.show_item._id.$oid}
          start_time={starttime.tz(event.event.time_zone).format('h:mm a')}
          duration={s.show_item.duration}
          show_item={s.show_item}
          act={s.act}
          assets={s.assets}
          reloadCallback={reloadCallback}
          total_items={show_items.length}
          user={user}
          event={event}
          notemodal={notemodal}
          owner={s.owner}
        />
      );
      starttime = starttime.add(s.show_item.duration, 'seconds');
      return data;
    })
  );

  return <div>{showItemNodes}</div>;
};

export default EventShowItemList;
