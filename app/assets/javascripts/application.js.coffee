#= require jquery
#= require jquery_ujs

#= require bootstrap

#= require plugins/_role
#= require plugins/_jquery.role
#= require plugins/_jquery.groupinputs

$(document).ready ->
  $("[data-toggle='modal']").on('click'
    (e) ->
      e.preventDefault()
      url = $(this).attr("href")
      if url.indexOf("#") is 0
        $(url).modal "open"
      else
        $.get(url, (data) ->
          $("<div class='modal' role='modal'>#{data}</div>").modal()
        ).success ->
          $('@modal').one('hidden'
            ->
              $(this).remove()
          )
          
          $("@modal input:text:visible:first").focus()
  )



