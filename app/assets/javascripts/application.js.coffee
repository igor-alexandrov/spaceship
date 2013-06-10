#= require jquery
#= require jquery_ujs

#= require bootstrap

#= require plugins/_role
#= require plugins/_jquery.role
#= require plugins/_jquery.groupinputs

#= require wiselinks

$(document).ready ->
  fetch_modal()

  @content = $('@content')
  @preloader = $('@preloader')

  @wiselinks = new Wiselinks(@content)

  $(document).off('page:loading').on(
    'page:loading'
    (event, url, target, render) -> 
      @content.addClass("translucent")
      @preloader.show()
    )

  $(document).off('page:always').on(
    'page:always'
    (event, $target, status) ->
      fetch_modal()
      @content.removeClass("translucent")
      @preloader.hide()
    )

fetch_modal = ->
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