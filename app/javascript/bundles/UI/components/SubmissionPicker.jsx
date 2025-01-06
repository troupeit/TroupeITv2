var SubmissionPicker = React.createClass({
  getInitialState: function() {
    return { results: null }
  },
  reloadResults: function() {
    $.ajax({
      url: '/events/accepting_submissions.json',
      dataType: 'json',
      success: function (data) {
        if (data.length == 0) { data = null }
        this.setState({results: data});
        console.log("accepting_submissions reloaded");
        
      }.bind(this),
      error: function (xhr, status, err) {
        console.error("accepting_submissions ajax failed" + this.props.event_id, status, err.toString());
      }.bind(this)
    });
  },
  componentDidMount: function() {
    $(this.refs.alertref).hide();
    this.reloadResults();
  },
  render: function() {
    var n = 0;

    return (
            <div className="modal fade" id="submissionPicker" tabIndex="-1" role="dialog" aria-labelledby="submissionPickerLabel" aria-hidden="true">
                <div className="modal-dialog">
                    <div className="modal-content">
                        <div className="modal-header">
                            <button type="button" className="close" data-dismiss="modal" aria-label="Close">
                                <span aria-hidden="true">&times;</span>
                            </button>
                             <h4 className="modal-title" id="submissionPickerLabel">Submit to which Event?</h4>
                             <p id="submissionPickerDetail"></p>
                        </div>
                           <input type="hidden" name="forAct" id="forAct" />
                           <div className="modal-body">
                           <div ref="alertref" className="alert alert-success" id='statusText'>Added to Event. You can safely close this window.</div>
                           <SubmissionPickerList results={this.state.results} reloadCallback={this.props.reloadCallback} />
                        </div>

                        <div className="modal-footer">
                            <button type="button" className="btn btn-default" data-dismiss="modal"> Close </button>
                        </div>
                    </div>
                </div>
            </div>
        )
    }
});
