p = (message) -> console.log(message)

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
            @element.setAttribute('class', 'selected')
        else
            @state = STATE.NORMAL
            @element.setAttribute('class', '')

    show: (yesNo) ->
        @state = if yesNo == yes then STATE.NORMAL else STATE.HIDDEN

class List
    doc:     null
    element: null
    items:   []

    constructor: (@doc, @element) ->

    addItem: (item) ->
        @items.push(item)

    clear: () ->
        @element.innerHTML = ''

    refresh: () ->
        @clear()

        for item in @items
            continue if item.state is STATE.HIDDEN
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

class KeyHandler
    element: null

    callbacks:
        enter:      () ->
        selectPrev: () ->
        selectNext: () ->
        others:     () ->

    constructor: (@element) ->
        self = this
        @element.addEventListener 'keyup', (event) =>
            this._onKeyUp(event)

    _onKeyUp: (event) ->
        @callbacks.others(event)

    check: (event) ->

    onEnter: (callback) ->

    onSelectPrev: (callback) ->

    onSelectNext: (callback) ->

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

        keyHandler.onOthers (event) ->
            list.filter(event.target.value)

        list.refresh()

    inputElement.focus()
