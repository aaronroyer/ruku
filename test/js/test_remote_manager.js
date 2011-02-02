(function() {

module("remoteManager");

RMTEST = {};
RMTEST.activeHost = "192.168.1.70";
RMTEST.activeName = "The Initially Active Remote";
RMTEST.inactiveHost = "192.168.1.80";
RMTEST.inactiveName = "Not Initially Active";

function getTestRemoteManager() {
	return RUKU.createRemoteManager({
		remotes: [
			{host:RMTEST.inactiveHost, name:RMTEST.inactiveName},
			{host:RMTEST.activeHost, name:RMTEST.activeName}
		],
		active: 1
	});
}

test("should create correctly with no args", function() {
	var rm = RUKU.createRemoteManager();
	equals(rm.remotes.length, 0);
	equals(rm.activeIndex, 0);
});

test("should create correctly with remote data", function() {
	var rm = getTestRemoteManager();
	equals(rm.remotes.length, 2);
	equals(rm.activeIndex, 1);
	equals(rm.remotes[0].host,RMTEST.inactiveHost);
	equals(rm.remotes[0].name, RMTEST.inactiveName);
	equals(rm.remotes[1].host, RMTEST.activeHost);
	equals(rm.remotes[1].name, RMTEST.activeName);
});

test("should create correctly without active index", function() {
	var rm = RUKU.createRemoteManager({
		remotes: [
			{host:"192.168.1.8", name:"Should Be Active"},
			{host:"192.168.1.70", name:"Not Active"}
		]
	});
	equals(rm.remotes.length, 2);
	equals(rm.activeIndex, 0);
	equals(rm.remotes[0].host, "192.168.1.8");
	equals(rm.remotes[1].host, "192.168.1.70");
});

test("load should load data from the server", function() {
	var newHost = "192.168.1.20";
	TEST.mockAjax({"remotes":[{"host":newHost}],"active":0});
	var rm = getTestRemoteManager();
	equals(rm.remotes.length, 2, "Initialized with correct number of remotes");

	rm.load();

	var opts = TEST.lastAjaxOptions;
	equals(opts.url, "/ajax");
	equals(opts.dataType, "json");
	equals(opts.data.action, "list");

	equals(rm.remotes.length, 1);
	equals(rm.getActive().host, newHost);
});

test("should send data to the server for saving", function() {
	var rm = getTestRemoteManager();

	TEST.mockAjax("success");

	rm.save();

	var opts = TEST.lastAjaxOptions;
	equals(opts.url, "/ajax", "Correct path used");
	equals(opts.data.action, "update", "Correct action specified");

	var remoteData = $.parseJSON(opts.data.data);
	equals(remoteData.remotes.length, 2, "Correct number of remotes sent");
	var remote1 = remoteData.remotes[0];
	var remote2 = remoteData.remotes[1];
	equals(remote1.host, RMTEST.inactiveHost, "First remote host sent correctly");
	equals(remote1.name, RMTEST.inactiveName, "First remote name sent correctly");
	equals(remote1.port, 8080, "First remote port sent correctly");
	equals(remote2.host, RMTEST.activeHost, "Second remote host sent correctly");
	equals(remote2.name, RMTEST.activeName, "Second remote name sent correctly");
	equals(remote2.port, 8080, "Second remote port sent correctly");
	equals(remoteData.active, 1, "Active index sent correctly");
});

test("getActive should get the active remote", function() {
	var rm = getTestRemoteManager();
	equals(rm.getActive().host, RMTEST.activeHost);
	equals(rm.getActive().name, RMTEST.activeName);
});

test("setActive with remote object should set the active remote and send the update to the server",
			function() {
	var rm = getTestRemoteManager();
	equals(rm.getActive().host, RMTEST.activeHost, "Initial active host is correct");

	TEST.mockAjax("success");

	var newActive = RUKU.createRemote({name:RMTEST.inactiveName, host:RMTEST.inactiveHost});
	rm.setActive(newActive);

	equals(rm.getActive().host, newActive.host, "Active host address updated correctly");
	equals(rm.getActive().name, newActive.name, "Active name updated correctly");

	var opts = TEST.lastAjaxOptions;
	equals(opts.url, "/ajax", "Correct path used");
	equals(opts.data.action, "update", "Correct action specified");

	var remoteData = $.parseJSON(opts.data.data);
	equals(remoteData.remotes.length, 2, "Correct number of remotes sent");
	var remote1 = remoteData.remotes[0];
	var remote2 = remoteData.remotes[1];
	equals(remote1.host, RMTEST.inactiveHost, "First remote host sent correctly");
	equals(remote2.host, RMTEST.activeHost, "Second remote host sent correctly");
	equals(remoteData.active, 0, "Correct new active index sent to server");
});

test("setActive with host should set the active remote and send the update to the server",
			function() {
	var rm = getTestRemoteManager();
	equals(rm.getActive().host, RMTEST.activeHost, "Initial active host is correct");

	TEST.mockAjax("success");

	var newActive = RUKU.createRemote({name:RMTEST.inactiveName, host:RMTEST.inactiveHost});
	rm.setActive(newActive.host); // Set with host instead of remote object itself

	equals(rm.getActive().host, newActive.host, "Active host address updated correctly");
	equals(rm.getActive().name, newActive.name, "Active name updated correctly");

	var opts = TEST.lastAjaxOptions;
	equals(opts.url, "/ajax", "Correct path used");
	equals(opts.data.action, "update", "Correct action specified");

	var remoteData = $.parseJSON(opts.data.data);
	equals(remoteData.remotes.length, 2, "Correct number of remotes sent");
	var remote1 = remoteData.remotes[0];
	var remote2 = remoteData.remotes[1];
	equals(remote1.host, RMTEST.inactiveHost, "First remote host sent correctly");
	equals(remote2.host, RMTEST.activeHost, "Second remote host sent correctly");
	equals(remoteData.active, 0, "Correct new active index sent to server");
});

test("should load scan for first results from the server", function() {
	var newHost = "192.168.1.77";
	var rm = getTestRemoteManager();

	TEST.mockAjax({"remotes":[{"host":newHost}],"active":0});

	rm.scanForFirst();

	var opts = TEST.lastAjaxOptions;
	equals(opts.url, "/ajax");
	equals(opts.dataType, "json");
	equals(opts.data.action, "scanForFirst");

	var active = rm.getActive();
	equals(active.host, newHost);
});

test("should load scan for all results from the server", function() {
	var firstHost = "192.168.1.77";
	var secondHost = "192.168.1.78";
	var rm = getTestRemoteManager();

	TEST.mockAjax({"remotes":[{"host":firstHost}, {"host":secondHost}],"active":0});

	rm.scanForAll();

	var opts = TEST.lastAjaxOptions;
	equals(opts.url, "/ajax");
	equals(opts.dataType, "json");
	equals(opts.data.action, "scanForAll");

	equals(rm.remotes.length, 2, "Correct number of remotes retrieved");
	var active = rm.getActive();
	equals(active.host, firstHost);
	equals(rm.remotes[1].host, secondHost);
});

})();
