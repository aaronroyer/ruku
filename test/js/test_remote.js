module("remote");

test("should create correctly", function() {
	var initObj = {host:"192.168.1.101", name:"Test box name", port:"5000"};
	var remote = RUKU.createRemote(initObj);
	equals(remote.host, initObj.host);
	equals(remote.name, initObj.name);
	equals(remote.port, initObj.port);
});

test("should have correct default port", function() {
	var initObj = {host:"192.168.1.101", name:"Test box name"};
	var remote = RUKU.createRemote(initObj);
	equals(remote.host, initObj.host);
	equals(remote.name, initObj.name);
	equals(remote.port, 8080);
});

test("should send ajax requests for commands", function() {
	var testHost = "192.168.1.101"
	var remote = RUKU.createRemote({host:testHost, name:"Test box name"});

	TEST.mockAjax("success");
	remote.up();
	var opts = TEST.lastAjaxOptions;

	equals(opts.url, "/ajax");
	equals(opts.data.host, testHost);
	equals(opts.data.command, "up");

	TEST.mockAjax("success");
	remote.select();
	var opts = TEST.lastAjaxOptions;
	equals(opts.url, "/ajax");
	equals(opts.data.host, testHost);
	equals(opts.data.command, "select");
});
