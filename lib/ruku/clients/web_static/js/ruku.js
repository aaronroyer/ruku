function RUKU() {}

/**
 * Creates a remote for a particular box. Calling various methods corresponding to remote
 * commands (i.e. up(), pause(), home()) will make an AJAX request resulting in the command
 * being sent to the box with the same IP/hostname as the object.
 *
 * Initialize with an object with the following properties: host, name, port (optional)
 */
RUKU.createRemote = function(data) {
	var remote = {
		host: data.host,
		name: data.name,
		port: data.port || 8080
	};

	// Add methods to our object, for each of the remote commands, that will make AJAX requests
	// resulting in the server sending the corresponding remote command to the Roku box with
	// this remote's IP/hostname.
	var commands = ["home", "up", "down", "left", "right", "select", "pause", "back", "fwd"];
	for (var i = 0; i < commands.length; i++) {
		var cmd = commands[i];
		remote[cmd] = function(theCmd) {
			return function() {
				$.ajax({url:"/ajax", data:{command:theCmd, host:data.host}, success:function(resp) {
					console.log("Successfully sent command: " + cmd);
				}, error:function() {
					console.log("Error on command: " + cmd);
				}});
			};
		}(cmd);
	}
	return remote;
};

/**
 * Creates objects that manage a collection of remote objects. Keeps track of which remote
 * is the active one, which is the one that commands are to be sent to with the remote interface.
 *
 * Initialize with with an object with a remotes property that is an Array of objects suitable
 * for initializing remote objects and an optional active property that contains the index,
 * in the remotes Array, of the active remote.
 */
RUKU.createRemoteManager = function(data) {
	var processed = {};

	/**
	 * Loads data into the remoteManager from an object as described in the createRemoteManager
	 * top level docs.
	 */
	function loadData(remoteData) {
		this.remotes = [];
		this.activeIndex = 0;
		if (remoteData) {
			for (var i = 0; i < remoteData.remotes.length; i++) {
				this.remotes.push(RUKU.createRemote(remoteData.remotes[i]));
			}
			this.activeIndex = remoteData.active || 0;
		}
	}

	loadData.call(processed, data);

	/**
	 * Loads the remoteManager with data from the server.
	 */
	function load(callback) {
		var that = this;
		$.ajax({url:"/ajax", dataType:"json", data:{action:"list"}, success:function(data) {
			that.loadData(data);
			if (callback) {
				callback();
			}
		}});
	}

	/**
	 * Sends the data contained in the remoteManager back to the server for saving.
	 */
	function save(callback) {
		// Just hack together the JSON this one time...
		var json = "{\"remotes\":[";
		for (var i = 0; i < this.remotes.length; i++) {
			var remote = this.remotes[i];
			json = json + "{\"host\":\"" + remote.host + "\",\"name\":\"" + remote.name +
				"\",\"port\":\"" + remote.port + "\"}";
			if (i !== (this.remotes.length - 1)) {
				json = json + ",";
			}
		}
		json = json + "],\"active\":" + this.activeIndex + "}";

		$.ajax({url:"/ajax", data:{action:"update", data:json}, success:function(resp) {
			console.log(resp);
			if (callback) {
				callback();
			}
		}});
	}

	/**
	 * Returns the active remote or null if there are no remotes.
	 */
	function getActive() {
		var activeRemote = null;
		if (this.remotes.length > 0 && this.activeIndex < this.remotes.length) {
			activeRemote = this.remotes[this.activeIndex];
		}
		return activeRemote;
	}

	/**
	 * Makes the given remote the active remote. Also accepts a String that is the new active remote's
	 * IP/hostname. If the remoteManager does not know about a remote with the given hostname then this
	 * is ignored.
	 */
	function setActive(newActive) {
		var that = this;
		var newHost = (newActive && newActive.host) ?
			newActive.host : (typeof newActive === 'string') ? newActive : null;
		if (newHost) {
			$.each(this.remotes, function(index, remote) {
				if (remote.host === newHost) {
					that.activeIndex = index;
					that.save();
					return false;
				}
			});
		}
	}

	function scanForFirst(callback) {
		var that = this;
		$.ajax({url:"/ajax", dataType:"json", data:{action:"scanForFirst"}, success:function(data) {
			that.loadData(data);
			if (callback) {
				callback();
			}
		}});
	}

	function scanForAll(callback) {
		var that = this;
		$.ajax({url:"/ajax", dataType:"json", data:{action:"scanForAll"}, success:function(data) {
			that.loadData(data);
			if (callback) {
				callback();
			}
		}});
	}

	return {
		remotes: processed.remotes,
		activeIndex: processed.activeIndex,
		loadData:loadData,
		getActive:getActive,
		setActive:setActive,
		load:load,
		save:save,
		scanForFirst:scanForFirst,
		scanForAll:scanForAll
	};
};

/**
 * Creates an interface for managing remotes. The first parameter is a (jQuery wrapped) element
 * that holds the main interface components. The second is an element containing the title for
 * the active remote that needs to be updated when the active remote changes. The third parameter
 * is the remoteManager to use for remote related operations.
 */
RUKU.createRemoteMenu = function(remoteMenu, activeRemoteTitle, remoteManagerToUse) {
	var remoteManager = remoteManagerToUse || RUKU.createRemoteManager();
	var container = remoteMenu.parent();
	var remoteList = remoteMenu.find("#remoteList");
	var firstBoxInfo = container.find("#firstBoxInfo");

	/** Set the remoteManager for the menu to use for its remote operations */
	function setRemoteManager(rm) {
		remoteManager = rm;
	}

	/** Get the remote that is active according to the remoteManager */
	function getActiveRemote() {
		return remoteManager.getActive();
	}

	/** Returns true if there is at least one remote managed by the remoteManager */
	function hasRemotes() {
		return remoteManager &&
			remoteManager.remotes &&
			remoteManager.remotes.length > 0;
	}

	/** Updates the text of the activeRemoteTitle element */
	function updateActiveRemoteTitle() {
		var activeRemote;
		if (remoteManager) {
			activeRemote = remoteManager.getActive();
		}
		if (activeRemote) {
			var name = ($.trim(activeRemote.name)) === "" ? "(Box with no name)" : activeRemote.name;
			activeRemoteTitle.text(name);
			var altText = name + " (" + activeRemote.host + ")";
			activeRemoteTitle.attr("alt", altText);
			activeRemoteTitle.attr("title", altText);
		} else {
			var text = "(Must set up remote)";
			activeRemoteTitle.text(text);
			activeRemoteTitle.attr("alt", text);
			activeRemoteTitle.attr("title", text);
		}
	}

	/** Scan for all remotes on the network and show the results */
	function scanForAll() {
		remoteManager.scanForAll(function() {
			updateActiveRemoteTitle();
			show();
		});
	}

	/**
	 * Scan for the first remote found on the network (the common case is one remote)
	 * and show display the result
	 */
	function scanForFirst() {
		remoteManager.scanForFirst(function() {
			updateActiveRemoteTitle();
			remoteList.css("display", "none");
			firstBoxInfo.empty();
			if (hasRemotes()) {
				firstBoxInfo
					.append($("<div>").addClass("message").text("One box found"))
					.append($("<div>").addClass("boxInfo")
						.append($("<img>").attr("src", "/images/box-medium.png"))
						.append(
							$("<div>").addClass("details")
								.append($("<div>").addClass("name").text(getActiveRemote().name))
								.append($("<div>").addClass("host").text(getActiveRemote().host))
						)
					)
					.append(
						$("<div>").addClass("menu")
							.append($("<a>").addClass("buttonLink").addClass("doneButton")
								.text("this is my only box").attr("href", "#")
								.click(function() {
									hide();
									return false;
								}))
							.append($("<a>").addClass("buttonLink").addClass("moreButton")
								.text("scan for more boxes").attr("href", "#")
								.click(function() {
									scanForAll();
									return false;
								}))
					);
			} else {
				firstBoxInfo.text("Didn't find anything");
			}
			firstBoxInfo.css("display", "block");
		});
	}

	function addRemote(host, name) {
		if (host === "") {
			return;
		}
		if (!name) {
			if (remoteManager.remotes.length === 0) {
				name = "My Roku Box";
			} else {
				name = host;
			}
		}
		remoteManager.remotes.push({host:host, name:name});
		remoteManager.save(function() {
			show();
		});
	}

	/**
	 * Updates the name of the remote with the given hostname and causes the remoteManager to save
	 * the data to the server if the name has changed.
	 */
	function updateRemoteName(remoteHost, remoteName) {
		var changed = false;

		for (var i = 0; i < remoteManager.remotes.length; i++) {
			var remote = remoteManager.remotes[i];
			if (remote.host === remoteHost) {
				if (remote.name !== remoteName) {
					remote.name = remoteName;
					changed = true;
				}
				break;
			}
		}

		if (changed) {
			remoteManager.save();
			updateActiveRemoteTitle();
		}
	}

	/**
	 * Changes the active remote to the one with the given hostname. If there are no remotes with the
	 * given hostname then there is no effect.
	 */
	function changeActiveRemote (newActiveRemoteHost) {
		$.each(remoteManager.remotes, function(index, remote) {
			if (remote.host === newActiveRemoteHost) {
				remoteManager.setActive(remote);
				updateActiveRemoteTitle();
				return false;
			}
		});
	}

	/** Render a list of available remotes */
	function show() {
		remoteList.empty();
		if (hasRemotes()) {
			for (var i=0; i < remoteManager.remotes.length; i++) {
				var remote = remoteManager.remotes[i];
				var boxDiv = $("<div>").addClass("remote")
					.append($("<div>")
						.append($("<input>").addClass("activeRemoteRadio").attr("type", "radio")
							.attr("name", "activeRemote").val(remote.host))
							.change(function(host) {
									return function() {
										changeActiveRemote(host);
									};
								}(remote.host)
							)
					)
					.append($("<div>").append($("<img>").addClass("boxPic").attr("src", "/images/box-small.png")))
					.append($("<div>").addClass("info")
						.append($("<input>").addClass("name")
							.attr("type", "text").val(remote.name || "(no name)")
							// Add the ability to edit the name of a remote by clicking on it and typing
							.hover(function() { $(this).addClass("over"); }, function() { $(this).removeClass("over"); })
							.blur(function(host) {
								return function() {
									updateRemoteName(host, $(this).val());
								};
							}(remote.host))
							.keypress(function() {
								// Make the Return key complete the name edit
								if (event.which == '13') {
									event.preventDefault();
									$(this).blur();
									$(this).removeClass("over");
								}
							}))
						.append($("<div>").addClass("host").text(remote.host))
					);

				if (i === remoteManager.activeIndex) {
					boxDiv.addClass("active");
					boxDiv.find(".activeRemoteRadio").attr("checked", true);
				}
				remoteList.append(boxDiv);
			}
		} else {
			remoteList.append(
				$("<div>").addClass("noRemotesMessage")
					.html(
						"No remotes have been set up yet. Click the <b>scan for boxes</b> button above " +
						"to find remotes on your network. If you know the IP address or hostname of your " +
						"box you can add it below instead."
					)
			);
		}

		remoteList.append(
			$("<div>").attr("id", "manualAddBox")
				.append("Add a box by IP: ")
				.append($("<input>").attr("type", "text").attr("id", "manualAddBoxInput"))
				.append($("<a>").addClass("buttonLink").text("Add")
					.click(function() {
						addRemote($("#manualAddBoxInput").val());
					})
				)
		);

		container.css("display", "block");
		remoteList.css("display", "block");
		firstBoxInfo.css("display", "none");
		remoteMenu.fadeIn();
	}

	/**
	 * Loads remote data from the server. If no remotes are found this displays
	 * a 'no remotes' message to the user.
	 */
	function load() {
		remoteManager.load(function() {
			updateActiveRemoteTitle();
			if (!hasRemotes()) {
				// Since we cannot do anything without remotes, go ahead and call the show() method which
				// will display the 'no remotes' message in this case.
				show();
			}
		});
	}

	/** Hide the menu */
	function hide() {
		remoteMenu.fadeOut("fast", function() {
			container.css("display", "none");
		});
	}

	function listRemotes() {
		if (hasRemotes()) {
			// We already have some remotes. Just display them.
			show();
		} else {
			remoteManager.load(function() {
				updateActiveRemoteTitle();
				show();
			});
		}
	}

	remoteMenu.find("#closeButton").click(function() {
		hide();
		return false;
	});

	remoteMenu.find("#scanButton").click(function() {
		scanForFirst();
		return false;
	});

	return {
		remoteManager:remoteManager,
		setRemoteManager:setRemoteManager,
		getActiveRemote:getActiveRemote,
		hasRemotes:hasRemotes,
		load:load,
		show:show,
		hide:hide,
		listRemotes:listRemotes,
		updateActiveRemoteTitle:updateActiveRemoteTitle
	};
};
