// Headers class based on JakeChampion/fetch polyfill
// Adapted for QuickJS Ruby gem
// Source: https://github.com/JakeChampion/fetch

(function() {
  if (typeof Headers !== 'undefined') return;

  function normalizeName(name) {
    if (typeof name !== 'string') {
      name = String(name);
    }
    if (/[^a-z0-9\-#$%&'*+.^_`|~!]/i.test(name) || name === '') {
      throw new TypeError('Invalid character in header field name: "' + name + '"');
    }
    return name.toLowerCase();
  }

  function normalizeValue(value) {
    if (typeof value !== 'string') {
      value = String(value);
    }
    return value;
  }

  function iteratorFor(items) {
    const iterator = {
      next: function() {
        const value = items.shift();
        return {done: value === undefined, value: value};
      }
    };
    if (typeof Symbol !== 'undefined' && Symbol.iterator) {
      iterator[Symbol.iterator] = function() {
        return iterator;
      };
    }
    return iterator;
  }

  globalThis.Headers = class Headers {
    constructor(headers) {
      this.map = {};

      if (headers instanceof Headers) {
        headers.forEach((value, name) => this.append(name, value));
      } else if (Array.isArray(headers)) {
        headers.forEach((header) => {
          if (header.length != 2) {
            throw new TypeError('Headers constructor: expected name/value pair to be length 2, found' + header.length);
          }
          this.append(header[0], header[1]);
        });
      } else if (headers) {
        Object.getOwnPropertyNames(headers).forEach((name) => {
          this.append(name, headers[name]);
        });
      }
    }

    append(name, value) {
      name = normalizeName(name);
      value = normalizeValue(value);
      const oldValue = this.map[name];
      this.map[name] = oldValue ? oldValue + ', ' + value : value;
    }

    delete(name) {
      delete this.map[normalizeName(name)];
    }

    get(name) {
      name = normalizeName(name);
      return this.has(name) ? this.map[name] : null;
    }

    has(name) {
      return this.map.hasOwnProperty(normalizeName(name));
    }

    set(name, value) {
      this.map[normalizeName(name)] = normalizeValue(value);
    }

    forEach(callback, thisArg) {
      for (const name in this.map) {
        if (this.map.hasOwnProperty(name)) {
          callback.call(thisArg, this.map[name], name, this);
        }
      }
    }

    keys() {
      const items = [];
      this.forEach((value, name) => {
        items.push(name);
      });
      return iteratorFor(items);
    }

    values() {
      const items = [];
      this.forEach((value) => {
        items.push(value);
      });
      return iteratorFor(items);
    }

    entries() {
      const items = [];
      this.forEach((value, name) => {
        items.push([name, value]);
      });
      return iteratorFor(items);
    }

    *[Symbol.iterator]() {
      for (const name in this.map) {
        if (this.map.hasOwnProperty(name)) {
          yield [name, this.map[name]];
        }
      }
    }
  };
})();
