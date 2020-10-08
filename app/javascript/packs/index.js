// Run this example by adding <%= javascript_pack_tag "hello_elm" %> to the
// head of your layout file, like app/views/layouts/application.html.erb.
// It will render "Hello Elm!" within the page.

import {
	Elm
} from '../Index'

document.addEventListener('DOMContentLoaded', () => {
	const target = document.createElement('div')

	const csrfToken = document.head.querySelector('meta[name="csrf-token"]').content;
	console.log(csrfToken);

	document.body.appendChild(target)
	let app = Elm.Index.init({
		node: target,
		flags: csrfToken
	});

	app.ports.csrfToken.send(csrfToken);
})
