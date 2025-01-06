var InviteModal = React.createClass({
  getInitialState: function() {
    return { visible: false, company: null };
  },
  closeModal: function(e) {
    $('#inviteModal').modal('hide');
    e.preventDefault();
  },
  handleShowEvent: function(e) {
    this.setState({company: e.detail.company});
    $('#inviteModal').modal('show');
  },
  listenForShowEvent: function() {
    window.addEventListener("showInviteModal", this.handleShowEvent, false);
  },
  componentDidMount: function() {
    this.listenForShowEvent();
    if ( this.state.visible == true ) {
      $('#inviteModal').modal('show');
    }
  },
  render: function() { 
    return (
        <div className="modal fade msgModal" id="inviteModal" tabIndex="-1" role="dialog" aria-labelledby="inviteLabel" aria-hidden="true">
           <div className="modal-dialog">
               <div className="modal-content">
                   <div className="modal-header">
                   <button type="button" className="close" data-dismiss="modal" aria-label="Close" onClick={this.props.handleClose}>
                           <span aria-hidden="true">&times;</span>
                       </button>
                      <h4 className="modal-title" id="inviteModalTitle">Invite</h4>
                   </div>

                   <div className="modal-body">
                      <InvitationPanel company={this.state.company} />
                   </div>
        
                   <div className="modal-footer">
                     <button type="button" className="btn btn-primary" id='okBtn' onClick={this.closeModal}> Ok </button>
                   </div>
               </div>
           </div>
       </div>
     )
  }
});

