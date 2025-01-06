import ReactOnRails from 'react-on-rails';

import HelloWorld from '../bundles/HelloWorld/components/HelloWorldServer';
import Avatar from '../bundles/UI/components/Avatar';
import DashboardApp from '../bundles/UI/components/DashboardApp';
// This is how react_on_rails can see the HelloWorld in the browser.
ReactOnRails.register({
  Avatar,
  DashboardApp,
  HelloWorld,
});
