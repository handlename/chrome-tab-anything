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

class Item
    doc:     null
    tab:     null
    element: null
    state:   null

    constructor: (@doc, @tab) ->
        @state = STATE.NORMAL

        @element           = @doc.createElement('li')
        @element.innerHTML = @tab.title

        this.select(no)
        this.show(yes)

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

class List
    doc:     null
    element: null
    items:   []

    constructor: (@doc, @element) ->

    addItem: (item) ->
        @items.push(item)

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
                flag = no unless item.tab.title.match pattern

            if flag is yes
                item.show(yes)
            else
                item.show(no)

        @refresh()

    activate: () ->
        selected = @selectedItem()
        chrome.tabs.update(selected.tab.id, { selected: true })

    selectPrev: () ->
        selected = @selectedItem()
        items    = @itemsByState(STATE.NORMAL|STATE.SELECTED)
        index    = items.indexOf(selected)
        index    = 0 if index == -1

        --index if 0 < index

        @selectOne(@items[@items.indexOf(items[index])])

    selectNext: () ->
        selected = @selectedItem()
        items    = @itemsByState(STATE.NORMAL|STATE.SELECTED)
        index    = items.indexOf(selected)
        index    = 0 if index == -1

        ++index if index < items.length - 1

        @selectOne(@items[@items.indexOf(items[index])])

    selectOne: (selected) ->
        @items.forEach (item) ->
            item.select(item is selected)

class KeyHandler
    element: null

    callbacks:
        enter:      () ->
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
        else if @_isSelectPrev(event.which)
            @callbacks.selectPrev(event)
        else if @_isSelectNext(event.which)
            @callbacks.selectNext(event)
        else
            @callbacks.others(event)

        @modifiers.ctrl  = off
        @modifiers.shift = off
        @modifiers.alt   = off
        @modifiers.meta  = off

    # 修飾キーの監視のみ
    _onKeyDown: (event) ->
        @modifiers.ctrl  = event.ctrlKey
        @modifiers.shift = event.shiftKey
        @modifiers.alt   = event.altKey
        @modifiers.meta  = event.metaKey

    _isEnter: (keycode) ->
        return (@modifiers.ctrl and keycode == 74) or # Ctrl+j
               (@modifiers.ctrl and keycode == 77) or # Ctrl+m
                                   (keycode == 13);   # Enter

    _isSelectPrev: (keycode) ->
        # Ctrl + p
        return @modifiers.ctrl and keycode is 80

    _isSelectNext: (keycode) ->
        # Ctrl + n
        return @modifiers.ctrl and keycode is 78

    check: (event) ->

    onEnter: (callback) ->
        @callbacks.enter = callback

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

        keyHandler.onEnter (event) ->
            list.activate()

        keyHandler.onOthers (event) ->
            list.filter(event.target.value)

        keyHandler.onSelectPrev (event) ->
            list.selectPrev()

        keyHandler.onSelectNext (event) ->
            list.selectNext()

        list.refresh()

    inputElement.focus()
