render: {
	baseUrl: "https://sean.liao.dev"
	gtm:     "GTM-TLVN7D6"
}

firebase: {
	site: "com-seankhliao"
	headers: [{
		glob: "/static/*.woff2"
		headers: "Access-Control-Allow-Origin": "*"
	}, {
		glob: "/(icon*|favicon.ico)"
		headers: "Access-Control-Allow-Origin": "*"
	}]
	_redirects: [
		["/ac-p-s", "/?utm_campaign=seankhliao&utm_medium=profile&utm_source=angelco"],
		["/cv-p-s", "/?utm_campaign=seankhliao\u0026utm_medium=profile\u0026utm_source=cv"],
		["/fb-p-s", "/?utm_campaign=seankhliao\u0026utm_medium=profile\u0026utm_source=facebook"],
		["/gh-p-er", "/?utm_campaign=erred\u0026utm_medium=profile\u0026utm_source=github"],
		["/gh-p-sd", "/?utm_campaign=sean-dbk\u0026utm_medium=profile\u0026utm_source=github"],
		["/gh-p-s", "/?utm_campaign=seankhliao\u0026utm_medium=profile\u0026utm_source=github"],
		["/gh-p-ss", "/?utm_campaign=sean-snyk\u0026utm_medium=profile\u0026utm_source=github"],
		["/gh-r-er", "/?utm_campaign=erred\u0026utm_medium=readme\u0026utm_source=github"],
		["/gh-r-sd", "/?utm_campaign=sean-dbk\u0026utm_medium=readme\u0026utm_source=github"],
		["/gh-r-s", "/?utm_campaign=seankhliao\u0026utm_medium=readme\u0026utm_source=github"],
		["/gh-s-er", "/?utm_campaign=erred\u0026utm_medium=site\u0026utm_source=github"],
		["/gh-s-sd", "/?utm_campaign=sean-dbk\u0026utm_medium=site\u0026utm_source=github"],
		["/gh-s-s", "/?utm_campaign=seankhliao\u0026utm_medium=site\u0026utm_source=github"],
		["/g-p-s", "/?utm_campaign=seankhliao\u0026utm_medium=profile\u0026utm_source=google"],
		["/ig-p-s", "/?utm_campaign=seankhliao\u0026utm_medium=profile\u0026utm_source=instagram"],
		["/li-r-s", "/?utm_campaign=seankhliao\u0026utm_medium=readme\u0026utm_source=linkedin"],
		["/li-p-s", "/?utm_campaign=seankhliao\u0026utm_medium=profile\u0026utm_source=linkedin"],
		["/mtd-p-s", "/?utm_campaign=seankhliao\u0026utm_medium=profile\u0026utm_source=mastodon"],
		["/sl-p-gophers", "/?utm_campaign=gophers\u0026utm_medium=profile\u0026utm_source=slack"],
		["/tw-p-s", "/?utm_campaign=seankhliao\u0026utm_medium=profile\u0026utm_source=twitter"],
		["/w-s-liadev", "/?utm_campaign=liadev\u0026utm_medium=site\u0026utm_source=web"],
		["/yt-p-s", "/?utm_campaign=seankhliao\u0026utm_medium=profile\u0026utm_source=youtube"],
	]
	redirects: [ for _red in _redirects {
		code:     307
		glob:     _red[0]
		location: _red[1]
	}]
}
