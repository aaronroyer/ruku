function TEST() {}

TEST.lastAjaxOptions;
TEST.mockAjax = function(response, error) {
	TEST.lastAjaxOptions = null;

	jQuery.ajax = function(opts) {
		TEST.lastAjaxOptions = opts;
		if (!error) {
			opts["success"](response);
		} else {
			opts["error"](response);
		}
	};
};
