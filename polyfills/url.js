// URL polyfill for QuickJS Ruby gem
// Pure JavaScript implementation (no DOM required)

(function() {
  if (typeof URL !== 'undefined') return;

  // URL parsing regex based on RFC 3986
  // Updated to handle username:password@host
  const URL_PARSER = /^([^:/?#]+:)(?:\/\/(?:([^:]*)(?::([^@]*))?@)?([^:/?#]*)(?::(\d+))?)?([^?#]*)(\?[^#]*)?(#.*)?$/;

  function parseURL(url, base = undefined) {
    if (typeof url !== 'string') {
      url = String(url);
    }

    let fullURL = url;
    let baseURL = null;

    // Resolve against base if provided
    if (base !== undefined) {
      baseURL = parseURL(base);
      if (!baseURL) {
        throw new TypeError('Invalid base URL');
      }

      // If url is relative, resolve against base
      if (!url.match(/^[a-zA-Z][a-zA-Z0-9+.-]*:/)) {
        // Relative URL
        if (url.startsWith('//')) {
          // Protocol-relative: //host/path
          fullURL = baseURL.protocol + url;
        } else if (url.startsWith('/')) {
          // Absolute path: /path
          fullURL = baseURL.protocol + '//' + baseURL.host + url;
        } else {
          // Relative path: path or ../path or ./path
          const basePath = baseURL.pathname || '/';
          const basePathDir = basePath.substring(0, basePath.lastIndexOf('/') + 1);
          fullURL = baseURL.protocol + '//' + baseURL.host + basePathDir + url;
        }
      }
    }

    // Check if URL has a valid protocol (scheme) - required for absolute URLs
    if (!fullURL.match(/^[a-zA-Z][a-zA-Z0-9+.-]*:/)) {
      throw new TypeError('Invalid URL');
    }

    const match = fullURL.match(URL_PARSER);
    if (!match) {
      throw new TypeError('Invalid URL');
    }

    const protocol = match[1] || '';
    const username = match[2] || '';
    const password = match[3] || '';
    const hostname = match[4] || '';
    const port = match[5] || '';
    let pathname = match[6] || '';
    const search = match[7] || '';
    const hash = match[8] || '';

    // Only set default pathname if we have a hostname but no path at all
    // But track whether pathname was originally present
    const hadPathname = match[6] !== undefined;
    if (!hadPathname && hostname && !pathname) {
      pathname = '';
    }

    return {
      protocol,
      username,
      password,
      hostname,
      port,
      pathname,
      search,
      hash,
      host: hostname + (port ? ':' + port : ''),
      href: fullURL,
      hadPathname
    };
  }

  function getDefaultPort(protocol) {
    if (!protocol) return '';
    const port = protocol.toLowerCase();
    if (port === 'http:') return '80';
    if (port === 'https:') return '443';
    if (port === 'ftp:') return '21';
    if (port === 'ws:') return '80';
    if (port === 'wss:') return '443';
    return '';
  }

  globalThis.URL = class URL {
    constructor(url, base = undefined) {
      const parsed = parseURL(url, base);

      Object.defineProperty(this, '_protocol', { value: parsed.protocol, writable: true });
      Object.defineProperty(this, '_username', { value: parsed.username, writable: true });
      Object.defineProperty(this, '_password', { value: parsed.password, writable: true });
      Object.defineProperty(this, '_hostname', { value: parsed.hostname, writable: true });
      Object.defineProperty(this, '_port', { value: parsed.port, writable: true });
      Object.defineProperty(this, '_pathname', { value: parsed.pathname, writable: true });
      Object.defineProperty(this, '_search', { value: parsed.search, writable: true });
      Object.defineProperty(this, '_hash', { value: parsed.hash, writable: true });
      Object.defineProperty(this, '_host', { value: parsed.host, writable: true });
      Object.defineProperty(this, '_hadPathname', { value: parsed.hadPathname || false, writable: true });

      // Store URL instance reference for searchParams callback
      const urlInstance = this;

      // Create URLSearchParams from search string
      const searchParams = new URLSearchParams(this._search.substring(1) || '');

      // Override URLSearchParams methods to update URL's search
      const originalAppend = searchParams.append.bind(searchParams);
      const originalDelete = searchParams.delete.bind(searchParams);
      const originalSet = searchParams.set.bind(searchParams);
      const originalSort = searchParams.sort.bind(searchParams);

      searchParams.append = function(name, value) {
        originalAppend(name, value);
        urlInstance._updateSearchFromParams();
      };

      searchParams.delete = function(name) {
        originalDelete(name);
        urlInstance._updateSearchFromParams();
      };

      searchParams.set = function(name, value) {
        originalSet(name, value);
        urlInstance._updateSearchFromParams();
      };

      searchParams.sort = function() {
        originalSort();
        urlInstance._updateSearchFromParams();
      };

      Object.defineProperty(this, 'searchParams', {
        value: searchParams,
        writable: false,
        enumerable: true,
        configurable: false
      });
    }

    _updateSearchFromParams() {
      const queryString = this.searchParams.toString();
      this._search = queryString ? '?' + queryString : '';
    }

    get protocol() {
      return this._protocol;
    }

    set protocol(value) {
      this._protocol = value;
    }

    get hostname() {
      return this._hostname;
    }

    set hostname(value) {
      this._hostname = value;
      this._host = value + (this._port ? ':' + this._port : '');
    }

    get port() {
      return this._port;
    }

    set port(value) {
      this._port = value;
      this._host = this._hostname + (value ? ':' + value : '');
    }

    get host() {
      return this._host;
    }

    set host(value) {
      this._host = value;
      // Parse out hostname and port from host
      const colonIndex = value.indexOf(':');
      if (colonIndex > -1) {
        this._hostname = value.substring(0, colonIndex);
        this._port = value.substring(colonIndex + 1);
      } else {
        this._hostname = value;
        this._port = '';
      }
    }

    get pathname() {
      return this._pathname || '/';
    }

    set pathname(value) {
      this._pathname = value;
      this._hadPathname = true;
    }

    get search() {
      return this._search;
    }

    set search(value) {
      this._search = value;
      // Rebuild searchParams from new search string
      // Clear existing params by directly modifying _dict
      this.searchParams._dict = {};
      // Parse new search string and populate
      const queryString = value ? value.substring(1) || '' : '';
      if (queryString) {
        const pairs = queryString.split('&');
        for (let i = 0; i < pairs.length; i++) {
          const pair = pairs[i];
          const index = pair.indexOf('=');
          if (index > -1) {
            this.searchParams.append(decodeURIComponent(pair.slice(0, index).replace(/[+]/g, ' ')),
                                     decodeURIComponent(pair.slice(index + 1).replace(/[+]/g, ' ')));
          } else if (pair) {
            this.searchParams.append(decodeURIComponent(pair.replace(/[+]/g, ' ')), '');
          }
        }
      }
    }

    get hash() {
      return this._hash;
    }

    set hash(value) {
      this._hash = value;
    }

    get href() {
      const protocol = this.protocol;
      const host = this.host;
      const pathname = this._pathname || '/';
      const search = this._search;
      const hash = this._hash;
      const username = this._username;
      const password = this._password;

      let auth = '';
      if (username || password) {
        auth = username + (password ? ':' + password : '') + '@';
      }

      return protocol + '//' + auth + host + pathname + search + hash;
    }

    set href(value) {
      const parsed = parseURL(value);
      this._protocol = parsed.protocol;
      this._username = parsed.username;
      this._password = parsed.password;
      this._hostname = parsed.hostname;
      this._port = parsed.port;
      this._pathname = parsed.pathname;
      this._search = parsed.search;
      this._hash = parsed.hash;
      this._host = parsed.host;
      this._hadPathname = parsed.hadPathname || false;
      // Update searchParams from new search string
      const queryString = this._search ? this._search.substring(1) || '' : '';
      this.searchParams._dict = {};
      if (queryString) {
        const pairs = queryString.split('&');
        for (let i = 0; i < pairs.length; i++) {
          const pair = pairs[i];
          const index = pair.indexOf('=');
          if (index > -1) {
            this.searchParams.append(decodeURIComponent(pair.slice(0, index).replace(/[+]/g, ' ')),
                                     decodeURIComponent(pair.slice(index + 1).replace(/[+]/g, ' ')));
          } else if (pair) {
            this.searchParams.append(decodeURIComponent(pair.replace(/[+]/g, ' ')), '');
          }
        }
      }
    }

    get origin() {
      if (!this.protocol) return '';
      const defaultPort = getDefaultPort(this.protocol);
      const port = this._port || defaultPort;
      return this.protocol + '//' + this._hostname + (port !== defaultPort ? ':' + port : '');
    }

    get username() {
      return this._username || '';
    }

    set username(value) {
      this._username = value || '';
    }

    get password() {
      return this._password || '';
    }

    set password(value) {
      this._password = value || '';
    }

    toString() {
      return this.href;
    }

    toJSON() {
      return this.href;
    }

    // Static methods
    static createObjectURL(_blob) {
      throw new TypeError('URL.createObjectURL is not supported in this environment');
    }

    static revokeObjectURL(_url) {
      // No-op for compatibility
    }
  };

  // Add toStringTag
  if (typeof Symbol !== 'undefined' && Symbol.toStringTag) {
    Object.defineProperty(globalThis.URL.prototype, Symbol.toStringTag, {
      value: 'URL',
      configurable: true
    });
  }
})();
