// URLSearchParams polyfill adapted from url-search-params-polyfill
// Source: https://github.com/jerrybendy/url-search-params-polyfill
// Adapted for QuickJS Ruby gem with modern class syntax

(function() {
  if (typeof URLSearchParams !== 'undefined') return;

  const iterable = typeof Symbol !== 'undefined' && Symbol.iterator;

  function encode(str) {
    const replace = {
      '!': '%21',
      "'": '%27',
      '(': '%28',
      ')': '%29',
      '~': '%7E',
      '%20': '+',
      '%00': '\x00'
    };
    return encodeURIComponent(str).replace(/[!'\(\)~]|%20|%00/g, (match) => replace[match]);
  }

  function decode(str) {
    return str
      .replace(/[ +]/g, '%20')
      .replace(/(%[a-f0-9]{2})+/gi, (match) => decodeURIComponent(match));
  }

  function makeIterator(arr) {
    const iterator = {
      next: function() {
        const value = arr.shift();
        return {done: value === undefined, value: value};
      }
    };

    if (iterable) {
      iterator[Symbol.iterator] = function() {
        return iterator;
      };
    }

    return iterator;
  }

  function parseToDict(search) {
    const dict = {};

    if (Array.isArray(search)) {
      // Sequence: [['key', 'value'], ['key2', 'value2']]
      for (let i = 0; i < search.length; i++) {
        const item = search[i];
        if (Array.isArray(item) && item.length === 2) {
          appendTo(dict, item[0], item[1]);
        } else {
          throw new TypeError("Failed to construct 'URLSearchParams': Sequence initializer must only contain pair elements");
        }
      }
    } else if (typeof search === 'object' && search !== null) {
      // Plain object: {key: 'value', key2: 'value2'}
      for (const key in search) {
        if (Object.prototype.hasOwnProperty.call(search, key)) {
          appendTo(dict, key, search[key]);
        }
      }
    } else {
      // String: "key=value&key2=value2"
      let searchString = String(search || '');

      // Remove leading '?'
      if (searchString.indexOf('?') === 0) {
        searchString = searchString.slice(1);
      }

      const pairs = searchString.split('&');
      for (let j = 0; j < pairs.length; j++) {
        const value = pairs[j];
        const index = value.indexOf('=');

        if (index > -1) {
          appendTo(dict, decode(value.slice(0, index)), decode(value.slice(index + 1)));
        } else if (value) {
          appendTo(dict, decode(value), '');
        }
      }
    }

    return dict;
  }

  function appendTo(dict, name, value) {
    const val = typeof value === 'string' ? value : (
      value !== null && value !== undefined && typeof value.toString === 'function'
        ? value.toString()
        : JSON.stringify(value)
    );

    if (Object.prototype.hasOwnProperty.call(dict, name)) {
      dict[name].push(val);
    } else {
      dict[name] = [val];
    }
  }

  globalThis.URLSearchParams = class URLSearchParams {
    constructor(search = '') {
      // Support constructing from another URLSearchParams instance
      if (search instanceof URLSearchParams) {
        search = search.toString();
      }

      this._dict = parseToDict(search);
    }

    append(name, value) {
      appendTo(this._dict, name, value);
    }

    delete(name) {
      delete this._dict[name];
    }

    get(name) {
      return this.has(name) ? this._dict[name][0] : null;
    }

    getAll(name) {
      return this.has(name) ? this._dict[name].slice(0) : [];
    }

    has(name) {
      return Object.prototype.hasOwnProperty.call(this._dict, name);
    }

    set(name, value) {
      this._dict[name] = [String(value)];
    }

    forEach(callback, thisArg) {
      for (const name in this._dict) {
        if (Object.prototype.hasOwnProperty.call(this._dict, name)) {
          const values = this._dict[name];
          for (let i = 0; i < values.length; i++) {
            callback.call(thisArg, values[i], name, this);
          }
        }
      }
    }

    sort() {
      const keys = [];
      for (const key in this._dict) {
        if (Object.prototype.hasOwnProperty.call(this._dict, key)) {
          keys.push(key);
        }
      }
      keys.sort();

      const sortedDict = {};
      for (let i = 0; i < keys.length; i++) {
        sortedDict[keys[i]] = this._dict[keys[i]];
      }
      this._dict = sortedDict;
    }

    toString() {
      const query = [];
      for (const key in this._dict) {
        if (Object.prototype.hasOwnProperty.call(this._dict, key)) {
          const name = encode(key);
          const values = this._dict[key];
          for (let i = 0; i < values.length; i++) {
            query.push(name + '=' + encode(values[i]));
          }
        }
      }
      return query.join('&');
    }

    keys() {
      const items = [];
      this.forEach((value, name) => {
        items.push(name);
      });
      return makeIterator(items);
    }

    values() {
      const items = [];
      this.forEach((value) => {
        items.push(value);
      });
      return makeIterator(items);
    }

    entries() {
      const items = [];
      this.forEach((value, name) => {
        items.push([name, value]);
      });
      return makeIterator(items);
    }

    *[Symbol.iterator]() {
      for (const key in this._dict) {
        if (Object.prototype.hasOwnProperty.call(this._dict, key)) {
          const values = this._dict[key];
          for (let i = 0; i < values.length; i++) {
            yield [key, values[i]];
          }
        }
      }
    }
  };

  // Define size as a property descriptor
  Object.defineProperty(globalThis.URLSearchParams.prototype, 'size', {
    get: function() {
      let count = 0;
      for (const key in this._dict) {
        if (Object.prototype.hasOwnProperty.call(this._dict, key)) {
          count += this._dict[key].length;
        }
      }
      return count;
    },
    enumerable: true,
    configurable: true
  });

  if (iterable) {
    Object.defineProperty(globalThis.URLSearchParams.prototype, Symbol.toStringTag, {
      value: 'URLSearchParams',
      configurable: true
    });
  }
})();
