import React, { useState, useEffect } from "react";
import ReactDOM from "react-dom";
import $ from "jquery";

const EXPORT_FIELDS = [
  'MC Intro',
  'Sound',
  'Lights',
  'Props/Stage',
  'Cleanup',
  'Performer Notes',
  'Personal Notes',
  'Company Notes'
];

const placeholder = document.createElement("li");
placeholder.className = "list-group-item placeholder";

/**
 * DragList component
 * @param {Object} props - Component properties
 * @param {Array} props.data - List of fields
 * @param {Array} props.initialChecked - Initial checked state
 * @param {Array} props.initialOrder - Initial order
 * @returns {JSX.Element} DragList component
 */
const DragList = ({ data, initialChecked, initialOrder }) => {
  const [state, setState] = useState({
    data: data,
    checked: initialChecked,
    order: initialOrder
  });

  useEffect(() => {
    $(window).on("dlReset", handleReset);
    return () => {
      $(window).off("dlReset", handleReset);
    };
  }, []);

  const handleReset = () => {
    const checkStates = Array(data.length).fill(true);
    const order = data.map((_, i) => i);
    setState({ data: data, checked: checkStates, order: order });
  };

  const dragStart = (e) => {
    e.dataTransfer.effectAllowed = 'move';
    e.dataTransfer.setData("text/html", e.currentTarget);
    e.currentTarget.style.display = "none";
  };

  const dragEnd = (e) => {
    e.currentTarget.style.display = "block";
    e.currentTarget.parentNode.removeChild(placeholder);

    const from = Number(e.currentTarget.dataset.id);
    const to = Number(placeholder.dataset.id);

    const newData = [...state.data];
    const newChecked = [...state.checked];
    const newOrder = [...state.order];

    if (from < to) to--;
    if (placeholder.nodePlacement === "after") to++;

    newData.splice(to, 0, newData.splice(from, 1)[0]);
    newChecked.splice(to, 0, newChecked.splice(from, 1)[0]);
    newOrder.splice(to, 0, newOrder.splice(from, 1)[0]);

    $(window).trigger("dlUpdate", [newChecked, newOrder]);

    setState({ data: newData, checked: newChecked, order: newOrder });
  };

  const dragOver = (e) => {
    e.preventDefault();
    const over = e.currentTarget;
    const relY = e.clientY - over.offsetTop;
    const height = over.offsetHeight / 2;
    const parent = over.parentNode;

    if (relY > height) {
      placeholder.nodePlacement = "after";
      parent.insertBefore(placeholder, over.nextElementSibling);
    } else {
      placeholder.nodePlacement = "before";
      parent.insertBefore(placeholder, over);
    }
  };

  const handleClick = (i) => {
    const newChecked = [...state.checked];
    newChecked[i] = !newChecked[i];
    setState({ ...state, checked: newChecked });
    $(window).trigger("dlUpdate", [newChecked, state.order]);
  };

  return (
    <div className="col-sm-offset-1 col-sm-10 col-sm-offset-1">
      <ul onDragOver={dragOver} className="list-group draglist">
        {state.data.map((item, i) => (
          <li
            className="list-group-item draglist"
            data-id={i}
            key={i}
            draggable="true"
            onDragEnd={dragEnd}
            onDragStart={dragStart}
          >
            <span className="float-end">
              <input
                type="checkbox"
                className="form-check-input"
                checked={state.checked[i]}
                onChange={() => handleClick(i)}
              />
            </span>
            <span className="bi bi-list" style={{ color: "#aaa" }}></span> {item}
          </li>
        ))}
      </ul>
    </div>
  );
};

/**
 * ExportModal component
 * @param {Object} props - Component properties
 * @param {Object} props.show - Show details
 * @returns {JSX.Element} ExportModal component
 */
const ExportModal = ({ show }) => {
  const [state, setState] = useState({
    checked: [1, 1, 1, 1, 1, 1, 0, 0],
    order: [0, 1, 2, 3, 4, 5, 6, 7]
  });

  useEffect(() => {
    $(window).on("dlUpdate", doUpdate);
    return () => {
      $(window).off("dlUpdate", doUpdate);
    };
  }, []);

  const doUpdate = (e, checked, order) => {
    setState({ checked: checked, order: order });
  };

  const doExport = (type) => {
    const mychecked = state.checked.map((m) => (m ? 1 : 0));
    const win = window.open(
      `/shows/${show._id.$oid}.${type}?checked=${mychecked}&order=${state.order}`,
      "_blank"
    );
    if (win) {
      win.focus();
    } else {
      alert("Please allow popups for troupeIT's export to work correctly.");
    }
  };

  const handleClose = (e) => {
    $(ReactDOM.findDOMNode(this)).modal("hide");
    e.preventDefault();
  };

  const handleReset = (e) => {
    $(window).trigger("dlReset");
  };

  return (
    <div className="modal fade" id="exportModal" tabIndex="-1" aria-labelledby="exportLabel" aria-hidden="true">
      <div className="modal-dialog">
        <div className="modal-content">
          <div className="modal-header">
            <button type="button" className="btn-close" data-bs-dismiss="modal" aria-label="Close" onClick={handleClose}></button>
            <h4 className="modal-title" id="exportModalTitle">Custom Export</h4>
          </div>
          <div className="modal-body">
            Export which fields? Drag and drop to change order.
          </div>
          <DragList data={EXPORT_FIELDS} initialOrder={state.order} initialChecked={state.checked} />
          <div className="modal-footer">
            <button type="button" className="btn btn-success" onClick={handleReset}>Reset</button>
            <button type="button" className="btn btn-danger" data-bs-dismiss="modal">Cancel</button>
            <button type="button" className="btn btn-success" onClick={() => doExport("pdf")}>Create PDF</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ExportModal;
