import React from "react";
import ActPickerItem from "./ActPickerItem";

/**
 * ActPickerList component
 * @param {Object} props - Component properties
 * @param {Array} props.results - List of act results
 * @param {Function} props.reloadCallback - Callback to reload data
 * @returns {JSX.Element} ActPickerList component
 */
const ActPickerList = ({ results, reloadCallback }) => {
  if (!results) {
    return (
      <div className="list-group">
        <a href="#" className="list-group-item">No results.</a>
      </div>
    );
  }

  const pickeritems = results.map((d) => (
    <ActPickerItem key={d._id.$oid} act={d} reloadCallback={reloadCallback} />
  ));

  return (
    <div className="list-group" style={{ height: '450px', overflow: 'scroll' }}>
      {pickeritems}
    </div>
  );
};

export default ActPickerList;