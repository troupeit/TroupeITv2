const CompanySelect = (props) => {
  if (props.companies == undefined) {
    return (<div><i className="far fa-spinner fa-spin"></i></div>);
  }
  
  var companyNodes = props.companies.map(function (company) {
    return (
        <option key={company.company_id} value={company.company_id}>{company.company.name}</option>
    );
  });

  if (props.showAll == true) {
    // have to do this as two vars or the select will fail.
    var showall=(<option key="all" value="all">All events in all companies</option>);
    var showallsep=(<option key="--" value="" disabled className="separator"></option>);
  }

  return (
    <div className="mb-3">
      <form role="form">
        <select className="form-select" name="companysel" id="companysel" onChange={props.callback} value={props.company}>
          {showall}
          {showallsep}
          {companyNodes}
        </select>
      </form>
    </div>
  );
};

export default CompanySelect;

