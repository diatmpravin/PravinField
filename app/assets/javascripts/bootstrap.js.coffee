jQuery ->
  $("a[rel=popover]").popover()
  $(".tooltip").tooltip()
  $("a[rel=tooltip]").tooltip()

# i is the id of the element, s is the style (class), and notice is the message
showNotice = (i, notice) ->
  if (notice == '')
    return
  else
    hideNotices()
    x = "<button class='close' data-dismiss='alert'>x</button>"
    s = 'alert'
    if (i=='flashnotices')
      s = s + ' alert-success'
    else if(i=='flashalerts')
      s = s + ' alert-error'
    if($('#'+i).length==0)
  	  $('#myModal').before("<div class='"+s+"' id='"+i+"'>"+x+notice+"</div>")
    else
  	  $('#'+i).html(x+notice).show()
  $(".alert").alert()
window.showNotice = showNotice

hideNotices = () ->
  $('#flasherrors').hide()
  $('#flashnotices').hide()
  $('#flashalerts').hide()