import ReactOnRails from 'react-on-rails';

import Avatar from '../bundles/UI/components/Avatar';

// This is how react_on_rails can see the HelloWorld in the browser.
console.log('registering avatar');

ReactOnRails.register({
  Avatar,
});
