import React from "react";
import moment from "moment";

/**
 * ActPickerItem component
 * @param {Object} props - Component properties
 * @param {Object} props.act - Act details
 * @param {Function} props.reloadCallback - Callback to reload data
 * @returns {JSX.Element} ActPickerItem component
 */
const ActPickerItem = ({ act, reloadCallback }) => {
  /**
   * Add act to show
   * @param {Event} event - Event object
   */
  const addToShow = (event) => {
    event.preventDefault();
    const currentHref = document.querySelector('.nav-tabs .active a').getAttribute('href');
    const parts = currentHref.split("-");
    
    if (parts.length === 2) {
      const showid = parts[1];
      const postdata = {
        'show_id': showid,
        'kind': 32,
        'act_id': act._id.$oid
      };

      $.ajax({
        type: 'POST',
        url: "/show_items.json",
        dataType: 'json',
        contentType: 'application/json',
        data: JSON.stringify(postdata),
        success: function (response) {
          console.log("add ok.");
          reloadCallback();
          document.querySelector('.modal#actPicker').modal('hide');
        },
        error: function (xhr, status, err) {
          console.error('addToShow', status, err.toString());
        }
      });
    } else {
      console.log('cannot determine show id for addToShow');
    }
  };

  const cdate = moment(act.created_at);
  const udate = moment(act.updated_at);
  const cdate_s = cdate.format('LLLL');
  const udate_s = udate.format('LLLL');

  const tagslist = act.tags.map((t, index) => (
    <span key={index} className="label label-info tagspace">{t}</span>
  ));

  return (
    <a href="#" className="list-group-item" onClick={addToShow}>
      <h5 className="list-group-item-heading">
        <strong>{act.stage_name}</strong>&nbsp;
        <small>({formatDuration(act.length)})</small>
      </h5>
      <p className="list-group-item-text">
        {act.short_description}
      </p>
      <div className="tagbox">
        {tagslist}
      </div>
      <i><strong>{act.user.username}</strong> - {udate_s}</i>
    </a>
  );
};

export default ActPickerItem;