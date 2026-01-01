// Response class based on JakeChampion/fetch polyfill
// Adapted for QuickJS Ruby gem
// Source: https://github.com/JakeChampion/fetch

(function() {
  if (typeof Response !== 'undefined') return;

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

    arrayBuffer() {
      if (this._bodyText) {
        const body = this._bodyText;
        const buf = new ArrayBuffer(body.length);
        const view = new Uint8Array(buf);
        for (let i = 0; i < body.length; i++) {
          view[i] = body.charCodeAt(i) & 0xff;
        }
        const isConsumed = consumed(this);
        if (isConsumed) {
          return isConsumed;
        }
        return Promise.resolve(buf);
      }
      return Promise.reject(new Error('could not read as ArrayBuffer'));
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

  globalThis.Response = class Response extends BodyMixin {
    constructor(bodyInit, options = {}) {
      super();

      if (!(this instanceof Response)) {
        throw new TypeError('Please use the "new" operator, this DOM object constructor cannot be called as a function.');
      }

      this.type = 'default';
      this.status = options.status === undefined ? 200 : options.status;
      if (this.status < 100 || this.status > 599) {
        throw new RangeError("Failed to construct 'Response': The status provided (" + this.status + ") is outside the range [100, 599].");
      }

      this.ok = this.status >= 200 && this.status < 300;
      this.statusText = options.statusText === undefined ? '' : '' + options.statusText;
      this.headers = options.headers instanceof Headers
        ? options.headers
        : new Headers(options.headers);
      this.url = options.url || '';

      this._initBody(bodyInit);
    }

    get body() {
      return this._bodyText;
    }

    clone() {
      if (this.bodyUsed) {
        throw new TypeError('Cannot clone a Response whose body has been used');
      }
      return new Response(this._bodyInit, {
        status: this.status,
        statusText: this.statusText,
        headers: new Headers(this.headers),
        url: this.url
      });
    }

    static error() {
      const response = Object.create(Response.prototype);
      response.type = 'error';
      response.status = 0;
      response.ok = false;
      response.statusText = '';
      response.headers = new Headers();
      response.url = '';
      Object.setPrototypeOf(response, Response.prototype);
      // Initialize bodyUsed and call _initBody
      response.bodyUsed = false;
      response._noBody = true;
      response._bodyInit = null;
      response._bodyText = '';
      return response;
    }

    static redirect(url, status) {
      const redirectStatuses = [301, 302, 303, 307, 308];
      if (redirectStatuses.indexOf(status) === -1) {
        throw new RangeError('Invalid redirect status code');
      }
      return new Response(null, {status: status, headers: {location: url}});
    }
  };
})();
