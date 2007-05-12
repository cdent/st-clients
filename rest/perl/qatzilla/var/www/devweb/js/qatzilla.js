function addSidebar() {
    if ((typeof window.sidebar == "object") && (typeof window.sidebar.addPanel == "function")) {
	var sidebarname=window.location.host;
	if (!/bug/i.test(sidebarname)) {
	    sidebarname="Qatzilla Sidebar";
	}
	var loc = new String(document.location);
	loc = loc.replace(/http:\/\/([^/]+).*/,'http://$1/qatzilla/sidebar');
	window.sidebar.addPanel(sidebarname, loc, "");
    }
    else {
	var rv = window.confirm("Your browser does not support the sidebar extension.  " + 
	                        "Would you like to upgrade now?"
			       );
	if (rv) {
	    document.location.href = "http://www.mozilla.org/";
	}
    }
}

function set_state (id, state, block) {
    var bk_spn = document.getElementById('blocked_'+id);
    var bk_chk = document.getElementById('blocked_'+id+'_chk');
    if (!bk_spn) {
	throw new Error("blocked_" + id + " doesn't exist");
    }
    if (!bk_chk) {
	throw new Error("blocked_" + id + "_chk doesn't exist");
    }

    if (state.toLowerCase() == 'fail') {
	bk_spn.style.display = 'block'
	bk_chk.checked = block ? true : false;
    }
    else if (state.toLowerCase() == 'blocked') {
	bk_spn.style.display = 'block'
	bk_chk.checked = true;
    }
    else {
	bk_chk.checked = false;
	bk_spn.style.display = 'none'
    }

    if (bk_spn.style.display == 'block' && bk_chk.checked) {
	state = 'blocked';
    }
    document.getElementById(id).className = state;
}

function set_all (state) {
    var inputs = elementsHavingClass(document, 'tscheck');
    for (var i=0; i<inputs.length; i++) {
	if (inputs[i].value.toLowerCase() == state.toLowerCase()) {
	    inputs[i].checked = true;
	    inputs[i].onclick();
	}
    }
}

function change_testers () {
    var loc = new String(document.location);
    var inputs = elementsHavingClass(document, 'tester');

    loc = loc.replace(/&section_\d+=[^&]*/g,"");
    
    for (var i=0; i<inputs.length; i++) {
	var original = inputs[i].getAttribute('original') || inputs[i].original || "";
	var value = inputs[i].value || "";
	if (value != original) {
	    loc += "&section_" + inputs[i].name + "=" + value;
	}
    }
    document.location = loc;
}

function change_tester (tester) {
    if (!tester) {
	var inputs = elementsHaving(document, 'name', 'tester_filter');
	tester = inputs[0].value;
    }

    if (tester == 'all') {
	del_cookie('QatzillaUser');
    }
    else {
	set_cookie('QatzillaUser', tester);
    }
    window.location.reload();
}

function change_status () {
    var loc = new String(document.location);
    var inputs = elementsHaving(document, 'name', 'status_filter');
    loc = loc.replace(/&status_filter=[^&]*/g,"");
    loc += '&status_filter=' + inputs[0].value;
    document.location = loc;
}

function show_reports (product_id) {
    var reports = elementsHavingClass(document, 'reports');
    for (var i=0; i<reports.length; i++) {
	var product = reports[i].getAttribute('product') || reports[i].product;
	if (product == product_id) {
	    reports[i].style.display = 'block';
	}
	else {
	    reports[i].style.display = 'none';
	}
    }
}

function set_content (div,content) {
    div.innerHTML = '';
    var elem = document.createElement('pre');
    elem.setAttribute('class','wrapped');
    elem.innerHTML = content;
    div.appendChild(elem);
}

function moo_set_content (div,content) {
    if (div.style.opacity && div.fxOpacity) {
	var fcn = div.fxOpacity.options.onComplete;
	div.fxOpacity.options.onComplete = function () {
	    set_content(div, content);
	
	    div.fxOpacity.options.onComplete = function () {
		div.fxOpacity.options.onComplete = fcn;
	    };
	    div.fxOpacity.toggle();
	};
	div.fxOpacity.toggle();
	return;
    }

    set_content(div,content);

    div.fxHeight = new fx.Height(
	div.id,
	{ onComplete: function () { this.now && this.el.fxOpacity.toggle() }
	});
    div.fxOpacity = new fx.Opacity(
	div.id,
	{ onComplete: function () { this.now || this.el.fxHeight.toggle() }
	});

    div.fxHeight.hide();
    div.fxOpacity.hide();
   
    div.style.display = 'block';

    div.fxHeight.toggle();
}

function fetch_url (url, div, fetchOnce) {
    if (typeof(div) == 'string') {
	div = document.getElementById(div);
    }
    if (!div) {
	throw new Error("fetch_url takes a url and an id or div element");
    }

    if (fetchOnce && div.fxOpacity) {
	div.fxOpacity.now ? div.fxOpacity.toggle() : div.fxHeight.toggle();
	return;
    }

    var topost;
    var parts = url.split('?')
    url = parts[0];
    topost = parts[1];

    new ajax( url, {
	postBody : topost,
	onComplete: function (req) { 
	    moo_set_content(div,req.responseText) 
	}
    });
}

function fetch_test_case (tc_id) {
    var url = '/qatzilla/testsection?tc_id=' + tc_id;
    var ele = document.getElementById('content_' + tc_id);
    fetch_url(url,ele,true);
}

function fetch_test_section (section_id, div_id) {
    var url = '/qatzilla/testsection?section_id=' + section_id;
    fetch_url(url, div_id,true);
}

function delete_row () {
    var node = this;
    while (node = node.parentNode) {
	if (node.tagName.toLowerCase() == 'tr') {
	    node.parentNode.removeChild(node);
	    break;
	}
    }
}

function add_row () {
    var row = document.createElement('tr');
    for (var i=0; i<arguments.length; i++) {
	var cell = document.createElement('td');
	cell.innerHTML = arguments[i];
	row.appendChild(cell);
    }

    var node = this;
    while (node = node.parentNode) {
	if (node.tagName.toLowerCase() == 'tbody') {
	    node.appendChild(row);
	    return;
	}
    }
}
