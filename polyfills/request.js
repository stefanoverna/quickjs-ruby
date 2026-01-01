(function() {
  if (typeof Request !== 'undefined') return;

  var validMethods = ['DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT'];

  function normalizeMethod(method) {
    var upper = method.toUpperCase();
    if (validMethods.indexOf(upper) !== -1) {
      return upper;
    }
    return method;
  }

  globalThis.Request = class Request {
    constructor(input, init = {}) {
      if (input instanceof Request) {
        this.url = input.url;
        this.method = input.method;
        this.headers = new Headers(input.headers);
        this._body = input._body;
        this.credentials = input.credentials;
        this.mode = input.mode;
        this.cache = input.cache;
        this.redirect = input.redirect;
        this.referrer = input.referrer;
        this.integrity = input.integrity;
      } else {
        this.url = String(input);
        this.method = 'GET';
        this.headers = new Headers();
        this._body = null;
        this.credentials = 'same-origin';
        this.mode = 'cors';
        this.cache = 'default';
        this.redirect = 'follow';
        this.referrer = 'about:client';
        this.integrity = '';
      }

      // Apply init options
      if (init.method !== undefined) {
        this.method = normalizeMethod(init.method);
      }
      if (init.headers !== undefined) {
        this.headers = init.headers instanceof Headers
          ? init.headers
          : new Headers(init.headers);
      }
      if (init.body !== undefined && init.body !== null) {
        if (this.method === 'GET' || this.method === 'HEAD') {
          throw new TypeError('Request with GET/HEAD method cannot have body');
        }
        this._body = String(init.body);
      }
      if (init.credentials !== undefined) {
        this.credentials = init.credentials;
      }
      if (init.mode !== undefined) {
        this.mode = init.mode;
      }
      if (init.cache !== undefined) {
        this.cache = init.cache;
      }
      if (init.redirect !== undefined) {
        this.redirect = init.redirect;
      }
      if (init.referrer !== undefined) {
        this.referrer = init.referrer;
      }
      if (init.integrity !== undefined) {
        this.integrity = init.integrity;
      }
    }

    get body() {
      return this._body;
    }

    clone() {
      return new Request(this);
    }

    text() {
      return Promise.resolve(this._body || '');
    }

    json() {
      try {
        return Promise.resolve(JSON.parse(this._body || 'null'));
      } catch (e) {
        return Promise.reject(e);
      }
    }
  };
})();
