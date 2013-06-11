#= require jquery
#= require jquery_ujs

#= require bootstrap

#= require plugins/_role
#= require plugins/_jquery.role
#= require plugins/_jquery.groupinputs

#= require wiselinks

class Spaceship
  constructor: ->
    self = this

    self.initialize_modal($(document))
    self.initialize_close($(document))

    @content = $('@content')
    @preloader = $('@preloader')

    new Wiselinks(@content)

    $(document).off('page:loading').on('page:loading'
      (event, url, target, render) -> 
        self.content.addClass("translucent")
        self.preloader.show()
    )

    $(document).off('page:always').on('page:always'
      (event, $target, status, url) ->      
        self.content.removeClass("translucent")
        self.preloader.hide()
    )

    $(document).off('page:done').on('page:always'
      (event, $target, status, url, data) ->
        self.initialize_modal($target)
        self.initialize_close($target)
        if(typeof(_metrika) != 'undefined')     
          _metrika.hit(location.pathname)
    )

  initialize_modal: ($selector) ->
    $selector.find("[data-toggle='modal']").on('click'
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

  initialize_close: ($selector) ->
    $selector.find('.alert a@close').on('click',
      (e) ->
        e.preventDefault()
        $(this).closest(".alert").slideUp(
          (e) ->
            $(this).remove()
        )
    )  

$(document).ready ->
  new Spaceship()
  