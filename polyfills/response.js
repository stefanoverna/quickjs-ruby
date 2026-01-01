(function() {
  if (typeof Response !== 'undefined') return;

  globalThis.Response = class Response {
    constructor(body, init = {}) {
      this._body = body !== undefined && body !== null ? String(body) : '';
      this._bodyUsed = false;

      this.status = init.status !== undefined ? init.status : 200;
      this.statusText = init.statusText !== undefined ? init.statusText : '';
      this.ok = this.status >= 200 && this.status < 300;
      this.headers = init.headers instanceof Headers
        ? init.headers
        : new Headers(init.headers);
      this.type = init.type || 'default';
      this.url = init.url || '';
      this.redirected = init.redirected || false;
    }

    get bodyUsed() {
      return this._bodyUsed;
    }

    // For backwards compatibility with existing code that accesses .body directly
    get body() {
      return this._body;
    }

    clone() {
      if (this._bodyUsed) {
        throw new TypeError('Cannot clone a Response whose body has been used');
      }
      return new Response(this._body, {
        status: this.status,
        statusText: this.statusText,
        headers: new Headers(this.headers),
        type: this.type,
        url: this.url,
        redirected: this.redirected
      });
    }

    text() {
      if (this._bodyUsed) {
        return Promise.reject(new TypeError('Body has already been consumed'));
      }
      this._bodyUsed = true;
      return Promise.resolve(this._body);
    }

    json() {
      if (this._bodyUsed) {
        return Promise.reject(new TypeError('Body has already been consumed'));
      }
      this._bodyUsed = true;
      try {
        return Promise.resolve(JSON.parse(this._body));
      } catch (e) {
        return Promise.reject(e);
      }
    }

    arrayBuffer() {
      if (this._bodyUsed) {
        return Promise.reject(new TypeError('Body has already been consumed'));
      }
      this._bodyUsed = true;
      // Simple implementation - convert string to array of char codes
      var body = this._body;
      var buf = new ArrayBuffer(body.length);
      var view = new Uint8Array(buf);
      for (var i = 0; i < body.length; i++) {
        view[i] = body.charCodeAt(i) & 0xff;
      }
      return Promise.resolve(buf);
    }

    blob() {
      return Promise.reject(new TypeError('Blob is not supported in this environment'));
    }

    formData() {
      return Promise.reject(new TypeError('FormData is not supported in this environment'));
    }

    static error() {
      var response = new Response(null, { status: 0, statusText: '' });
      response.type = 'error';
      return response;
    }

    static redirect(url, status) {
      if (status === undefined) status = 302;
      if ([301, 302, 303, 307, 308].indexOf(status) === -1) {
        throw new RangeError('Invalid redirect status code');
      }
      return new Response(null, {
        status: status,
        headers: { 'Location': url }
      });
    }
  };
})();
