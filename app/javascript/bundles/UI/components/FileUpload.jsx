import React, { useState, useEffect, useRef } from 'react';
import $ from 'jquery';
import ReactDOM from 'react-dom';
import plupload from 'plupload';

/**
 * FileListRow component
 * @param {Object} props - Component properties
 * @param {Object} props.file - File details
 * @returns {JSX.Element} FileListRow component
 */
const FileListRow = ({ file }) => (
  <tr>
    <td>{file.name}</td>
    <td>{bytesToSize(file.size)}</td>
    <td>
      <div className="progress" style={{ width: "200px" }}>
        <div className="progress-bar progress-bar-success progress-bar-striped active" role="progressbar" style={{ width: file.progpercent }} id={file.id}>
          {file.progpercent}
        </div>
      </div>
    </td>
  </tr>
);

/**
 * FileUpload component
 * @param {Object} props - Component properties
 * @param {Function} props.successCallback - Callback function for successful upload
 * @returns {JSX.Element} FileUpload component
 */
const FileUpload = ({ successCallback }) => {
  const [files, setFiles] = useState([]);
  const [lastPasset, setLastPasset] = useState(undefined);
  const dropzoneRef = useRef(null);
  const uploaderRef = useRef(null);

  useEffect(() => {
    const $dropzone = $(dropzoneRef.current);

    $dropzone
      .on('dragover', () => $dropzone.addClass('over'))
      .on('dragleave', () => $dropzone.removeClass('over'))
      .on('drop', () => $dropzone.removeClass('over'));

    const uploader = new plupload.Uploader({
      max_file_count: 1,
      multi_selection: false,
      file_data_name: 'file',
      browse_button: 'pickfiles',
      url: 'http://amazonaws.com', // placeholder, if blank plupload will not init
      drop_element: 'dropper',
      multipart: true,
      multipart_params: {
        filename: 'filename',
        utf8: true,
        acl: "public-read",
        AWSAccessKeyId: '',
        policy: '',
        signature: '',
        key: "uploads/${filename}",
        'Content-Type': ''
      }
    });

    uploader.init();
    $("#startupload").prop("disabled", true);

    uploader.bind('UploadProgress', (up, file) => {
      const pctLoaded = Math.floor((file.loaded / file.size) * 100);
      $(ReactDOM.findDOMNode(dropzoneRef.current)).find('div#' + file.id).width(pctLoaded + '%');
      $(ReactDOM.findDOMNode(dropzoneRef.current)).find('div#' + file.id).html(pctLoaded + '%');
      console.log('upload progress: ' + file.id + ' ' + file.name + ' ' + pctLoaded);
    });

    uploader.bind('Error', (up, err) => {
      console.log("\nError #" + err.code + ": " + err.message);
      if (err.code === -200) {
        console.log("\nError #" + err.code + ": " + err.message);
      }
      window.onbeforeunload = null;
    });

    uploader.bind('FilesAdded', (up, files) => {
      files.forEach(file => {
        setFiles(prevFiles => [...prevFiles, file]);
        console.log("added : " + file.name);

        up.settings.multipart_params['Content-Type'] = file.type;

        window.onbeforeunload = () => "You have a file upload in progress. Leave?";

        $("#startupload").prop("disabled", false);
        $("#searcharea").hide();
      });
    });

    uploader.bind('BeforeUpload', handleBeforeUpload);

    uploader.bind('FileUploaded', (up, file, info) => {
      console.log('fileuploaded - OK!');
    });

    uploader.bind('UploadComplete', (up, files) => {
      clearFiles();
      $("#searcharea").show();
      window.onbeforeunload = null;

      if (successCallback) {
        successCallback(files);
      }
    });

    uploaderRef.current = uploader;

    return () => {
      $dropzone.off('dragover dragleave drop');
    };
  }, []);

  const clearFiles = () => {
    setFiles([]);
  };

  const handleBeforeUpload = (uploader, file) => {
    const settings = uploader.settings;
    const params = settings.multipart_params;

    const postData = {
      filename: file.name,
      size: file.size,
      kind: file.type
    };

    $.ajax({
      url: '/passets.json',
      type: 'POST',
      contentType: 'application/json',
      data: JSON.stringify(postData),
      dataType: 'json',
      success: (response) => {
        settings.url = response.formUrl;
        Object.keys(response.formData).forEach(key => {
          if (params.hasOwnProperty(key)) {
            params[key] = response.formData[key];
          }
        });
        file.status = plupload.UPLOADING;
        file.passet = response.passet;
        setLastPasset(response.passet);
        uploader.trigger("UploadFile", file);
      },
      error: (xhr, status, err) => {
        console.error('failed to get S3 policy ' + err);
      }
    });

    return false;
  };

  const doUpload = () => {
    $("#startupload").prop("disabled", true);

    window.onbeforeunload = () => "You have a file upload in progress. Leave?";

    uploaderRef.current.start();
  };

  const fileRows = files.map(file => (
    <FileListRow key={file.name} file={file} />
  ));

  const fileList = files.length > 0 && (
    <div>
      <table className="table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Size</th>
            <th>Progress</th>
          </tr>
        </thead>
        <tbody>
          {fileRows}
        </tbody>
      </table>
    </div>
  );

  const uploadBtn = files.length > 0 && (
    <button className="btn btn-success w-100" id="startupload" onClick={doUpload}>
      <i className="fa fa-upload"></i>&nbsp;Start Upload
    </button>
  );

  const ulText = files.length === 0 ? "Drop a file to upload in this box, or " : "To start your upload, click \"Start Upload\". Or, you can ";
  const btnText = files.length === 0 ? "Select a File" : "Add Another File";

  return (
    <div>
      <div id="dropper" className="dropper" ref={dropzoneRef}>
        <div className="help">{ulText}&nbsp;
          <a id="pickfiles" href="#">
            <button className="btn btn-info">
              {btnText}
            </button>
          </a>&nbsp;
        </div>
      </div>
      {uploadBtn}
      {fileList}
    </div>
  );
};

export default FileUpload;