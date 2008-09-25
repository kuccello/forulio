// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function merge_hash(hash1, hash2)
{
    var result = {};
    var addResult = function(pair) { result[pair.key] = pair.value; }
    $H(hash1).each(addResult);
    $H(hash2).each(addResult);
    return result;
}
var default_inplace_options = 
{
	okText: 'Save',
	savingText: 'Saving...<img src="/images/snake.gif" />',
  	size : 30,
  	onFailure: function(sender, transport) { alert(transport.responseText); },
}
var category_inplace_option = merge_hash(default_inplace_options, {highlightendcolor : '#DEE088'});
var topic_inplace_option = 	merge_hash(default_inplace_options, {highlightendcolor : '#DEE088'});

function show_loader(container_id, image ) 
{ 
	if (!image) image = 'snake';
	with($(container_id))
	{
		innerHTML = '<img src="/images/'+ image +'.gif" />';
		show();
	}
}
var Category = 
{
	cancelCreate:function() { new Effect.Fade('create_category') },
	remove:function(category_id) {
		var my_cat = $('cat_tr_' + category_id);
	   	var table = $('forulio');
	    for (var i = my_cat.rowIndex + 1; i < table.rows.length; i++) 
	    {
	        var id = table.rows[i].id;
			    if (id && id.startsWith('cat_tr_')) break;
	        $(table.rows[i]).remove();
	    }
	    FTableManager.Remove(my_cat);
	},
  insert:function(tr_content) {
    FTableManager.InsertRowContent('forulio', tr_content);
  },
	startRemoteTask:function(category_id){
		$('cat_tr_' + category_id).hoverObserverInstance.active = false;
		$('cat_tasks_content_' + category_id, 'cat_loader_' + category_id).invoke('toggle');
	},
	stopRemoteTask:function(category_id) {
		$('cat_tasks_content_' + category_id, 'cat_loader_' + category_id).invoke('toggle');
		with($('cat_tr_' + category_id).hoverObserverInstance)
		{
			hide();
			active = true;	
		}
	}
}
var Forum = 
{
	cancelEdit:function(id) {
		FTableManager.RollBackRowContent('forum_tr_' + id);
		$('forum_tasks_content_' + id, 'forum_loader_' + id).invoke('toggle');
		with(new Element.HoverObserver('forum_tr_' + id))
		{
			hide();
			active = true;
		}
	},
	insert:function(tr_content, category_id){
		var table = $('forulio');
		var my_cat = $('cat_tr_' + category_id);
		var options = {};
		for(var i = my_cat.rowIndex + 1; i < table.rows.length; i++)
		{
			var id = table.rows[i].id;
			if(id && id.startsWith('cat_tr_')) {
				options['beforeIndex'] = i;
				break;
			}
		}
		FTableManager.InsertRowContent('forulio', tr_content, options);
	},
  update:function(id, tr_content, do_backup){
    id = '' + id;
    client_id = id.match(/^\d+$/i) ? 'forum_tr_' + id : id;
    if (do_backup)
      FTableManager.UpdateRowContentWithBackup(client_id, tr_content);
    else
      FTableManager.UpdateRowContent(client_id, tr_content);      
  },
	startRemoteTask:function(forum_id){
		Element.HoverObserver.getInstance('forum_tr_' + forum_id).active = false;
		$('forum_tasks_content_' + forum_id, 'forum_loader_' + forum_id).invoke('toggle');
	},
	stopRemoteTask:function(forum_id) {
		$('forum_tasks_content_' + forum_id, 'forum_loader_' + forum_id).invoke('toggle');
		with(Element.HoverObserver.getInstance('forum_tr_' + forum_id))
		{
			hide();
			active = true;	
		}
	},
  remove:function(id) { FTableManager.Hide('forum_tr_' + id); }
}

var Post = 
{
	backupContent:function(id, force){
		var content_div = $('content_' + id);
		if(!content_div.__backupHTML || force){
			content_div.__backupHTML = content_div.innerHTML;
		}
	},
	restoreContent:function(id){
		var content_div = $('content_' + id);
		content_div.innerHTML = content_div.__backupHTML;
	
		var updated = $('post_updated_'+ id)
		if (updated) updated.hide();
	
		new Effect.Highlight(content_div, {duration:0.5});
	},
  insert:function(tr_content) {
    FTableManager.InsertRowContent('posts', tr_content);
  },
  delete_post:function(post_id){
     FTableManager.Hide('tr_post_' + post_id);
  },
  scrollTo:function(post_id) {
    setTimeout("Element.scrollTo('tr_post_" + post_id +"')", 1000)
  }
}

var Topic = 
{
	startRemoteTask:function(topic_id){
		Element.HoverObserver.getInstance('topic_tr_' + topic_id).active = false;
		$('topic_tasks_content_' + topic_id, 'topic_loader_' + topic_id).invoke('toggle');
	},
	stopRemoteTask:function(topic_id) {
		$('topic_tasks_content_' + topic_id, 'topic_loader_' + topic_id).invoke('toggle');
		with(Element.HoverObserver.getInstance('topic_tr_' + topic_id))
		{
			hide();
			active = true;	
		}
	},
	remove:function(topic_id) {
		var tr = $('topic_tr_' + topic_id);
		FTableManager.Remove(tr);
	},
  saveStickyTranslations:function(unstick_str, stick_str) {
    var obj = $('sticky_topic')
    if(!obj._stickyTrans) {
      obj._stickyTrans = [stick_str, unstick_str]
    }
  },
  setStickyText:function(sticky) {
    var obj = $('sticky_topic')
    obj.innerHTML = obj._stickyTrans[sticky];
  }
}

var Role = {
  assign: function(id, user_id){
    new Ajax.Request('/user/assign_role/' + id + '?user_id=' + user_id, {
      asynchronous: true,
      evalScripts: true,
      method: 'post',
      onLoading: $('role_' + id).replace('<img src="/images/snake.gif" />')
    });
  },
  unassign: function(id, user_id){
    new Ajax.Request('/user/unassign_role/' + id + '?user_id=' + user_id, {
      asynchronous: true,
      evalScripts: true,
      method: 'post',
      onLoading: $('role_' + id).replace('<img src="/images/snake.gif" />')
    });
  },
  new_role: function(user_id){
    var role = window.prompt('New role title:');
    if (role != null) {
      new Ajax.Request('/user/new_assign_role/?user_id=' + user_id + '&role=' + role, {
        asynchronous: true,
        evalScripts: true,
        method: 'post',
        onLoading: $('new_role_box').innerHTML = '<img src="/images/snake.gif" />',
        onFailure: function(t){
          alert(t.responseText)
        },
        onSuccess: setTimeout(function(){
          $('new_role_box').innerHTML = '&nbsp;&nbsp;'
        }, 200)
      });
    }
  },
  remove:function(obj, id, confirmMessage){
     if (confirm(confirmMessage)){
       new Ajax.Request('/user/remove_role/' + id, {
        asynchronous: true,
        evalScripts: true,
        method: 'post',
        onLoading: $(obj).replace('<img src="/images/snake.gif" />')
      });  
     }
  }
}
var Tag = {
  
  edit:function(id, tr_content) {
    FTableManager.UpdateRowContentWithBackup('tag_' + id, tr_content);
  },
  update:function(id, tr_content) {
    FTableManager.UpdateRowContent('tag_' + id, tr_content);
  },
  cancelEdit:function(id) {
		FTableManager.RollBackRowContent('tag_' + id);
    $$('#tag_' + id +' td').last().select('img', 'span').invoke('toggle');
	},
  startRemoteGridTask:function(id){
		$$('#tag_' + id +' td').last().select('img', 'span').invoke('toggle');
	},
  startRemoteEditTask:function(id){
		show_loader($$('#tag_' + id +' td table tr').last().select('td').last(), 'loader2')
	},
  remove:function(id) {
     FTableManager.Remove($('tag_' + id));
  }
  
}
var TimeZone = 
{
	addZeros:function(value)
	{
		var res = "00" + value;
		return res.substr(res.length - 2);
	},
	summerTime:function()
	{
		var date = new Date();
		var t_date_val = date.valueOf() - date.valueOf() % 86400000;
		
		var from = new Date(t_date_val);
		from.setMonth(2);
		from.setDate(21);
		from.setHours(3);
		
		var until = new Date(t_date_val);
		until.setMonth(8);
		until.setDate(22);
		until.setHours(3);
		
		return (date >= from && date <= until);
	},
	findDefault : function(id)
	{
		var element = $(id);
		var offset = new Date().getTimezoneOffset();
		if(this.summerTime()) offset += 60;
		var props = {
			sign : offset < 0 ? '+' : '-',
			hours : this.addZeros(Math.abs(parseInt(offset / 60))),
			minutes : this.addZeros(offset % 60)
		};
		var strOffset = "(GMT#{sign}#{hours}:#{minutes})".interpolate(props);
		var from = -1;
		var until = -1;
		for (var i = 0; i < element.options.length; i++)
		{
			if(element.options[i].text.startsWith(strOffset)) if(from == -1) from = i; else until = i;
			else if(until != -1) break;

		}
		if(from >= 0 && until >= from) element.selectedIndex = parseInt((from + until) / 2);
	}
}











