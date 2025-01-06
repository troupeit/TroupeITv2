import Button from 'react-bootstrap/Button';
import Modal from 'react-bootstrap/Modal';
/*
 * simple confirmation modal
 *
 * props: 
 *    title - title of modal
 *    message - inside modal body
 *    confirmText - default 'Ok'
 *    cancelText - default 'Cancel'
 * 
 * optional callbacks
 *    handleConfirm - function to call at confirm 
 *    handleClose - function to call at window close (x in upper right corner)
 *    handleCancel - function to call at cancel 
 */
import React, { useState } from 'react';

const ConfirmModal = (props) => {

  var confirmText = props.confirmText ? props.confirmText : "Ok";
  var cancelText = props.cancelText ? props.cancelText : "Cancel";
  var messageText = props.message ? props.message : "";
  var titleText = props.titleText ? props.titleText : "";

  var classes = "modal fade";
  if (props.show) {
    classes += " show";
  }

  return (
    <div
      className={classes}
      style={{ display: 'block', position: 'initial' }}
    >
      <Modal.Dialog id="#confirmModal">
        <Modal.Header closeButton>
          <Modal.Title id="#confirmModalTitle">{titleText}</Modal.Title>
        </Modal.Header>

        <Modal.Body id="#confirmModalBody">
          <p>{messageText}</p>
        </Modal.Body>

        <Modal.Footer>
          <Button id="#cancelBtn" variant="secondary">{cancelText}</Button>
          <Button id="#okBtn" variant="primary">{confirmText}</Button>
        </Modal.Footer>
      </Modal.Dialog>
    </div>
  );
}

export default ConfirmModal;
