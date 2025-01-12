
/**
 * TaskList component
 * @param {Object} props - Component properties
 * @param {Array} props.tasks - List of tasks
 * @param {string} props.event_id - Event ID
 * @param {Function} props.reloadCallback - Callback to reload data
 * @returns {JSX.Element} TaskList component
 */
const TaskList = ({ tasks, event_id, reloadCallback }) => {
  const [state, setState] = useState({ tasks: tasks, dragging: undefined });
  let dragged;

  useEffect(() => {
    setState({ tasks: tasks });
  }, [tasks]);

  const dragStart = (e) => {
    dragged = Number(e.currentTarget.dataset.seq);
    console.log("start drag " + dragged);
    e.dataTransfer.effectAllowed = "move";
    e.dataTransfer.setData("text/html", null);
  };

  const dragEnd = () => {
    setState({ ...state, dragging: undefined });
    console.log("dragend");

    const taskseqs = {};
    for (let i = 0; i < state.tasks.length; i++) {
      console.log(state.tasks[i]._id.$oid + ": " + i);
      taskseqs[state.tasks[i]._id.$oid] = i;
    }

    const postdata = { tasks: taskseqs };

    $.ajax({
      type: "POST",
      url: "/tasks/update_seq.json",
      dataType: "json",
      contentType: "application/json",
      data: JSON.stringify(postdata),
      success: () => {
        reloadCallback();
      },
      error: (xhr, status, err) => {
        console.error("sequpdate failed", status, err.toString());
      },
    });
  };

  const dragOver = (e) => {
    e.preventDefault();
    const over = e.currentTarget;
    const from = isFinite(state.dragging) ? state.dragging : dragged;
    let to = Number(over.dataset.seq);

    if (isFinite(to)) {
      if (from < to) to--;
      if (e.clientY - over.offsetTop > over.offsetHeight / 2) {
        to++;
      }

      const items = state.tasks;
      items.splice(to, 0, items.splice(from, 1)[0]);
      setState({ tasks: items, dragging: to });
    }
  };

  const listitems = state.tasks.map((t, i) => {
    const dragging = i === state.dragging ? "dragging" : "";
    return (
      <TaskListItem
        event_id={event_id}
        item={t}
        reloadCallback={reloadCallback}
        key={t._id.$oid}
        dragEnd={dragEnd}
        dragStart={dragStart}
        dragOver={dragOver}
        itemClass={dragging}
        seq={i}
      />
    );
  });

  return (
    <div>
      <div className="card bg-dark text-white">
        <div className="card-header">
          <h3 className="card-title">Tasks</h3>
        </div>
        <div className="card-body overflow-auto" style={{ maxHeight: "400px" }}>
          <ul className="list-group list-group-flush" onDragOver={dragOver}>
            <TaskListItem event_id={event_id} reloadCallback={reloadCallback} key="add" />
            {listitems}
          </ul>
        </div>
      </div>
    </div>
  );
};

export default TaskList;
