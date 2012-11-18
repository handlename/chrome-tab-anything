puts = (message) -> console.log(message)

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
        if yesNo == yes
            @state = STATE.SELECTED
            @element.setAttribute('class', 'selected')
        else
            @state = STATE.NORMAL
            @element.setAttribute('class', '')

    show: (yesNo) ->
        @state = if yesNo == yes then STATE.NORMAL else STATE.HIDDEN

class List
    element: null

    items: []

    constructor: (@doc, @element) ->

    addItem: (item) ->
        @items.push(item)

    clear: () ->
        @element.innerHTML = ''

    refresh: () ->
        this.clear()

        for item in @items
            @element.appendChild(item.element)

class KeyHandler
    element: null

    constructor: (targetElement) ->

    check: (event) ->

    onEnter: (callback) ->

    onSelectPrev: (callback) ->

    onSelectNext: (callback) ->

    onOthers: (callback) ->

window.addEventListener 'load', () ->
    doc  = window.document;
    list = new List(doc, doc.getElementById('list'))

    chrome.tabs.getAllInWindow (tabs) ->
        for tab in tabs
            item = new Item(doc, tab)
            list.addItem(item)

        list.refresh()
