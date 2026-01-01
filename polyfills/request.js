// Request class based on JakeChampion/fetch polyfill
// Adapted for QuickJS Ruby gem
// Source: https://github.com/JakeChampion/fetch

(function() {
  if (typeof Request !== 'undefined') return;

  const methods = ['CONNECT', 'DELETE', 'GET', 'HEAD', 'OPTIONS', 'PATCH', 'POST', 'PUT', 'TRACE'];

  function normalizeMethod(method) {
    const upcased = method.toUpperCase();
    return methods.indexOf(upcased) > -1 ? upcased : method;
  }

  function consumed(body) {
    if (body._noBody) return;
    if (body.bodyUsed) {
      return Promise.reject(new TypeError('Body has already been consumed'));
    }
    body.bodyUsed = true;
  }

  // Body mixin - shared between Request and Response
  class BodyMixin {
    constructor() {
      this.bodyUsed = false;
    }

    _initBody(body) {
      this.bodyUsed = this.bodyUsed;
      this._bodyInit = body;

      if (!body) {
        this._noBody = true;
        this._bodyText = '';
      } else if (typeof body === 'string') {
        this._bodyText = body;
      } else if (body !== undefined && body !== null) {
        this._bodyText = String(body);
      } else {
        this._bodyText = '';
      }

      if (!this.headers.get('content-type')) {
        if (typeof body === 'string') {
          this.headers.set('content-type', 'text/plain;charset=UTF-8');
        }
      }
    }

    text() {
      const rejected = consumed(this);
      if (rejected) {
        return rejected;
      }
      return Promise.resolve(this._bodyText);
    }

    json() {
      return this.text().then(JSON.parse);
    }
  }

  globalThis.Request = class Request extends BodyMixin {
    constructor(input, options = {}) {
      super();

      if (!(this instanceof Request)) {
        throw new TypeError('Please use the "new" operator, this DOM object constructor cannot be called as a function.');
      }

      let body = options.body;

      if (input instanceof Request) {
        if (input.bodyUsed) {
          throw new TypeError('Already read');
        }
        this.url = input.url;
        this.credentials = input.credentials;
        if (!options.headers) {
          this.headers = new Headers(input.headers);
        }
        this.method = input.method;
        if (!body && input._bodyInit != null) {
          body = input._bodyInit;
          input.bodyUsed = true;
        }
      } else {
        this.url = String(input);
      }

      this.credentials = options.credentials || this.credentials || 'same-origin';
      if (options.headers || !this.headers) {
        this.headers = new Headers(options.headers);
      }
      this.method = normalizeMethod(options.method || this.method || 'GET');

      if ((this.method === 'GET' || this.method === 'HEAD') && body) {
        throw new TypeError('Request with GET or HEAD method cannot have body');
      }

      this._initBody(body);
    }

    get body() {
      return this._bodyText;
    }

    clone() {
      return new Request(this, {body: this._bodyInit});
    }
  };
})();
