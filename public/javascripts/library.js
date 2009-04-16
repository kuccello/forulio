var FTableManager = {
	UpdateAttributes : function(to, from) {
		if (from.id)
			to.id = from.id;
		if (from.vAlign)
			to.vAlign = from.vAlign;
		if (from.align)
			to.align = from.align;
		if (from.colSpan)
			to.colSpan = from.colSpan;
		if (from.className)
			to.className = from.className;
		if (from.style.backgroundColor)
			to.style.backgroundColor = from.style.backgroundColor;
	},
	Update : function(to, from) {
		Element.update(to, from.innerHTML);
		this.UpdateAttributes(to, from);
	},
	UpdateRowContent : function(rowElement, tr_content) {
		// Create Object
		var div = document.createElement('div');
		Element.update(div, '<table>' + tr_content + '</table>')
		var tr = div.firstChild.rows[0];

		rowElement = $(rowElement);
		while (rowElement.cells.length)
			rowElement.deleteCell(0);
		for (var i = 0; i < tr.cells.length; i++)
			this.Update(rowElement.insertCell(rowElement.cells.length),
					tr.cells[i]);

		div.innerHTML = "";
		this.UpdateAttributes(rowElement, tr);
		this.Show(rowElement);
	},
	UpdateRowContentWithBackup : function(rowElement, tr_content) {
		rowElement = $(rowElement);
		rowElement.__backupInnerHTML = rowElement.innerHTML;
		this.UpdateRowContent(rowElement, tr_content);
	},
	RollBackRowContent : function(rowElement) {
		rowElement = $(rowElement);
		if (rowElement.__backupInnerHTML)
			this.UpdateRowContent(rowElement, "<tr>"
					+ rowElement.__backupInnerHTML + "</tr>");

	},
	InsertRowContent : function(table_id, tr_content, options) {
		var table = $(table_id);
		var index = null;

		if (options) {
			if (options["before"])
				index = $(options["before"]).rowIndex;
			else if (options["after"])
				index = $(options["after"]).rowIndex + 1;
			else if (options["beforeIndex"])
				index = options["beforeIndex"];
			else if (options["afterIndex"])
				index = options["afterIndex"] + 1;
		}
		if (!index)
			index = table.rows.length;

		var new_tr = table.insertRow(index);
		$(new_tr).hide();
		this.UpdateRowContent(new_tr, tr_content);
	},
	Hide : function(rowElement) {
		var element = $(rowElement);
		new Effect.Parallel([new Effect.Highlight(element.id, {
			startcolor : '#ffffff',
			endcolor : '#ff0000',
			duration : 0.5
		}), new Effect.Fade(element.id, {
			duration : 0.5
		})]);
	},
	Remove : function(rowElement) {
		var element = $(rowElement);
		new Effect.Parallel([new Effect.Highlight(element.id, {
			startcolor : '#ffffff',
			endcolor : '#ff0000',
			duration : 0.5
		}), new Effect.Fade(element.id, {
			duration : 0.5
		})], {
			afterFinish : function() {
				element.remove();
			}
		});
	},
	Show : function(rowElement) {
		var element = $(rowElement);
		new Effect.Parallel([new Effect.Appear(element),
				new Effect.Highlight(element)]);
	}
}

Element.HoverObserver = Class.create();
Element.HoverObserver.getInstance = function(element) {
	var element = $(element);
	if (element.hoverObserverInstance)
		return element.hoverObserverInstance;
	else
		return new Element.HoverObserver(element)
}
Element.HoverObserver.controls = [];
Element.HoverObserver.loaded = false;
Element.HoverObserver.process = function() {
	var controls = Element.HoverObserver.controls;
	for (var i = 0; i < controls.length; i++) {
		document.body.appendChild(controls[i].hintElement);
	}
	Element.HoverObserver.controls = [];
	Element.HoverObserver.loaded = true;
}
Element.HoverObserver.prototype = {
	initialize : function(element) {
		this.element = $(element);
		var hint = this.element.select('.hover_task').first();
		if (!hint)
			return;
		this.active = true;
		this.element.hoverObserverInstance = this;
		this.hintElement = document.createElement('div');
		$(this.hintElement).setStyle({
			position : 'absolute',
			display : 'none'
		});
		this.hintElement.innerHTML = hint.innerHTML;

		hint.remove();
		if(!Element.HoverObserver.loaded)
			Element.HoverObserver.controls.push(this);
		else
			document.body.appendChild(this.hintElement);
		
		this.registerCallbackHandler = this.registerCallback.bind(this);
		this.cancelCallbackHandler = this.cancelCallback.bind(this);
		Event.observe(this.element, 'mouseover', this.registerCallbackHandler);
		Event.observe(this.element, 'mouseout', this.cancelCallbackHandler);
	},
	registerCallback : function(event) {
		if (!this.active)
			return;
		if (this.timer)
			clearTimeout(this.timer);
		this.timer = setTimeout(this.show.bind(this), 100);
	},
	cancelCallback : function(event) {
		if (!this.active)
			return;
		if (this.timer)
			clearTimeout(this.timer);
		this.timer = setTimeout(this.hide.bind(this), 1000);
	},
	show : function() {
		var size = Element.getDimensions(this.element);
		var pos = Element.cumulativeOffset(this.element);
		var hintSize = Element.getDimensions(this.hintElement);
		this.hintElement.setStyle({
					left : pos[0] + (size.width + 10) + "px",
					top : pos[1] + ((size.height - hintSize.height) / 2) + "px"
				});
		this.hintElement.show();
	},
	hide : function() {
		this.hintElement.hide();
	},
	remove : function() {
		Event.stopObserving(this.element, 'mouseover', this.registerCallbackHandler);
		Event.stopObserving(this.element, 'mouseout', this.cancelCallbackHandler);
		this.hintElement.remove();
	}

}

document.observe("dom:loaded", function() {
	Element.HoverObserver.process();
});
