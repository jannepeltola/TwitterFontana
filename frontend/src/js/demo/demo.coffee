# Bootswatch stylesheets
styles =
    Bootstrap:
        stylesheet: ""
        description: "Default style"
    Amelia:
        stylesheet: "/bootswatch/amelia/bootstrap.min.css"
        description: "Sweet and cheery"
    Cerulean:
        stylesheet: "/bootswatch/cerulean/bootstrap.min.css"
        description: "A calm blue sky"
    Cosmo:
        stylesheet: "/bootswatch/cosmo/bootstrap.min.css"
        description: "An ode to Metro"
    Cyborg:
        stylesheet: "/bootswatch/cyborg/bootstrap.min.css"
        description: "Jet black and electric blue"
    Flatly:
        stylesheet: "/bootswatch/flatly/bootstrap.min.css"
        description: "Flat and modern"
    Journal:
        stylesheet: "/bootswatch/journal/bootstrap.min.css"
        description: "Crisp like a new sheet of paper"
    Readable:
        stylesheet: "/bootswatch/readable/bootstrap.min.css"
        description: "Optimized for legibility"
    Simplex:
        stylesheet: "/bootswatch/simplex/bootstrap.min.css"
        description: "Mini and minimalist"
    Slate:
        stylesheet: "/bootswatch/slate/bootstrap.min.css"
        description: "Shades of gunmetal gray"
    Spacelab:
        stylesheet: "/bootswatch/spacelab/bootstrap.min.css"
        description: "Silvery and sleek"
    United:
        stylesheet: "/bootswatch/united/bootstrap.min.css"
        description: "Ubuntu orange and unique font"

transitions =
    'Scroll-Down': 'scroll-down'
    'Scroll-Up': 'scroll-up'
    'Lightspeed': 'lightspeed'
    'Hinge': 'hinge'

# Tying things together to make the demo page work
$ ->
    controls = $("#controls")
    signIn = $("#signin")
    signOut = $("#signout")
    auth = new Fontana.TwitterAuth()
    container = $(".fontana")
    visualizer = null
    settings = null

    fetchSettings = ->
        $.get("/pop/settings.html", now: (new Date()).getTime()).success (data) ->
            settings = $(data)
            settings.css(
                position: "absolute"
                top: "40px"
                left: 0
            )
            $('form', settings).submit (e) ->
                e.preventDefault()
                return false
            $('.close', settings).click () ->
                settings.hide()
            rigSearchBox(settings)
            rigStyleSwitch(settings)
            rigTransitionSwitch(settings)
            settings.appendTo(document.body)

    rigSearchBox = (settings)->
        input = $("#search", settings)
        if $(document.body).hasClass("signedIn")
            input.attr("disabled", false)
            input.keypress (e) ->
                if(e.which == 13)
                    e.preventDefault()
                    input.change()
                    return false
            input.change ->
                q = $("#search", settings).val()
                if q && q != visualizer.datasource.q
                    twitterFontana(transition: $("#transition", settings).val(),
                                   $("#search", settings).val())
        else
            input.attr("disabled", true)

    rigStyleSwitch = (settings)->
        select = $("#bootswatch", settings)
        Object.keys(styles).forEach (key) ->
            style = styles[key]
            select.append("<option value='#{style.stylesheet}'>#{key} &mdash; #{style.description}</option>")
        select.change (e)->
            $("link.bootswatch", document.head).remove()
            stylesheet = $(e.target).val()
            if stylesheet
                $("<link rel='stylesheet' href='#{stylesheet}' class='bootswatch'>").insertAfter($('link.bootstrap'))

    rigTransitionSwitch = (settings)->
        select = $("#transition", settings)
        Object.keys(transitions).forEach (key) ->
            transition = transitions[key]
            select.append("<option value='#{transition}'>#{key}</option>")
        select.change (e)->
            transition = $(e.target).val()
            visualizer.pause()
            visualizer.config(transition: transition)
            visualizer.resume()

    # Toggles
    toggleSettings = ->
        if !settings
            fetchSettings()
        else
            settings.toggle()

    toggleViz = ->
        icon = $(".glyphicon", this)
        if visualizer.paused
            icon.removeClass("glyphicon-play")
            icon.addClass("glyphicon-pause")
            visualizer.resume()
        else
            icon.removeClass("glyphicon-pause")
            icon.addClass("glyphicon-play")
            visualizer.pause()

    toggleFullscreen = ->
        if Fontana.utils.isFullScreen()
            Fontana.utils.cancelFullScreen()
        else
            Fontana.utils.requestFullScreen(document.body)

    # Auth
    checkSession = ->
        auth.activeSession (data)->
            if (data)
                isSignedIn(data)
            else
                isSignedOut()

    isSignedIn = (data)->
        $(document.body).addClass('signedIn')
        userText = $(".navbar-text", signOut)
        userText.html(nano(userText.data("text"), data))
        signIn.addClass("hidden")
        signOut.removeClass("hidden")
        if settings
            rigSearchBox(settings)
            twitterFontana(transition: $("#transition", settings).val(),
                           $("#search", settings).val())
        else
            twitterFontana()

    isSignedOut = ->
        $(document.body).removeClass('signedIn')
        signIn.removeClass("hidden")
        signOut.addClass("hidden")
        if settings
            rigSearchBox(settings)
            HTMLFontana(transition: $("#transition", settings).val())
        else
            HTMLFontana()

    # Two Demo Fontanas
    twitterFontana = (settings={}, q="TwitterFontana")->
        if visualizer
            visualizer.stop()
        datasource = new Fontana.datasources.TwitterSearch(q)
        visualizer = new Fontana.Visualizer(container, datasource)
        visualizer.start(settings)

    HTMLFontana = (settings={})->
        if visualizer
            visualizer.stop()
        visualizer = new Fontana.Visualizer(container, HTMLFontana.datasource)
        visualizer.start(settings)
    # Prepare our datasource, the messages will disappear soon...
    HTMLFontana.datasource = new Fontana.datasources.HTML(container)
    HTMLFontana.datasource.getMessages()

    # Bindings
    $(".settings", controls).click -> toggleSettings.call(this)
    $(".pause-resume", controls).click -> toggleViz.call(this)
    $(".fullscreen", controls).click -> toggleFullscreen.call(this)
    $("button", signIn).click -> auth.signIn(checkSession)
    $("button", signOut).click -> auth.signOut(checkSession)

    checkSession()
