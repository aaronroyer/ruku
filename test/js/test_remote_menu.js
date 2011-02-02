(function() {

module("remoteMenu", {
	setup:function() {
		$("#testArea").empty()
			.append($('<div id="activeRemoteTitle">&nbsp;</div>'))
			.append(
				$('<div id="remoteMenu" style="display:none;">' +
						'<a id="closeButton" class="buttonLink" href="#">X close</a>' +
						'<a id="scanButton" class="buttonLink" href="#">scan for boxes</a>' +
						'<div class="title">Manage Boxes</div>' +
						'<div id="remoteList"></div>' +
						'<div id="firstBoxInfo" style="display:none;"></div>' +
					'</div>')
			);
	}, teardown:function() {
		$("#testArea").empty();
	}
});

MENUTEST = {};
MENUTEST.activeHost = "192.168.1.70";
MENUTEST.activeName = "The Active Remote";
MENUTEST.inactiveHost = "192.168.1.80";
MENUTEST.inactiveName = "Not Active";

function getTestRemoteManager() {
	return RUKU.createRemoteManager({
		remotes: [
			{host:MENUTEST.inactiveHost, name:MENUTEST.inactiveName},
			{host:MENUTEST.activeHost, name:MENUTEST.activeName}
		],
		active: 1
	});
}

function getTestRemoteMenu() {
	return RUKU.createRemoteMenu($("#remoteMenu"), $("#activeRemoteTitle"), getTestRemoteManager());
};

test("should know if it hasRemotes", function() {
	ok(getTestRemoteMenu().hasRemotes(), "Yep, 2 remotes here");
	ok(!RUKU.createRemoteMenu($("remoteMenu"), $("activeRemoteTitle")).hasRemotes(),
			"No remotes in this one");
	ok(!RUKU.createRemoteMenu($("remoteMenu"), $("activeRemoteTitle"),
			RUKU.createRemoteManager()).hasRemotes(), "Also no remotes");
});

test("should show remotes list correctly", function() {
	var menu = getTestRemoteMenu();
	menu.show();
	var remoteDivs = $("#remoteMenu > #remoteList > div.remote");
	equals(remoteDivs.size(), 2, "Displays the correct number of remotes");
	equals(remoteDivs.first().find(".name").val(), MENUTEST.inactiveName,
		"First remote name is correct");
	equals(remoteDivs.first().find(".host").text(), MENUTEST.inactiveHost,
		"First remote host is correct");
	equals(remoteDivs.last().find(".name").val(), MENUTEST.activeName,
		"Second remote name is correct");
	equals(remoteDivs.last().find(".host").text(), MENUTEST.activeHost,
		"Second remote host is correct");
	ok($("#remoteMenu > #remoteList").is(":visible"), "List is visible");
});

test("should get the correct active remote", function() {
	var menu = getTestRemoteMenu();
	var active = menu.getActiveRemote();
	equals(active.host, MENUTEST.activeHost, "Active remote has correct host");
});

test("should load results from server and render result after scanning for first", function() {
	var newHost = "192.168.1.77";
	var menu = getTestRemoteMenu();

	TEST.mockAjax({"remotes":[{"host":newHost}],"active":0});

	$("#remoteMenu").show(); // Remote menu would be visible for scan button to be clicked

	$("#scanButton").click();

	var opts = TEST.lastAjaxOptions;
	equals(opts.url, "/ajax");
	equals(opts.dataType, "json");
	equals(opts.data.action, "scanForFirst");

	var active = menu.getActiveRemote();
	equals(active.host, newHost);

	ok($("#firstBoxInfo").is(":visible"));
	equals($("#firstBoxInfo .host").text(), newHost);
});

test("should load results from server and render result after scanning for all", function() {
	var firstHost = "192.168.1.77";
	var secondHost = "192.168.1.78";
	var menu = getTestRemoteMenu();

	TEST.mockAjax({"remotes":[{"host":firstHost}],"active":0});
	$("#remoteMenu").show();
	$("#scanButton").click();

	// We should be set up now in the typical situation to scan for more boxes,
	// after the first is found and displayed.

	// Send back one more the second time
	TEST.mockAjax({"remotes":[{"host":firstHost}, {"host":secondHost}],"active":0});
	$("#remoteMenu .moreButton").click();

	var remoteDivs = $("#remoteMenu > #remoteList > div.remote");
	equals(remoteDivs.size(), 2, "Displays the correct number of remotes");
	equals(remoteDivs.first().find(".host").text(), firstHost,
		"First remote host is correct");
	equals(remoteDivs.last().find(".host").text(), secondHost,
		"Second remote host is correct");
	ok($("#remoteMenu > #remoteList").is(":visible"), "List is visible");
});

test("should allow updating of remote name", function() {
	var menu = getTestRemoteMenu();
	menu.show();

	var newName = "New Name";

	// This is something of an integration test since it tests to make sure everything happens,
	// the whole way to the remoteManager making the correct request to the server to update
	// the remote data.

	TEST.mockAjax("success");

	var nameElement = $("#remoteList .remote .name").last();

	// Simulate a user editing the remote name
	nameElement.focus();
	nameElement.val(newName);
	nameElement.blur();

	// Make sure the resulting request has the correct data
	var opts = TEST.lastAjaxOptions;
	equals(opts.url, "/ajax");
	equals(opts.data.action, "update");

	var remoteData = $.parseJSON(opts.data.data);
	equals(remoteData.remotes.length, 2);
	var remote1 = remoteData.remotes[0];
	var remote2 = remoteData.remotes[1];
	equals(remote1.host, MENUTEST.inactiveHost);
	equals(remote1.name, MENUTEST.inactiveName);
	equals(remote1.port, 8080);
	equals(remote2.host, MENUTEST.activeHost);
	equals(remote2.name, newName);
	equals(remote2.port, 8080);
	equals(remoteData.active, 1);
});

test("should update active remote title on remote name update", function() {
	var menu = getTestRemoteMenu();
	menu.show();

	var newName = "New Name";

	// Just mock out the AJAX to prevent it from making the request
	TEST.mockAjax("success");

	var nameDisplay = $("#activeRemoteTitle");
	var menuNameElement = $("#remoteList .remote .name").last();

	menu.updateActiveRemoteTitle();

	equals(nameDisplay.text(), MENUTEST.activeName, "Has correct initial title");

	// Simulate a user editing the remote name
	menuNameElement.focus();
	menuNameElement.val(newName);
	menuNameElement.blur();

	equals(nameDisplay.text(), newName, "Has correct updated title");
});

test("should allow updating of active remote", function() {
	var menu = getTestRemoteMenu();
	menu.show();

	// Also tests integration with remoteManager and verifies request to the server to update
	// the remote data.
	TEST.mockAjax("success");

	equals(menu.getActiveRemote().host, MENUTEST.activeHost, "Has correct initial host");

	// Select the first remote to make it active
	$("#remoteMenu .activeRemoteRadio").first().change();

	equals(menu.getActiveRemote().host, MENUTEST.inactiveHost, "Has correct updated host");

	// Make sure the resulting request has the correct data
	var opts = TEST.lastAjaxOptions;
	equals(opts.url, "/ajax");
	equals(opts.data.action, "update");

	var remoteData = $.parseJSON(opts.data.data);
	equals(remoteData.remotes.length, 2);
	var remote1 = remoteData.remotes[0];
	var remote2 = remoteData.remotes[1];
	equals(remote1.host, MENUTEST.inactiveHost);
	equals(remote2.host, MENUTEST.activeHost);
	equals(remoteData.active, 0, "Correct new active index sent to server");
});

})();
