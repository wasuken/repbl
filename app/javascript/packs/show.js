// Run this example by adding <%= javascript_pack_tag "hello_elm" %> to the
// head of your layout file, like app/views/layouts/application.html.erb.
// It will render "Hello Elm!" within the page.

import {
	Elm
} from '../Show';

document.addEventListener('DOMContentLoaded', () => {
	const target = document.createElement('div');

	const csrfToken = document.head.querySelector('meta[name="csrf-token"]').content;
	const repoId = location.href.split('/').slice(-1)[0];
	const param = {
		repoId: repoId,
		csrfToken: csrfToken
	};

	document.body.appendChild(target);
	let app = Elm.Show.init({
		node: target,
		flags: param
	});

	app.ports.param.send(param);
})
