import React, { useState, useEffect, useRef } from "react";
import $ from "jquery";

/**
 * TaskListItem component
 * @param {Object} props - Component properties
 * @param {Object} props.item - Task item details
 * @param {string} props.event_id - Event ID
 * @param {Function} props.reloadCallback - Callback to reload data
 * @param {Function} props.dragStart - Drag start handler
 * @param {Function} props.dragEnd - Drag end handler
 * @param {Function} props.dragOver - Drag over handler
 * @param {string} props.itemClass - CSS class for the item
 * @param {number} props.seq - Sequence number
 * @returns {JSX.Element} TaskListItem component
 */
const TaskListItem = ({ item, event_id, reloadCallback, dragStart, dragEnd, dragOver, itemClass, seq }) => {
  const [state, setState] = useState({ working: false, hover: false, editing: false, dragok: item !== undefined });
  const taskinputRef = useRef(null);
  const taskcheckRef = useRef(null);

  useEffect(() => {
    if (item !== undefined) {
      taskinputRef.current.style.height = `${taskinputRef.current.scrollHeight}px`;
    }
  }, [item]);

  const mouseOver = (e) => {
    if (!state.editing) {
      setState({ ...state, hover: true });
      e.preventDefault();
    }
  };

  const mouseOut = (e) => {
    if (!state.editing) {
      setState({ ...state, hover: false });
      e.preventDefault();
    }
  };

  const editItem = () => {
    setState({ ...state, hover: false, editing: true, dragok: false });
  };

  const updateCheck = () => {
    updateItem();
  };

  const updateItem = () => {
    const postdata = {
      event_id: event_id,
      task: {
        txt: taskinputRef.current.value,
        completed: taskcheckRef.current.checked,
      },
    };

    setState({ ...state, working: true });

    $.ajax({
      type: "PUT",
      url: `/tasks/${item._id.$oid}.json`,
      dataType: "json",
      contentType: "application/json",
      data: JSON.stringify(postdata),
      success: () => {
        setState({ ...state, editing: false, working: false, dragok: true });
        reloadCallback();
      },
      error: (xhr, status, err) => {
        setState({ ...state, editing: false, working: false });
        console.error("addtask", status, err.toString());
      },
    });
  };

  const deleteItem = () => {
    $.ajax({
      type: "DELETE",
      url: `/tasks/${item._id.$oid}.json`,
      success: () => {
        reloadCallback();
      },
      error: (xhr, status, err) => {
        console.error("delete failed", status, err.toString());
      },
    });
  };

  const addItem = () => {
    if (taskinputRef.current.value.length === 0) {
      return;
    }

    setState({ ...state, working: true });
    const postdata = {
      event_id: event_id,
      task: {
        txt: taskinputRef.current.value,
      },
    };

    $.ajax({
      type: "POST",
      url: "/tasks.json",
      dataType: "json",
      contentType: "application/json",
      data: JSON.stringify(postdata),
      success: () => {
        setState({ ...state, working: false });
        taskinputRef.current.value = "";
        reloadCallback();
      },
      error: (xhr, status, err) => {
        setState({ ...state, working: false });
        console.error("addtask", status, err.toString());
      },
    });
  };

  const handleKeyUp = (e) => {
    if (e.which === 27) {
      setState({ ...state, editing: false });
      taskinputRef.current.value = item.txt;
    }
  };

  let taskinput;
  let hover;
  let addbtn;

  if (item === undefined) {
    if (!state.working) {
      addbtn = (
        <div className="input-group-text">
          <button onClick={addItem} className="btn btn-sm btn-primary">Add</button>
        </div>
      );
    } else {
      addbtn = (
        <div className="input-group-text">
          <i className="fa fa-spinner fa-spin"></i>
        </div>
      );
    }

    taskinput = (
      <textarea
        className="form-control"
        placeholder="Add Task"
        ref={taskinputRef}
        rows="1"
        style={{ overflow: "hidden", wordWrap: "break-word", resize: "none", height: "50px" }}
      />
    );
  } else {
    if (state.hover) {
      hover = (
        <div className="input-group-text">
          <button onClick={deleteItem} className="btn btn-sm btn-primary">
            <i className="fa fa-trash"></i>
          </button>&nbsp;
          <button onClick={editItem} className="btn btn-sm btn-primary">
            <i className="fa fa-pencil"></i>
          </button>
        </div>
      );
    }

    taskinput = (
      <textarea
        type="text"
        className="form-control dragmoveok"
        disabled={!state.editing}
        ref={taskinputRef}
        defaultValue={item.txt}
        style={{ overflow: "hidden", wordWrap: "break-word", resize: "none" }}
        onKeyUp={handleKeyUp}
      />
    );

    if (state.editing) {
      if (!state.working) {
        hover = (
          <div className="input-group-text">
            <button onClick={updateItem} className="btn btn-sm btn-primary">
              Save
            </button>
          </div>
        );
      } else {
        hover = (
          <div className="input-group-text">
            <i className="fa fa-spinner fa-spin"></i>
          </div>
        );
      }
    }
  }

  const checkval = item !== undefined ? item.completed : false;
  const key = item !== undefined ? item._id.$oid : "new";

  return (
    <li
      data-seq={seq}
      key={key}
      draggable={state.dragok}
      onMouseEnter={mouseOver}
      onMouseLeave={mouseOut}
      onDragStart={dragStart}
      onDragEnd={dragEnd}
      onDragOver={dragOver}
      className={itemClass}
    >
      <div className="form-group mb-2">
        <div className="input-group">
          <div className="input-group-text">
            <input
              type="checkbox"
              className="form-check-input"
              ref={taskcheckRef}
              disabled={item === undefined}
              checked={checkval}
              onChange={updateCheck}
            />
          </div>
          {taskinput}
          {hover}
          {addbtn}
        </div>
      </div>
    </li>
  );
};

export default TaskListItem;