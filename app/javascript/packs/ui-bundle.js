import ReactOnRails from 'react-on-rails';

import Avatar from '../bundles/UI/components/Avatar';
import ConfirmModal from '../bundles/UI/components/ConfirmModal';
import DashboardApp from '../bundles/UI/components/DashboardApp';

// This is how react_on_rails can see the HelloWorld in the browser.
console.log('registering avatar');

ReactOnRails.register({
  Avatar,
  ConfirmModal,
  DashboardApp
});
