p = (message) -> console.log(message)

HTMLElement.prototype.addClass = (className) ->
    classes = this.className?.split(' ')
    return unless classes

    index = classes.indexOf(className)

    if index == -1
        classes.push(className)
        this.className = classes.join(' ')

    return this

HTMLElement.prototype.removeClass = (className) ->
    classes = this.className?.split(' ')
    return unless classes

    index = classes.indexOf(className)

    if index != -1
        classes.splice(index, 1)
        this.className = classes.join(' ')

    return this

STATE =
    NORMAL:   1
    HIDDEN:   2
    SELECTED: 4

DIRECTION =
    NEXT: 1
    PREV: -1

class Item
    doc:     null
    tab:     null
    element: null
    state:   null

    callbacks:
        click:     () ->
        mouseover: () ->

    constructor: (@doc, @tab) ->
        @state = STATE.NORMAL

        @element = @_createElement()

        @element.addEventListener 'click', (event) =>
            @callbacks.click(this)
        , false

        @element.addEventListener 'mouseover', (event) =>
            @callbacks.mouseover(this)
        , false

        this.select(no)
        this.show(yes)

    _createElement: () ->
        template = @doc.getElementById('item-template').innerHTML
        template = template.replace('{title}', @tab.title)
        template = template.replace('{url}', @tab.url)

        dummy           = @doc.createElement('dummy')
        dummy.innerHTML = template

        return dummy.getElementsByTagName('li')[0]

    source: () ->
        return [@tab.title, @tab.url].join(',')

    select: (yesNo) ->
        if yesNo is yes
            @state = STATE.SELECTED
            @element.addClass('selected')
        else
            @state = STATE.NORMAL if @state is STATE.SELECTED
            @element.removeClass('selected')

    show: (yesNo) ->
        if yesNo is yes
            @state = STATE.NORMAL if @state is STATE.HIDDEN
            @element.removeClass('hidden')
        else
            @state = STATE.HIDDEN
            @element.addClass('hidden')

    onClick: (callback) ->
        @callbacks.click = callback

    onMouseover: (callback) ->
        @callbacks.mouseover = callback

class List
    doc:     null
    element: null
    items:   []

    constructor: (@doc, @element) ->

    addItem: (item) ->
        @items.push(item)

        item.onClick     (that) => @selectOne(that); @activate()
        item.onMouseover (that) => @selectOne(that)

    itemsByState: (state) ->
        return (item for item in @items when item.state & state)

    selectedItem: () ->
        items = @itemsByState(STATE.SELECTED)
        return if items?.length then items[0] else undefined

    clear: () ->
        @element.innerHTML = ''

    refresh: () ->
        @clear()

        # 選択されているものがなければ先頭のアイテムを選択
        unless @selectedItem()
            @itemsByState(STATE.NORMAL|STATE.SELECTED)[0]?.select(yes)

        for item in @items
            @element.appendChild(item.element)

    filter: (text) ->
        patterns = text.split(/\s+/).map (word) ->
            return new RegExp(word, 'i')

        for item in @items
            flag = yes

            for pattern in patterns
                flag = no unless item.source().match pattern

            if flag is yes
                item.show(yes)
            else
                item.show(no)

        @refresh()

    activate: () ->
        selected = @selectedItem()
        chrome.tabs.update(selected.tab.id, { selected: true })

    selectNext: (direction) ->
        selected = @selectedItem()
        items    = @itemsByState(STATE.NORMAL|STATE.SELECTED)
        index    = items.indexOf(selected)
        index    = 0 if index == -1

        # 指定方向のアイテムを選択
        # 指定方向にアイテムがなければリストをループして
        # 逆サイドのアイテムを選択
        if direction < 0
            if 0 < index then --index else index = items.length - 1
        else
            if index < items.length - 1 then ++index else index = 0

        @selectOne(@items[@items.indexOf(items[index])])

    selectOne: (selected) ->
        @items.forEach (item) ->
            item.select(item is selected)

class KeyHandler
    element: null

    callbacks:
        enter:      () ->
        esc:        () ->
        selectPrev: () ->
        selectNext: () ->
        others:     () ->

    modifiers:
        ctrl:  off
        shift: off
        alt:   off
        meta:  off

    constructor: (@element) ->
        @element.addEventListener 'keydown', (event) =>
            this._onKeyDown(event)

        @element.addEventListener 'keyup', (event) =>
            this._onKeyUp(event)

    _onKeyUp: (event) ->
        if @_isEnter(event.which)
            @callbacks.enter(event)
        else if @_isEsc(event.which)
            @callbacks.esc(event)
        else if @_isSelectPrev(event.which)
            @callbacks.selectPrev(event)
        else if @_isSelectNext(event.which)
            @callbacks.selectNext(event)
        else
            @callbacks.others(event)

        @_updateModifier(event)

    _onKeyDown: (event) ->
        @_updateModifier(event)

    _updateModifier: (event) ->
        @modifiers.ctrl  = event.ctrlKey
        @modifiers.shift = event.shiftKey
        @modifiers.alt   = event.altKey
        @modifiers.meta  = event.metaKey

    _isEnter: (keycode) ->
        return (@modifiers.ctrl and keycode == 74) or # Ctrl + j
               (@modifiers.ctrl and keycode == 77) or # Ctrl + m
                                   (keycode == 13);   # Enter

    _isEsc: (keycode) ->
        return (@modifiers.ctrl and keycode == 71) or # Ctrl + g
                                   (keycode == 27)    # Esc

    _isSelectPrev: (keycode) ->
        return (@modifiers.ctrl and keycode == 80) or # Ctrl + p
                                   (keycode == 38)    # Up

    _isSelectNext: (keycode) ->
        return (@modifiers.ctrl and keycode == 78) or # Ctrl + n
                                   (keycode == 40)    # Down

    onEnter: (callback) ->
        @callbacks.enter = callback

    onEsc: (callback) ->
        @callbacks.esc = callback

    onSelectPrev: (callback) ->
        @callbacks.selectPrev = callback

    onSelectNext: (callback) ->
        @callbacks.selectNext = callback

    onOthers: (callback) ->
        @callbacks.others = callback

window.addEventListener 'load', () ->
    doc          = window.document;
    inputElement = doc.getElementById('input')
    listElement  = doc.getElementById('list')

    keyHandler = new KeyHandler(inputElement)
    list       = new List(doc, listElement)

    chrome.tabs.getAllInWindow (tabs) ->
        for tab in tabs
            item = new Item(doc, tab)
            list.addItem(item)

        keyHandler.onEnter      (event) -> list.activate()
        keyHandler.onOthers     (event) -> list.filter(event.target.value)
        keyHandler.onSelectPrev (event) -> list.selectNext(DIRECTION.PREV)
        keyHandler.onSelectNext (event) -> list.selectNext(DIRECTION.NEXT)
        keyHandler.onEsc        (event) -> window.close()

        list.refresh()

    inputElement.focus()
