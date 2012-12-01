// Generated by CoffeeScript 1.3.3
var Item, KeyHandler, List, STATE, p;

p = function(message) {
  return console.log(message);
};

HTMLElement.prototype.addClass = function(className) {
  var classes, index, _ref;
  classes = (_ref = this.className) != null ? _ref.split(' ') : void 0;
  if (!classes) {
    return;
  }
  index = classes.indexOf(className);
  if (index === -1) {
    classes.push(className);
    this.className = classes.join(' ');
  }
  return this;
};

HTMLElement.prototype.removeClass = function(className) {
  var classes, index, _ref;
  classes = (_ref = this.className) != null ? _ref.split(' ') : void 0;
  if (!classes) {
    return;
  }
  index = classes.indexOf(className);
  if (index !== -1) {
    classes.splice(index, 1);
    this.className = classes.join(' ');
  }
  return this;
};

STATE = {
  NORMAL: 1,
  HIDDEN: 2,
  SELECTED: 4
};

Item = (function() {

  Item.prototype.doc = null;

  Item.prototype.tab = null;

  Item.prototype.element = null;

  Item.prototype.state = null;

  function Item(doc, tab) {
    this.doc = doc;
    this.tab = tab;
    this.state = STATE.NORMAL;
    this._createElement();
    this.select(false);
    this.show(true);
  }

  Item.prototype._createElement = function() {
    var dummy, template;
    template = this.doc.getElementById('item-template').innerHTML;
    template = template.replace('{title}', this.tab.title);
    template = template.replace('{url}', this.tab.url);
    dummy = this.doc.createElement('dummy');
    dummy.innerHTML = template;
    return this.element = dummy.getElementsByTagName('li')[0];
  };

  Item.prototype.source = function() {
    return [this.tab.title, this.tab.url].join(',');
  };

  Item.prototype.select = function(yesNo) {
    if (yesNo === true) {
      this.state = STATE.SELECTED;
      return this.element.addClass('selected');
    } else {
      if (this.state === STATE.SELECTED) {
        this.state = STATE.NORMAL;
      }
      return this.element.removeClass('selected');
    }
  };

  Item.prototype.show = function(yesNo) {
    if (yesNo === true) {
      if (this.state === STATE.HIDDEN) {
        this.state = STATE.NORMAL;
      }
      return this.element.removeClass('hidden');
    } else {
      this.state = STATE.HIDDEN;
      return this.element.addClass('hidden');
    }
  };

  return Item;

})();

List = (function() {

  List.prototype.doc = null;

  List.prototype.element = null;

  List.prototype.items = [];

  function List(doc, element) {
    this.doc = doc;
    this.element = element;
  }

  List.prototype.addItem = function(item) {
    return this.items.push(item);
  };

  List.prototype.itemsByState = function(state) {
    var item;
    return (function() {
      var _i, _len, _ref, _results;
      _ref = this.items;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        if (item.state & state) {
          _results.push(item);
        }
      }
      return _results;
    }).call(this);
  };

  List.prototype.selectedItem = function() {
    var items;
    items = this.itemsByState(STATE.SELECTED);
    if (items != null ? items.length : void 0) {
      return items[0];
    } else {
      return void 0;
    }
  };

  List.prototype.clear = function() {
    return this.element.innerHTML = '';
  };

  List.prototype.refresh = function() {
    var item, _i, _len, _ref, _ref1, _results;
    this.clear();
    if (!this.selectedItem()) {
      if ((_ref = this.itemsByState(STATE.NORMAL | STATE.SELECTED)[0]) != null) {
        _ref.select(true);
      }
    }
    _ref1 = this.items;
    _results = [];
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      item = _ref1[_i];
      _results.push(this.element.appendChild(item.element));
    }
    return _results;
  };

  List.prototype.filter = function(text) {
    var flag, item, pattern, patterns, _i, _j, _len, _len1, _ref;
    patterns = text.split(/\s+/).map(function(word) {
      return new RegExp(word, 'i');
    });
    _ref = this.items;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      flag = true;
      for (_j = 0, _len1 = patterns.length; _j < _len1; _j++) {
        pattern = patterns[_j];
        if (!item.source().match(pattern)) {
          flag = false;
        }
      }
      if (flag === true) {
        item.show(true);
      } else {
        item.show(false);
      }
    }
    return this.refresh();
  };

  List.prototype.activate = function() {
    var selected;
    selected = this.selectedItem();
    return chrome.tabs.update(selected.tab.id, {
      selected: true
    });
  };

  List.prototype.selectPrev = function() {
    var index, items, selected;
    selected = this.selectedItem();
    items = this.itemsByState(STATE.NORMAL | STATE.SELECTED);
    index = items.indexOf(selected);
    if (index === -1) {
      index = 0;
    }
    if (0 < index) {
      --index;
    }
    return this.selectOne(this.items[this.items.indexOf(items[index])]);
  };

  List.prototype.selectNext = function() {
    var index, items, selected;
    selected = this.selectedItem();
    items = this.itemsByState(STATE.NORMAL | STATE.SELECTED);
    index = items.indexOf(selected);
    if (index === -1) {
      index = 0;
    }
    if (index < items.length - 1) {
      ++index;
    }
    return this.selectOne(this.items[this.items.indexOf(items[index])]);
  };

  List.prototype.selectOne = function(selected) {
    return this.items.forEach(function(item) {
      return item.select(item === selected);
    });
  };

  return List;

})();

KeyHandler = (function() {

  KeyHandler.prototype.element = null;

  KeyHandler.prototype.callbacks = {
    enter: function() {},
    selectPrev: function() {},
    selectNext: function() {},
    others: function() {}
  };

  KeyHandler.prototype.modifiers = {
    ctrl: false,
    shift: false,
    alt: false,
    meta: false
  };

  function KeyHandler(element) {
    var _this = this;
    this.element = element;
    this.element.addEventListener('keydown', function(event) {
      return _this._onKeyDown(event);
    });
    this.element.addEventListener('keyup', function(event) {
      return _this._onKeyUp(event);
    });
  }

  KeyHandler.prototype._onKeyUp = function(event) {
    if (this._isEnter(event.which)) {
      this.callbacks.enter(event);
    } else if (this._isSelectPrev(event.which)) {
      this.callbacks.selectPrev(event);
    } else if (this._isSelectNext(event.which)) {
      this.callbacks.selectNext(event);
    } else {
      this.callbacks.others(event);
    }
    return this._updateModifier(event);
  };

  KeyHandler.prototype._onKeyDown = function(event) {
    return this._updateModifier(event);
  };

  KeyHandler.prototype._updateModifier = function(event) {
    this.modifiers.ctrl = event.ctrlKey;
    this.modifiers.shift = event.shiftKey;
    this.modifiers.alt = event.altKey;
    return this.modifiers.meta = event.metaKey;
  };

  KeyHandler.prototype._isEnter = function(keycode) {
    return (this.modifiers.ctrl && keycode === 74) || (this.modifiers.ctrl && keycode === 77) || (keycode === 13);
  };

  KeyHandler.prototype._isSelectPrev = function(keycode) {
    return this.modifiers.ctrl && keycode === 80;
  };

  KeyHandler.prototype._isSelectNext = function(keycode) {
    return this.modifiers.ctrl && keycode === 78;
  };

  KeyHandler.prototype.check = function(event) {};

  KeyHandler.prototype.onEnter = function(callback) {
    return this.callbacks.enter = callback;
  };

  KeyHandler.prototype.onSelectPrev = function(callback) {
    return this.callbacks.selectPrev = callback;
  };

  KeyHandler.prototype.onSelectNext = function(callback) {
    return this.callbacks.selectNext = callback;
  };

  KeyHandler.prototype.onOthers = function(callback) {
    return this.callbacks.others = callback;
  };

  return KeyHandler;

})();

window.addEventListener('load', function() {
  var doc, inputElement, keyHandler, list, listElement;
  doc = window.document;
  inputElement = doc.getElementById('input');
  listElement = doc.getElementById('list');
  keyHandler = new KeyHandler(inputElement);
  list = new List(doc, listElement);
  chrome.tabs.getAllInWindow(function(tabs) {
    var item, tab, _i, _len;
    for (_i = 0, _len = tabs.length; _i < _len; _i++) {
      tab = tabs[_i];
      item = new Item(doc, tab);
      list.addItem(item);
    }
    keyHandler.onEnter(function(event) {
      return list.activate();
    });
    keyHandler.onOthers(function(event) {
      return list.filter(event.target.value);
    });
    keyHandler.onSelectPrev(function(event) {
      return list.selectPrev();
    });
    keyHandler.onSelectNext(function(event) {
      return list.selectNext();
    });
    return list.refresh();
  });
  return inputElement.focus();
});
